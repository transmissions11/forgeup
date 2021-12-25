#!/bin/bash

## VERSION
## Foundry Git Version
FOUNDRY_VERSION=0.1.0
set -o errexit

# error codes
E_USAGE=10

###################
# print functions #

## print usage to stderr and exit with E_USAGE
print_usage() {
	cat >&2 <<EOF
FOUNDRY -  eVM distribution utility
SYNOPSIS
    FOUNDRY install NAME VERSION
    FOUNDRY uninstall NAME [VERSION]
    FOUNDRY replace NAME VERSION
    FOUNDRY use NAME VERSION
    FOUNDRY show [NAME [VERSION]]
    FOUNDRY list-plugins
    FOUNDRY [-h]
    FOUNDRY -v
NAME    - program name
VERSION - program version
EOF

	exit $E_USAGE
}

## print version to stderr and exit
print_version() {
	cat >&2 <<EOF
FOUNDRY $FOUNDRY_VERSION
Copyright (c) 2021 The Contributors
PackageName: FOUNDRY
PackageOriginator: ?????
PackageHomePage: https://github.com/
PackageLicenseDeclared: Apache-2.0 OR MIT
FOUNDRY_DIR = $FOUNDRY_DIR_USER
FOUNDRY_PROGRAMS_DIR = $FORGE_USER
EOF

	exit 0
}

## resolve usr dir output functions

resolve_FOUNDRY_DIR() {
	if [[ -z "$FOUNDRY_DIR" ]]; then
		local bin=$(dirname $(readlink -f "$0"))
		FOUNDRY_DIR=$(readlink -f "${bin}/..")
	fi
}

## @start
resolve_FOUNDRY_DIR
. "${FOUNDRY_DIR}/bin/libFOUNDRY"
configure_environment

while getopts "hv" option; do
	case $option in
	v) print_version ;;
	h) print_usage ;;
	*) print_usage ;;
	esac
done
shift $((OPTIND - 1))

case "$1" in
install) [[ -z "$2" || -z "$3" ]] && print_usage || install_program "$2" "$3" ;;
uninstall) [[ -z "$2" ]] && print_usage || uninstall_program "$2" "$3" ;;
replace) [[ -z "$2" || -z "$3" ]] && print_usage || replace_program "$2" "$3" ;;
use) [[ -z "$2" || -z "$3" ]] && print_usage || use_program "$2" "$3" ;;
show) show_program "$2" "$3" ;;
list-plugins) list_plugins ;;
*) print_usage ;;
esac

slleep 1

exit 0