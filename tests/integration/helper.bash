# -*- mode: Shell-script;bash -*- 

if [ -z "$AVAKAS_TEST_DIR" ] ; then
    export AVAKAS_TEST_DIR="${BATS_TMPDIR}avakas-${RANDOM}"
    mkdir -p "$AVAKAS_TEST_DIR"
fi

if [ -z "$AVAKAS" ] ; then
    AVAKAS="${BATS_TEST_DIRNAME}/../../avakas"
fi

teardown() {
    rm -rf "$AVAKAS_TEST_DIR"
}

fake_file() {
    local DIR="$1"
    local FILE="${DIR}/mystery-${BATS_TEST_NAME}-${RANDOM}"
    "${BATS_TEST_DIRNAME}/fake-file" "${FILE}"
    echo "$FILE"
}

fake_repo() {
    local REPO="${AVAKAS_TEST_DIR}/briefcase-${BATS_TEST_NAME}-${RANDOM}"
    mkdir "${REPO}"
    cd "$REPO"
    git init -q
    local FILES="$(fake_file "$REPO")"
    FILES="${FILES} $(fake_file "$REPO")"
    git add $FILES
    git commit -qm "some ${RANDOM} message" $FILES
    echo $REPO
}

clone_repo() {
    local ORIGIN="$1"
    local REPO="${AVAKAS_TEST_DIR}/briefcase-${BATS_TEST_NAME}-${RANDOM}"
    git clone -q "$ORIGIN" "$REPO"
    echo $REPO
}

origin_repo() {
    local REPO="$1"
    cd "$REPO"
    git config --bool core.bare true
    rm "${REPO}"/*
}

random_rev() {
    local REPO="$1"
    cd "$REPO"
    local REVS=($(git log | grep commit | cut -f 2 -d ' '))
    local OIFS=$IFS
    IFS=" "
    echo ${REVS[$RANDOM % ${#RANDOM[@]}]}
    IFS=$OIFS
}

tag_repo() {
    local REPO="$1"
    local TAG="$2"
    cd "$REPO"
    local REV=$(random_rev "$REPO")
    git tag "$TAG" "$REV"
}

plain_version() {
    local REPO="$1"
    local VSN="$2"
    local FILE="${REPO}/version"
    echo "$VSN" > "${REPO}/version"
    cd "$REPO"
    git add $FILE
    git commit -qm "Bumping to ${VSN}" $FILE
    tag_repo "$REPO" "$VSN"
}
