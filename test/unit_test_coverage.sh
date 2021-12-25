#!/bin/bash

setUp() {
  . '../bin/binary'

  FOUNDRY_DIR=$(mktemp -d)
  pd=$FORGE_UP # alias to reduce character count
}

tearDown() {
  rm -rf $pd
}

testInstallProgramNameEmpty() {
  install_program
  assertEquals 5 $?
}

testInstallProgramVersionEmpty() {
  install_program forge
  assertEquals 6 $?
}

testInstallProgramCommandLine() {
  load_cli() {
    assertEquals forge $1
    assertEquals 0.1.0 $VERSION
    return 1
  }

  local msg=$(
    install_program forge 0.1.0 2>&1
    assertEquals 1 $?
  )
  assertEquals "Error CLI: forge" "$msg"
}

testUrlNoArguments() {
  (
    url
    assertTrue "[ -z $URL ]"
  )
}

testUrlOneArgument() {
  (
    url 'https://github.com'
    assertEquals 'https://github.com' "$URL"
  )
}

testUrlTwoArguments() {
  (
    url 'https://github.com' 'http://crates.io'
    assertEquals 'https://github.com http://crates.io' "$URL"
  )
}

source testbash
