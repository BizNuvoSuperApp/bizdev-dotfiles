#!/bin/bash

# Short form: set -e
set -o errexit

# Print a helpful message if a pipeline with non-zero exit code causes the
# script to exit as described above.
trap 'echo "Aborting due to errexit on line $LINENO. Exit code: $?" >&2' ERR

trapcleanup() {
    if [[ -d build/tmp/.cache ]]; then
        echo "Cleaning up build temporary cache"
        rm -rf build/tmp/.cache
    fi
}
trap trapcleanup EXIT

# Allow the above trap be inherited by all functions in the script.
#
# Short form: set -E
set -o errtrace

# Return value of a pipeline is the value of the last (rightmost) command to
# exit with a non-zero status, or zero if all commands in the pipeline exit
# successfully.
set -o pipefail

# Set $IFS to only newline and tab.
#
# http://www.dwheeler.com/essays/filenames-in-shell.html
IFS=$'\n\t'

# This program's basename.
_ME="$(basename "${0}")"

# allow aliases
shopt -s expand_aliases

# Specify Umask for all files created
umask 002

# General commands

alias mkdir="\mkdir -p -v"
alias cp="\cp -v"
alias rm="\rm -f"
alias ln="\ln -v"
alias chmod="\chmod -v"


###############################################################################
# General Information
###############################################################################

_isWindows() {
    [[ -n "${WINDIR}" ]]
}

###############################################################################
# Error Messages
###############################################################################

# _exit_1()
#
# Usage:
#   _exit_1 <command>
#
# Description:
#   Exit with status 1 after executing the specified command with output
#   redirected to standard error. The command is expected to print a message
#   and should typically be either `echo`, `printf`, or `cat`.
_exit_1() {
    {
        printf "%s!!EXIT!! %s%s\n" "$(tput setaf 1)" "${@}" "$(tput sgr0)"
    } 1>&2
    exit 1
}

# _debug()
#
# Usage:
#   _debug <command>
#
# Description:
#   Print the specified command with output redirected to standard error.
#   The command is expected to print a message and should typically be either
#   `echo`, `printf`, or `cat`.
_log() {
    printf "\n%s == %s\n" "$(_decorate bold "$(_date)")" "${@}"
}

_info() {
	printf "\n"
    printf "%s" "${@}" | sed -e 's/[\t]//g' | fmt --width=95 | sed -e 's/^/== /g'
	printf "\n"
}

# _warn()
#
# Usage:
#   _warn <command>
#
# Description:
#   Print the specified command with output redirected to standard error.
#   The command is expected to print a message and should typically be either
#   `echo`, `printf`, or `cat`.
_warn() {
  {
    printf "\n%s!!! %s%s\n" "$(tput setaf 1)" "${@}" "$(tput sgr0)"
  } 1>&2
}

# _error()
#
# Usage:
#   _error <command>
#
# Description:
#   Print the specified command with output redirected to standard error.
#   The command is expected to print a message and should typically be either
#   `echo`, `printf`, or `cat`.
_error() {
  {
    printf "\n%sERR %s%s\n" "$(tput setaf 1)" "${@}" "$(tput sgr0)"
  } 1>&2
}

_die() {
    local _ret="${2:-1}"
    echo "$1" >&2
    exit "${_ret}"
}

###############################################################################
# Utility Functions
###############################################################################

# _blank()
#
# Usage:
#   _blank <argument>
#
# Exit / Error Status:
#   0 (success, true)  If <argument> is not present or null.
#   1 (error,  false)  If <argument> is present and not null.
_blank() {
    [[ -z "${1:-}" ]]
}

# _present()
#
# Usage:
#   _present <argument>
#
# Exit / Error Status:
#   0 (success, true)  If <argument> is present and not null.
#   1 (error,  false)  If <argument> is not present or null.
_present() {
    [[ -n "${1:-}" ]]
}


_eq() {
    [[ "${1:-}" == "${2:-}" ]]
}

_neq() {
    [[ "${1:-}" != "${2:-}" ]]
}

_matches() {
    [[ "${1:-}" =~ ${2:-} ]]
}

# _contains()
#
# Usage:
#   _contains <query> <list-item>...
#
# Exit / Error Status:
#   0 (success, true)  If the item is included in the list.
#   1 (error,  false)  If not.
#
# Examples:
#   _contains "${_query}" "${_list[@]}"
_contains() {
  local _query="${1:-}"
  shift

  if [[ -z "${_query}"  ]] ||
     [[ -z "${*:-}"     ]]
  then
    return 1
  fi

  for __element in "${@}"
  do
    [[ "${__element}" == "${_query}" ]] && return 0
  done

  return 1
}


# _isTrue()
#
# Usage:
#   _isTrue <argument>
#
# Exit / Error Status:
#   0 (success, true)  If <argument> is present and equals true.
#   1 (error,  false)  If <argument> is not present or not equals true.
_isTrue() {
    [[ "${1:-}" == true ]]
}

# _isFalse()
#
# Usage:
#   _isFalse <argument>
#
# Exit / Error Status:
#   0 (success, true)  If <argument> is not present or not equals true.
#   1 (error,  false)  If <argument> is present and equals true.
_isFalse() {
    [[ "${1:-}" != true ]]
}


# _isOn()
#
# Usage:
#   _isOn <argument>
#
# Exit / Error Status:
#   0 (success, true)  If <argument> is present and equals "on".
#   1 (error,  false)  If <argument> is not present or not equals "on".
_isOn() {
    [[ "${1:-}" == "on" ]]
}

_ifOn() {
    if _isOn "${1:-}"; then
        printf "%s" "${2:-}"
    else
        printf ""
    fi
}

# _isOff()
#
# Usage:
#   _isOff <argument>
#
# Exit / Error Status:
#   0 (success, true)  If <argument> is present and equals "off".
#   1 (error,  false)  If <argument> is not present or not equals "off".
_isOff() {
    [[ "${1:-}" == "off" ]]
}

_ifOff() {
    if _isOff "${1:-}"; then
        printf "%s" "${2:-}"
    else
        printf ""
    fi
}


_if() {
    if ${1:-} ; then
       printf "%s" "${2:-}"
    else
       printf "%s" "${3:-}"
    fi
}


_date() {
    if _eq file "$1" ; then
        TZ='America/New_York' date +'%Y%m%d-%H%M%S'
    else
        TZ='America/New_York' date +'%Y-%m-%d %H:%M:%S'
    fi
}

_decorate() {
    local opts
    local prefix=""
    local suffix=""

    if _neq dumb "${TERM}" ; then
        IFS=':' read -r -a opts <<< "$1"

        for opt in "${opts[@]}"; do
            case $opt in
            bold)       prefix="$(tput bold)${prefix}" ;;
            ul)         prefix="$(tput smul)${prefix}" ;;
            rev)        prefix="$(tput rev)${prefix}" ;;
            standout)   prefix="$(tput smso)${prefix}" ;;
            boldred)    prefix="$(tput setaf 7)$(tput setab 1)${prefix}" ;;
            esac
        done

        suffix="$(tput sgr0)"
    fi

    printf "%s%s%s" "${prefix}" "${2:-}" "${suffix}"
}



_exists() {
    [[ -n "${1:-}" && -e "${1:-}" ]]
}

_isFile() {
    [[ -n "${1:-}" && -f "${1:-}" ]]
}

_isDir() {
    [[ -n "${1:-}" && -d "${1:-}" ]]
}

_notEmpty() {
    [[ -n "${1:-}" && -s "${1:-}" ]]
}

_isEmpty() {
    [[ -n "${1:-}" && ! -s "${1:-}" ]]
}


_confirmEnter() {
    read -s -p "${1:-Press ENTER to continue}"
}

_normalizeYesNo() {
    printf "%s" "${1}" | tr '[:upper:]' '[:lower:]'
}

_confirmYes() {
    local yn
    read -r -p "?? ${1:-Input} [y/N]? " yn
    yn="${yn:-n}"
    yn=$(_normalizeYesNo "${yn}")
    [[ ${yn} == "y" || ${yn} == "yes" ]]
}

_confirmNo() {
    local yn
    read -r -p "?? ${1:-Input} [Y/n] " yn
    yn="${yn:-y}"
    yn=$(_normalizeYesNo "${yn}")
    [[ ${yn} == "n" || ${yn} == "no" ]]
}

_enterValue() {
    _present "${1}" || _exit_1 "Must specify prompt message"

    local input
    read -r -p "?? ${1:-Input} : " input

    _blank "${input}" && _present "${2}" && input="${2}"

    printf "%s" "${input}"
}
