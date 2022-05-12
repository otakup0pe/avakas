# -*- mode: Shell-script;bash -*-

function shared_setup() {
    # we do not want this during tests
    if [ -n "$GITHUB_RUN_ID" ] ; then
        unset GITHUB_RUN_ID
    fi
    if [ -n "$GITHUB_RUN_NUMBER" ] ; then
        unset GITHUB_RUN_NUMBER
    fi
    if [ -z "$AVAKAS_TEST_DIR" ] ; then
        AVAKAS_TEST_DIR="${BATS_TMPDIR}"
        if [ "${AVAKAS_TEST_DIR: -1:1}" != "/" ] ; then
            AVAKAS_TEST_DIR="${AVAKAS_TEST_DIR}/"
        fi
        export AVAKAS_TEST_DIR="${AVAKAS_TEST_DIR}avakas-${RANDOM}"
        mkdir -p "$AVAKAS_TEST_DIR"
    fi

    # hey git internal env vars
    unset GIT_AUTHOR_DATE
    unset GIT_AUTHOR_EMAIL
    unset GIT_AUTHOR_NAME
    unset GIT_DIR
    unset GIT_EDITOR
    unset GIT_INDEX_FILE
    unset GIT_PREFIX
}

shared_teardown() {
    rm -rf "$AVAKAS_TEST_DIR"
}

fake_file() {
    local DIR="$1"
    local FILE="${DIR}/mystery-${BATS_TEST_NAME}-${RANDOM}"
    "${BATS_TEST_DIRNAME}/fake-file" "${FILE}"
    echo "$FILE"
}

config_repo() {
    local REPO="$1"
    cd "$REPO"
    git config pull.rebase false
    git config user.email "nobody@example.com"
    git config user.name "some user"
    git.config.
}

fake_repo() {
    local REPO="${AVAKAS_TEST_DIR}/briefcase-${BATS_TEST_NAME}-${RANDOM}"
    mkdir "${REPO}"
    cd "$REPO"
    git init -q --initial-branch=mainline
    config_repo "$REPO"
    local FILES="$(fake_file "$REPO")"
    FILES="${FILES} $(fake_file "$REPO")"
    git add $FILES
    git commit -qm "some ${RANDOM} message" $FILES
    echo "$REPO"
}

clone_repo() {
    local ORIGIN="$1"
    local REPO="${AVAKAS_TEST_DIR}/briefcase-${BATS_TEST_NAME}-${RANDOM}"
    git clone -q "$ORIGIN" "$REPO"
    config_repo "$REPO"
    echo "$REPO"
}

origin_repo() {
    local REPO="$1"
    cd "$REPO"
    git config --bool core.bare true
    rm -rf "${REPO}"/*
}

current_rev() {
    local REPO="$1"
    cd "$REPO"
    local REV=$(git rev-parse --verify HEAD | cut -c 1-8)
    echo "$REV"
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
    local LATEST="$3"
    cd "$REPO"
    if [[ -z "$LATEST" ]]; then 
        local REV=$(random_rev "$REPO")
    else
        local REV=$(current_rev "$REPO")
    fi
    git tag "$TAG" "$REV"
}

update_repo() {
    local REPO="$1"
    cd "$REPO"
    git pull -q origin master
}

plain_version() {
    local REPO="$1"
    local VSN="$2"
    if [ -z "$3" ] ; then
        FILE="${REPO}/version"
    else
        FILE="${REPO}/${3}"
    fi
    echo -n "$VSN" > "$FILE"
    cd "$REPO"
    git add "$FILE"
    git commit -qm "Bumping to ${VSN}" $FILE
    tag_repo "$REPO" "$VSN"
}

ansible_version() {
    local REPO="$1"
    local VSN="$2"
    FILE="${REPO}/meta/main.yml"
    mkdir "${REPO}/meta"
    touch "$FILE"
    cd "$REPO"
    git add "$FILE"
    git commit -qm "This is an important skeleton" "$FILE"
    tag_repo "$REPO" "$VSN"
}

cookbook_version() {
    local REPO="$1"
    local VSN="$2"
    sed -e "s/@@VSN@@/${VSN}/" < "${BATS_TEST_DIRNAME}/fixtures/metadata.rb" > "${REPO}/metadata.rb"
    cd "$REPO"
    git add metadata.rb
    git commit -qm "This is an important skeleton" metadata.rb
    tag_repo "$REPO" "$VSN"
}

avakas_wrapper() {
    avakas_rc 0 $*
}

avakas_rc() {
    RC="$1"
    shift
    OWD="$(pwd)"
    cd "$CIDIR"
    run coverage run -a --source "avakas" -m "avakas" $* 2> /dev/null
    cd "$OWD"
    echo "$output"
    [ "$status" -eq "$RC" ]
}

template_skeleton() {
    local REPO="$1"
    local FLAVOR="$2"
    local VSN="$3"
    if [ "$FLAVOR" == "plain" ] ; then
        plain_version "$REPO" "$VSN"
    elif [ "$FLAVOR" == "ansible" ] ; then
        ansible_version "$REPO" "$VSN"
    elif [ "$FLAVOR" == "cookbook" ] ; then
        cookbook_version "$REPO" "$VSN"
    else
        echo "Invalid skeleton!"
        exit 1
    fi
}

scan_lines() {
    local STRING="$1"
    shift
    while [ ! -z "$1" ] ; do
        if [ "$1" == "$STRING" ] ; then
            return 0
        fi
        shift
    done
    return 1
}

commit_message() {
    local REPO="$1"
    local MSG="$2"
    cd $REPO
    echo "some kinda ${RANDOM}" > "foo"
    git add "foo"
    git commit -qm "$MSG" "foo"
}
