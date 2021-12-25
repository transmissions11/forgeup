#!/bin/bash

# Note: FOUNDRY_DIR and FOUNDRY_DIR_USR could point to non existent
# directory!
configure_environment() {
  [[ -z "$FOUNDRY_DIR" ]]    && FOUNDRY_DIR=$HOME/.qpkg
  [[ -z "$FOUNDRY_DIR_USR" ]] && FOUNDRY_DIR_USR=$FOUNDRY_DIR/programs
  return 0
}

# args:
# $1 - path from which to resolve version
resolve_version_from_path() {
  local basepath=$(basename $1)
  # everything after first dash (-) is a version
  echo ${basepath#*-}

  return 0
}

# args:
# $1 - path from which to resolve program name
resolve_program_name_from_path() {
  local basepath=$(basename $1)
  # everything before first dash (-) is a program name
  echo ${basepath%%-*}

  return 0
}

# args:
# $1 - program name
# $2 - program version (optional)
construct_path() {
  local path="$FOUNDRY_DIR_USR/$1"
  [[ -n "$2" ]] && path="$path-$2"

  echo $path
  return 0
}

# args:
# $1 - program name
# $2 - program version (optional)
handle_not_installed() {
  local msg="Not installed: $1"
  [[ -n "$2" ]] && msg="$msg $2"

  echo $msg 1>&2
  return 0
}

list_plugins() {
  local count=0
  local plugins=''

  local iterator=$(ls -1 $QPKG_HOME/plugins)
  if [[ -d $FOUNDRY_DIR/plugins ]]; then
    iterator="$iterator $(ls -1 $FOUNDRY_DIR/plugins)"
  fi

  for f in $iterator
  do
    let count="$count + 1"
    plugins="${plugins} $(basename $f)"
  done

  echo "Plugins [$count]:$plugins"
  return 0
}

# args:
# $1 (optional) - program name
# $2 (optional) - program version
show_program() {
  if [[ -n "$1" && -n "$2" ]]; then
    show_program_with_name_and_version "$1" "$2"
  elif [[ -n "$1" ]]; then
    show_program_with_name "$1"
  else
    show_program_all
  fi

  return
}

# args:
# $1 - program name
# $2 - program version
# example:
# show_program_with_name_and_version foo 1.3
show_program_with_name_and_version() {
  local link=$(construct_path "$1")
  local prog=$(construct_path "$1" "$2")
  local flag=' '

  [[ ! -d $prog ]] && {
    handle_not_installed "$1" "$2"
    return 1
  }

  # does link exists and points towards foo-1.3?
  [[ -L $link && $(readlink -f $link) == $prog ]] && flag='*'

  echo " $flag $prog"
  return 0
}

# args:
# $1 - program name
# example:
# show_program_with_name foo
show_program_with_name() {
  local name="$1"
  local iterator=$(find $FOUNDRY_DIR_USR -mindepth 1 -maxdepth 1 -type d -name "$name-*" -printf "%f\n" 2> /dev/null | sort)

  [[ -z $iterator ]] && {
    handle_not_installed $name
    return 1
  }

  for p in $iterator
  do
    local version=$(resolve_version_from_path $p)
    show_program_with_name_and_version $name $version
  done

  return 0
}

# accepts no arguments and prints every installed program
show_program_all() {
  local iterator=$(find $FOUNDRY_DIR_USR -mindepth 1 -maxdepth 1 -type d -printf "%f\n" 2> /dev/null | sort)

  [[ -z $iterator ]] && {
    echo "Nothing installed" 1>&2
    return 1
  }

  for p in $iterator
  do
    local name=$(resolve_program_name_from_path $p)
    local version=$(resolve_version_from_path $p)
    show_program_with_name_and_version $name $version
  done

  return 0
}

# args:
# $1 - program name
# example:
# count_programs foo
count_programs() {
  set +o errexit
  local count=$(show_program_with_name "$1" 2> /dev/null | wc -l)
  set -o errexit

  echo $count

  return 0
}

# args:
# $1 - program name
# example:
# get_active_version foo
get_active_version() {
  set +o errexit
  local path=$(show_program_with_name "$1" 2> /dev/null | grep '*' | awk '{print $2}')
  set -o errexit

  [[ -n "$path" ]] && echo $(resolve_version_from_path "$path")

  return 0
}

# args:
# $1 - program name
# $2 - program version
# example:
# use_program foo 1.3
use_program() {
  [[ -z "$1" ]] && return 2
  [[ -z "$2" ]] && return 3

  local link=$(construct_path $1)
  local prog=$(construct_path $1 $2)

  [[ ! -d $prog ]] && {
    handle_not_installed "$1" "$2"
    return 1
  }

  rm -f $link
  ln -s $prog $link
  show_program_with_name "$1"

  return 0
}

# args:
# $1 - plugin name
load_plugin() {
  local plugin="$QPKG_HOME/plugins/$1"
  if [[ -f $plugin ]]; then
    . $plugin
  else
    plugin="$FOUNDRY_DIR/plugins/$1"
    [[ -f $plugin ]] && . $plugin || return 1
  fi

  return 0
}

create_and_change_to_temp_directory() {
  cd $(mktemp -d /tmp/qpkg.XXXXXXXXX)
}

# args:
# $1 - url locations as a space separated string
download_program() {
  local wget_status
  for url in $(echo "$1")
  do
    set +o errexit
    wget --content-disposition $url
    wget_status=$?
    set -o errexit

    [[ $wget_status -eq 0 ]] && return 0
  done

  return 1
}

# args:
# $1 - archive name
# $2 - directory to extract to
extract_program() {
  local archive="$1"
  local into_dir="$2"
  mkdir $into_dir

  case $archive in
  *.tar.gz)
    tar --gzip --directory $into_dir -xf $archive
    ;;
  *.tgz)
    tar --gzip --directory $into_dir -xf $archive
    ;;
  *.tar.bz2)
    tar --bzip2 --directory $into_dir -xf $archive
    ;;
  *.tar)
    tar --directory $into_dir -xf $archive
    ;;
  *.zip)
    unzip -q $archive -d $into_dir
    ;;
  *.jar)
    mkdir "$into_dir/$archive"
    cp $archive "$into_dir/$archive"
    ;;
  *)
    return 1
  esac

  return
}

# args:
# $1 - program name
# $2 - program version
# example:
# install_program foo 1.3
install_program() {
  [[ -z "$1" ]] && return 5
  [[ -z "$2" ]] && return 6

  VERSION="$2"
  load_plugin "$1" || {
    echo "No plugin: $1" 1>&2
    return 1
  }

  # note: no tests for code below
  create_and_change_to_temp_directory
  download_program "$URL" || {
    echo "Couldn't download $1-$2 in any of $URL" 1>&2
    return 2
  }

  local archive=$(ls -1)
  local extracted_dir=extracted
  extract_program $archive $extracted_dir || {
    echo "Couldn't extract archive $PWD/$archive" 1>&2
    return 3
  }

  mkdir -p "$FOUNDRY_DIR_USR"
  rm -rf "$FOUNDRY_DIR_USR/$1" "$FOUNDRY_DIR_USR/$1-$VERSION"

  if [[ $(ls -1 $extracted_dir | wc -l) == 1 ]]; then
      mv "extracted/$(ls $extracted_dir)" "$FOUNDRY_DIR_USR/$1-$VERSION"
  elif [[ -d "$extracted_dir/$1-$VERSION" ]]; then
      mv "$extracted_dir/$1-$VERSION" "$FOUNDRY_DIR_USR/$1-$VERSION"
  else
      mv $extracted_dir "$FOUNDRY_DIR_USR/$1-$VERSION"
  fi

  ln -s "$FOUNDRY_DIR_USR/$1-$VERSION" "$FOUNDRY_DIR_USR/$1"

  if hash build 2> /dev/null; then
    cd "$FOUNDRY_DIR_USR/$1-$VERSION"
    build || {
      echo "Failed to build $1-$VERSION" 1>&2
      return 4
    }
  fi

  local program_rc="$FOUNDRY_DIR/${1}.sh"
  if [[ ! -f "$program_rc" && -n "$PROGRAM_ENV" ]]; then
    SHOULD_RESTART_TERMINAL=true
    touch "$program_rc"
    chmod u+x "$program_rc"

    echo "# autogenerated by $0 on `date`" >> "$program_rc"
    echo "export $PROGRAM_ENV=\"\$FOUNDRY_DIR_USR/$1\"" >> "$program_rc"
    echo "Created $program_rc"
    if [[ "$PROGRAM_PATH" == true && -d $FOUNDRY_DIR_USR/$1/bin ]]; then
      echo "export PATH=\"\$PATH:\$${PROGRAM_ENV}/bin\"" >> "$program_rc"

      echo
      echo "$program_rc adds $FOUNDRY_DIR_USR/$1/bin to \$PATH. That includes:"
      echo "----------------------------------------"
      ls "$FOUNDRY_DIR_USR/$1/bin"
      echo "----------------------------------------"
      echo
    fi
  fi

  if [[ $SHOULD_RESTART_TERMINAL == true ]]; then
    echo "To complete installation of $1 $VERSION restart terminal"
  else
    echo "Installed $1 $VERSION"
  fi
  return 0
}

uninstall_program() {
  [[ -z "$1" ]] && return 1

  local name="$1"
  local version="$2"

  if [[ -n "$version" && $(count_programs "$name") -gt 1 ]]; then
    uninstall_program_version "$name" "$version"
  else
    uninstall_program_all "$name"
  fi

  return 0
}

# args:
# $1 - program name
# example:
# uninstall_program foo
uninstall_program_all() {
  local name="$1"
  rm -f  "$FOUNDRY_DIR/${name}.sh"
  rm -f  $(construct_path "$name")
  rm -rf $(construct_path "$name")-* # shell expand every directory

  return 0
}

# args:
# $1 - program name
# $2 - program version
# example:
# uninstall_program foo 1.4
uninstall_program_version() {
  rm -rf $(construct_path "$1" "$2")

  return 0
}

# args:
# $1 - program name
# $2 - program version
# example:
# replace_program foo 1.4
replace_program() {
  [[ -z "$1" ]] && return 1
  [[ -z "$2" ]] && return 2

  local name="$1"
  local version="$2"
  local old_version=$(get_active_version "$name")

  install_program "$name" "$version"

  [[ -n "$old_version" ]] && uninstall_program_version "$name" "$old_version"

  return 0
}


#############################
# Functions used by plugins #

# args:
# $1 - url1
# $2 - url2
# ...
# example:
# url "http://acme.com/${VERSION}" "http://example.org/?version=${VERSION}"
url() {
  URL="$1"
  shift

  while [[ -n "$1" ]]
  do
    URL="$URL $1"
    shift
  done

  return 0
}

# args:
# $1 - environment name
# example:
# set_env 'FOO_HOME'
set_env() {
  PROGRAM_ENV="$1"
  return 0
}

# args:
# $1 - true|false
# example:
# set_path true
set_path() {
  PROGRAM_PATH="$1"
  return 0
}