#!/usr/bin/env bats
# -*- mode: Shell-script;bash -*-

load helper

setup() {
    shared_setup
    REPO_ORIGIN=$(fake_repo)
    template_skeleton "$REPO_ORIGIN" plain "0.0.1"
    origin_repo "$REPO_ORIGIN"
    REPO=$(clone_repo $REPO_ORIGIN)
}

teardown() {
    shared_teardown
}

@test "show a git-native version" {
    avakas_wrapper show "$REPO"  --flavor="git-native"
    scan_lines "0.0.1" "${lines[@]}"
    [ -e "$REPO/version" ]
}

@test "show a git-native version with a tag prefix" {
    commit_message "$REPO" "whorp\nbump:minor"
    tag_repo "$REPO" "v0.0.1" "latest"
    avakas_wrapper show "$REPO"  --flavor="git-native" --tag-prefix "v"
    scan_lines "v0.0.1" "${lines[@]}"
    [ -e "$REPO/version" ]
}

@test "ignore non-version tags on autobump" {
    avakas_wrapper  set "$REPO" --flavor "git-native" "1.0.0"

    commit_message "$REPO" "whorp\nbump:minor"
    echo "committed"
    tag_repo "$REPO" "Florf" "latest"
    echo "tagged"
    avakas_wrapper bump "$REPO" auto --flavor "git-native"
    [ "$output" == "Version updated from 1.0.0 to 1.1.0" ]
    avakas_wrapper show "$REPO" --flavor "git-native"
    [ "$output" == "1.1.0" ]

}

@test "set a git-native version" {
    avakas_wrapper set "$REPO" "0.0.2" --flavor "git-native"
    scan_lines "Version set to 0.0.2" "${lines[@]}"
    avakas_wrapper show "$REPO" --flavor "git-native"
    scan_lines "0.0.2" "${lines[@]}"
    [ -e "$REPO/version" ]
}


@test "set a git-native version with tag prefix" {
    avakas_wrapper set "$REPO" "v0.0.2" --flavor "git-native" --tag-prefix "v"
    scan_lines "Version set to v0.0.2" "${lines[@]}"
    avakas_wrapper show "$REPO" --flavor "git-native" --tag-prefix "v"
    scan_lines "v0.0.2" "${lines[@]}"
    [ -e "$REPO/version" ]
}

@test "bump a git-native version" {
    avakas_wrapper bump "$REPO" patch --flavor "git-native"
    scan_lines "Version updated from 0.0.1 to 0.0.2" "${lines[@]}"
    avakas_wrapper show "$REPO" --flavor "git-native"
    scan_lines "0.0.2" "${lines[@]}"
    [ -e "$REPO/version" ]
}

@test "bump a git-native version with tag prefix" {
    tag_repo "$REPO" 'v0.0.1' "latest"
    avakas_wrapper bump "$REPO" patch --flavor "git-native" --tag-prefix 'v'
    scan_lines "Version updated from v0.0.1 to v0.0.2" "${lines[@]}"
    avakas_wrapper show "$REPO" --flavor "git-native" --tag-prefix 'v'
    scan_lines "v0.0.2" "${lines[@]}"
    [ -e "$REPO/version" ]
}

@test "autobump git-native version once" {
    cd $REPO
    commit_message "$REPO" "you're probably not gonna read this anyway\nbump:patch"
    avakas_wrapper bump "$REPO" auto --flavor "git-native"
    avakas_wrapper show "$REPO" --flavor "git-native"
    [ "$output" == "0.0.2" ]
}

@test "autobump git-native version once with tag prefix" {
    cd $REPO
    commit_message "$REPO" "initial commit!"
    tag_repo "$REPO" 'v0.0.1' "latest"
    commit_message "$REPO" "you're probably not gonna read this anyway\nbump:patch"
    avakas_wrapper bump "$REPO" auto --tag-prefix "v" --flavor "git-native"
    git show-ref --tags
    avakas_wrapper show "$REPO" --flavor "git-native" --tag-prefix "v"
    [ "$output" == "v0.0.2" ]
}

@test "autobump git-native version once with tag prefix and build info" {
    cd $REPO
    commit_message "$REPO" "initial commit!"
    tag_repo "$REPO" 'v0.0.1' "latest"
    commit_message "$REPO" "you're probably not gonna read this anyway\nbump:patch"
    avakas_wrapper bump "$REPO" auto --tag-prefix "v" --flavor "git-native" --build-meta

    REV=$(current_rev $REPO)
    avakas_wrapper show "$REPO" --flavor "git-native" --tag-prefix "v"
    [[ "$output" =~ ^v0\.0\.2\+${REV} ]]
}

# I'm not sure how to disable a test, this is for behaviour we want in the future
#@test "autobump git-native version once with tag prefix, prerelease prefix, and build info" {
#    cd $REPO
#    commit_message "$REPO" "initial commit!"
#    tag_repo "$REPO" 'v0.0.1' "latest"
#    commit_message "$REPO" "you're probably not gonna read this anyway\nbump:minor"
#    avakas_wrapper bump "$REPO" auto --tag-prefix "v" --prerelease-prefix "pre" --flavor "git-native" --build
#    REV=$(current_rev $REPO)
#    avakas_wrapper show "$REPO" --flavor "git-native" --tag-prefix "v"
#    [[ "$output" =~ ^v0\.1\.0\-pre.0+${REV} ]]
#}

@test "autobump git-native versions multiple times" {
    cd $REPO
    commit_message "$REPO" "initial commit!"
    tag_repo "$REPO" 'v0.0.1' "latest"
    commit_message "$REPO" "whorp\nbump:patch"
    avakas_wrapper bump "$REPO" auto  --flavor "git-native" --tag-prefix "v"
    avakas_wrapper show "$REPO" --flavor "git-native" --tag-prefix "v"
    [ "$output" == "v0.0.2" ]
    avakas_wrapper bump "$REPO" auto  --flavor "git-native" --tag-prefix "v"
    avakas_wrapper show "$REPO" --flavor "git-native" --tag-prefix "v"
    [ "$output" == "v0.0.2" ]
    avakas_wrapper bump "$REPO" auto  --flavor "git-native" --tag-prefix "v"
    avakas_wrapper show "$REPO" --flavor "git-native" --tag-prefix "v"
    [ "$output" == "v0.0.2" ]
    avakas_wrapper bump "$REPO" auto  --flavor "git-native" --tag-prefix "v"
    avakas_wrapper show "$REPO" --flavor "git-native" --tag-prefix "v"
    [ "$output" == "v0.0.2" ]
}

@test "autobump git-native versions with prereleases" {
    cd $REPO
    commit_message "$REPO" "FLunkf\nbump:patch"

    avakas_wrapper bump "$REPO" auto --flavor "git-native" --prerelease --prerelease-prefix 'alpha'
    [[ "$output"  =~ ^Version\ updated\ from\ 0\.0\.1\ to\ 0\.0\.2-alpha\.1 ]]
    avakas_wrapper show "$REPO" --flavor "git-native"
    [ "$output" == "0.0.2-alpha.1" ]

    commit_message "$REPO" "squirrels"
    avakas_wrapper bump "$REPO" auto --flavor "git-native" --prerelease --prerelease-prefix 'alpha'
    [ "$output" == "Version updated from 0.0.2-alpha.1 to 0.0.2-alpha.2" ]
    avakas_wrapper show "$REPO" --flavor "git-native"
    [ "$output" == "0.0.2-alpha.2" ]

    avakas_wrapper bump "$REPO" auto --flavor "git-native"
    [ "$output" == "Version updated from 0.0.2-alpha.2 to 0.0.2" ]

    # Should do nothing because no bumps in messages since last non-prerelease bump
    avakas_wrapper bump "$REPO" auto --flavor "git-native" --prerelease --prerelease-prefix 'beta'
    [ "$output" == "" ]
    avakas_wrapper show "$REPO" --flavor "git-native"
    [ "$output" == "0.0.2" ]

    commit_message "$REPO" "hwhelp\nbump:minor"

    avakas_wrapper bump "$REPO" auto --flavor "git-native" --prerelease --prerelease-prefix 'beta'
    [ "$output" == "Version updated from 0.0.2 to 0.1.0-beta.1" ]
    avakas_wrapper show "$REPO" --flavor "git-native"
    [ "$output" == "0.1.0-beta.1" ]

    # No commits since last pre-release bump
    avakas_wrapper bump "$REPO" auto --flavor "git-native" --prerelease --prerelease-prefix 'beta'
    [ "$output" == "" ]
    avakas_wrapper show "$REPO" --flavor "git-native"
    [ "$output" == "0.1.0-beta.1" ]
}

@test "autobump git-native versions with prereleases and tag prefixes" {
    cd $REPO
    commit_message "$REPO" "initial commit!"
    tag_repo "$REPO" 'v1.0.1' "latest"

    commit_message "$REPO" "FLunkf\nbump:patch"
    avakas_wrapper bump "$REPO" auto --tag-prefix "v" --flavor "git-native" --prerelease --prerelease-prefix 'alpha'
    [ "$output"  == "Version updated from v1.0.1 to v1.0.2-alpha.1" ]
    avakas_wrapper show "$REPO" --flavor "git-native" --tag-prefix 'v'
    [ "$output" == "v1.0.2-alpha.1" ]

    commit_message "$REPO" "squirrels"
    avakas_wrapper bump "$REPO" auto --tag-prefix "v" --flavor "git-native" --prerelease --prerelease-prefix 'alpha'
    [ "$output" == "Version updated from v1.0.2-alpha.1 to v1.0.2-alpha.2" ]
    avakas_wrapper show "$REPO" --flavor "git-native" --tag-prefix 'v'
    [ "$output" == "v1.0.2-alpha.2" ]

    avakas_wrapper bump "$REPO" auto --tag-prefix "v" --flavor "git-native"
    [ "$output" == "Version updated from v1.0.2-alpha.2 to v1.0.2" ]

    # Should do nothing because no bumps in messages since last non-prerelease bump
    avakas_wrapper bump "$REPO" auto --tag-prefix "v" --flavor "git-native" --prerelease --prerelease-prefix 'beta'
    [ "$output" == "" ]
    avakas_wrapper show "$REPO" --flavor "git-native" --tag-prefix 'v'
    [ "$output" == "v1.0.2" ]

    commit_message "$REPO" "hwhelp\nbump:minor"

    avakas_wrapper bump "$REPO" auto --tag-prefix "v" --flavor "git-native" --prerelease --prerelease-prefix 'beta'
    avakas_wrapper show "$REPO" --tag-prefix 'v' --flavor "git-native"
    [ "$output" == "v1.1.0-beta.1" ]

    # No commits since last pre-release bump
    avakas_wrapper bump "$REPO" auto --flavor "git-native" --tag-prefix "v" --prerelease --prerelease-prefix 'beta'
    avakas_wrapper show "$REPO" --flavor "git-native" --tag-prefix 'v'
    [ "$output" == "v1.1.0-beta.1" ]
}
