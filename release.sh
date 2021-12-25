#!/bin/bash
#
set -o errexit

declare -r version="$1"
release-pre "$version"
release-post "$version"

foundry replace foundry "$version"

exit 0