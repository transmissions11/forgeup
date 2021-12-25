#!/bin/bash

setUp() {
  FOUNDRY_DIR='../FOUNDRY_DIR'

  mkdir -p user_home
  export FOUNDRY_DIR_HOME='user_home'
}

tearDown() {
  rm -rf user_home
}

testPrintVersion() {
  $FOUNDRY_DIR -v 2>/dev/null
  assertEquals 0 $?
}

testPrintHelp() {
  $FOUNDRY_DIR -h 2>/dev/null
  assertEquals 10 $?
}

. shunit2
