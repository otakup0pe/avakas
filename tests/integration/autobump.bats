#!/usr/bin/env bats
# -*- mode: Shell-script;bash -*-

load helper

setup() {
    shared_setup
    REPO_ORIGIN=$(fake_repo)
    template_skeleton "$REPO_ORIGIN" plain "0.0.1"
    origin_repo "$REPO_ORIGIN"
    REPO=$(clone_repo $REPO_ORIGIN)
    cd "$REPO"
}

teardown() {
    shared_teardown
}

@test "autobump a plain version - patch" {
    commit_message "$REPO" "some thing\nbump:patch"
    avakas_wrapper bump "$REPO" auto
    avakas_wrapper show "$REPO"
    [ "$output" == "0.0.2" ]
    commit_message "$REPO" "some boring junk"
    commit_message "$REPO" "more boring junk"
    commit_message "$REPO" "we who are dreamers\nbump:patch"
    avakas_wrapper bump "$REPO" auto
    avakas_wrapper show "$REPO"
    [ "$output" == "0.0.3" ]
}
@test "autobump a plain version - minor" {
    commit_message "$REPO" "some thing\nbump:minor"
    avakas_wrapper bump "$REPO" auto
    avakas_wrapper show "$REPO"
    [ "$output" == "0.1.0" ]
    commit_message "$REPO" "some boring junk"
    commit_message "$REPO" "more boring junk"
    commit_message "$REPO" "we who are dreamers\nbump:minor"
    avakas_wrapper bump "$REPO" auto
    avakas_wrapper show "$REPO"
    [ "$output" == "0.2.0" ]
    commit_message "$REPO" "some boring junk\nbump:patch"
    commit_message "$REPO" "slightly less boring junk\nbump:minor"
    commit_message "$REPO" "still here tho"
    avakas_wrapper bump "$REPO" auto
    avakas_wrapper show "$REPO"
    [ "$output" == "0.3.0" ]    
}
@test "autobump a plain version - major" {
    commit_message "$REPO" "some thing\nbump:major"
    avakas_wrapper bump "$REPO" auto
    avakas_wrapper show "$REPO"
    [ "$output" == "1.0.0" ]
    commit_message "$REPO" "some boring junk"
    commit_message "$REPO" "more boring junk"
    commit_message "$REPO" "we who are dreamers\nbump:major"
    avakas_wrapper bump "$REPO" auto
    avakas_wrapper show "$REPO"
    [ "$output" == "2.0.0" ]
    commit_message "$REPO" "some boring junk\nbump:patch"
    commit_message "$REPO" "slightly less boring junk\nbump:major"
    commit_message "$REPO" "some boring junk\nbump:minor"    
    commit_message "$REPO" "still here tho"
    avakas_wrapper bump "$REPO" auto
    avakas_wrapper show "$REPO"
    [ "$output" == "3.0.0" ]    
}

@test "autobump a plain version - complex" {
    commit_message "$REPO" "some boring stuff"
    commit_message "$REPO" "more boring stuff"
    commit_message "$REPO" "more boring stuff\nmore\nbump:patch\neven more"
    avakas_wrapper bump "$REPO" auto
    avakas_wrapper show "$REPO"
    [ "$output" == "0.0.2" ]
    commit_message "$REPO" "blah blah"
    avakas_wrapper bump "$REPO" auto
    avakas_wrapper show "$REPO"
    [ "$output" == "0.0.2" ]
    commit_message "$REPO" "some progress report"
    commit_message "$REPO" "TPS reports tho"
    commit_message "$REPO" "This is the year it happens tho"
    commit_message "$REPO" "release time party time \nbump:major"
    avakas_wrapper bump "$REPO" auto
    avakas_wrapper show "$REPO"
    [ "$output" == "1.0.0" ]
    commit_message "$REPO" "some kinda bugfix"
    commit_message "$REPO" "oh hey feature tho\nbump:minor"
    avakas_wrapper bump "$REPO" auto
    avakas_wrapper show "$REPO"
    [ "$output" == "1.1.0" ]    
}
