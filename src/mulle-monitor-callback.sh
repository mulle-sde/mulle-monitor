#! /usr/bin/env bash
#
#   Copyright (c) 2018 Nat! - Mulle kybernetiK
#   All rights reserved.
#
#   Redistribution and use in source and binary forms, with or without
#   modification, are permitted provided that the following conditions are met:
#
#   Redistributions of source code must retain the above copyright notice, this
#   list of conditions and the following disclaimer.
#
#   Redistributions in binary form must reproduce the above copyright notice,
#   this list of conditions and the following disclaimer in the documentation
#   and/or other materials provided with the distribution.
#
#   Neither the name of Mulle kybernetiK nor the names of its contributors
#   may be used to endorse or promote products derived from this software
#   without specific prior written permission.
#
#   THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
#   AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
#   IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
#   ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
#   LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
#   CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
#   SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
#   INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
#   CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
#   ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
#   POSSIBILITY OF SUCH DAMAGE.
#
MULLE_MONITOR_CALLBACK_SH="included"


monitor::callback::usage()
{
   if [ "$#" -ne 0 ]
   then
      log_error "$*"
   fi

   cat <<EOF >&2
Usage:
   ${MULLE_USAGE_NAME} callback <command>

   A callback is executed, when there has been an interesting change in the
   filesystem. These changes are categorized by "patternfile"s and
   are used to determine the callback to execute.

   A callback may return a string, which will be interpreted as a "task" to
   perform. See \`${MULLE_USAGE_NAME} task help\` and
   \`${MULLE_USAGE_NAME} patternfile help\` for more information.

Commands:
   cat       : print callback to stdout (hopefully it is readable)
   add       : install a callback
   list      : list installed callbacks (default)
   remove    : remove a callback
   run       : run a callback

EOF
   exit 1
}


monitor::callback::add_usage()
{
   if [ "$#" -ne 0 ]
   then
      log_error "$*"
   fi

   cat <<EOF >&2
Usage:
   ${MULLE_USAGE_NAME} callback add [options] <name> <executable>

   Install an executable as a mulle-sde callback.
EOF
   exit 1
}


monitor::callback::create_usage()
{
   if [ "$#" -ne 0 ]
   then
      log_error "$*"
   fi

   cat <<EOF >&2
Usage:
   ${MULLE_USAGE_NAME} callback create <name>

   Create a simple callback script, that merely triggers a task of the same
   name.

EOF
   exit 1
}


monitor::callback::edit_usage()
{
   if [ "$#" -ne 0 ]
   then
      log_error "$*"
   fi

   cat <<EOF >&2
Usage:
   ${MULLE_USAGE_NAME} callback edit <name>

   Edit a callback script.

EOF
   exit 1
}


monitor::callback::remove_usage()
{
   if [ "$#" -ne 0 ]
   then
      log_error "$*"
   fi

   cat <<EOF >&2
Usage:
   ${MULLE_USAGE_NAME} callback remove <callback>

   Remove callback.

EOF
   exit 1
}


monitor::callback::list_usage()
{
   if [ "$#" -ne 0 ]
   then
      log_error "$*"
   fi

   cat <<EOF >&2
Usage:
   ${MULLE_USAGE_NAME} callback list [options]

   List installed callbacks.

Options:
   --output-name : output the name of the callback (default)
   --output-path : output the location of the callback in the filesystem
   --cat         : show contents of the callback (assumed to be a shellscript)

EOF
   exit 1
}


monitor::callback::run_usage()
{
   if [ "$#" -ne 0 ]
   then
      log_error "$*"
   fi

   cat <<EOF >&2
Usage:
   ${MULLE_USAGE_NAME} callback run <name> ...

   Run a callback with the given name, passing any number of arguments to it.

EOF
   exit 1
}


monitor::callback::cat_usage()
{
   if [ "$#" -ne 0 ]
   then
      log_error "$*"
   fi

   cat <<EOF >&2
Usage:
   ${MULLE_USAGE_NAME} callback cat <name>

   Print a callback with the given name to stdout. Works nicely, if the
   callback is a script. Not so nice, if its a compiled binary..

EOF
   exit 1
}


monitor::callback::_r_callback_executable_install_filename()
{
   log_entry "monitor::callback::_r_callback_executable_install_filename" "$@"

   local callback="$1"

   local name

   r_identifier "${callback//_/+}"  # make underscores fail too
   if [ "${RVAL}" != "${callback}" ]
   then
      fail "\"${callback}\" must be a-zA-Z0-9-"
   fi

   RVAL="${MULLE_MONITOR_ETC_DIR}/bin/${callback}-callback"
}


monitor::callback::_r_callback_executable_filename()
{
   log_entry "monitor::callback::_r_callback_executable_filename" "$@"

   local callback="$1"
   local defaultcallback="$2"

   if [ "${callback}" = 'default' -a ! -z "${defaultcallback}" ]
   then
      case "${defaultcallback}" in
         echo\ *)
            log_debug "Shortcut for \"${defaultcallback}\" callback"
            RVAL="${defaultcallback}"
            return 0
         ;;
      esac

      r_absolutepath "${defaultcallback}"
   else
      [ -z "${MULLE_MONITOR_SHARE_DIR}" ] && internal_fail "MULLE_MONITOR_SHARE_DIR not set"

      RVAL="${MULLE_MONITOR_ETC_DIR}/bin/${callback}-callback"
      if [ ! -x "${RVAL}" ]
      then
         RVAL="${MULLE_MONITOR_SHARE_DIR}/bin/${callback}-callback"
      fi
   fi

   [ -x "${RVAL}" ]
}


monitor::callback::_r_locate()
{
   log_entry "monitor::callback::_r_locate" "$@"

   local callback="$1"

   if monitor::callback::_r_callback_executable_filename "${callback}" \
                                      "${MULLE_MONITOR_DEFAULT_CALLBACK}"
   then
      return 0
   fi

   if [ -f "${RVAL}" ]
   then
      log_error "\"${RVAL}\" is not executable"
      return 1
   fi

   log_error "\"${RVAL}\" not found"
   RVAL=
   return 1
}


monitor::callback::_cheap_help_options()
{
   local usage="$1"

   while :
   do
      case "$1" in
         -h*|--help|help)
            "${usage}"
         ;;

         -*)
             "${usage}" "Unknown option \"$1\""
         ;;

         *)
            break
         ;;
      esac

      shift
   done
}


monitor::callback::remove()
{
   log_entry "monitor::callback::remove" "$@"

   monitor::callback::_cheap_help_options "monitor::callback::remove_usage"

   [ "$#" -ne 1 ] && monitor::callback::remove_usage

   local callback="$1"

   local executable
   monitor::callback::_r_callback_executable_install_filename "${callback}"
   executable="${RVAL}"

   if [ ! -e "${executable}" ]
   then
      log_warning "\"${executable}\" does not exist."
      return 0
   fi

   remove_file_if_present "${executable}"
}


monitor::callback::add()
{
   log_entry "monitor::callback::add" "$@"

   monitor::callback::_cheap_help_options "monitor::callback::add_usage"

   [ "$#" -ne 2 ] && monitor::callback::add_usage

   local callback="$1"
   local filename="$2"

   validate_monitor_identifier "${callback}"

   [ -z "${filename}" ] && monitor::task::usage "missing filename"
   [ "${filename}" = "-" -o -f "${filename}" ] || fail "\"${filename}\" not found"

   local executable

   monitor::callback::_r_callback_executable_install_filename "${callback}"
   executable="${RVAL}"

   [ -e "${executable}" -a "${MULLE_FLAG_MAGNUM_FORCE}" = 'NO' ] \
      && fail "\"${executable}\" already exists. Use -f to clobber"

   local bindir

   r_dirname "${executable}"
   bindir="${RVAL}"

   if [ "${filename}" = "-" ]
   then
      local text

      text="`cat`" || exit 1
      mkdir_if_missing "${bindir}" # do as late as possible
      redirect_exekutor "${executable}" printf "%s\n" "${text}"
   else
      mkdir_if_missing "${bindir}"
      exekutor cp "${filename}" "${executable}"
   fi
   exekutor chmod +x "${executable}"
}


monitor::callback::emit_default()
{
   log_entry "monitor::callback::emit_default" "$@"

   local callback="$1"

   cat <<EOF
#! /usr/bin/env bash

printf "%s\n" "${callback}"

EOF
}


monitor::callback::create()
{
   log_entry "monitor::callback::create" "$@"

   monitor::callback::_cheap_help_options "monitor::callback::create"

   [ "$#" -ne 1 ] && monitor::callback::create_usage

   local callback="$1"

   validate_monitor_identifier "${callback}"
   monitor::callback::emit_default "${callback}" | monitor::callback::add "${callback}" "-"
}


monitor::callback::edit()
{
   log_entry "monitor::callback::edit" "$@"

   monitor::callback::_cheap_help_options "monitor::task::edit_usage"

   [ "$#" -ne 1 ] && monitor::task::edit_usage

   local callback="$1"

   local executable

   monitor::callback::_r_callback_executable_install_filename "${callback}"
   executable="${RVAL}"

   if [ ! -e "${executable}" ]
   then
      log_warning "\"${executable}\" does not exist."
      return 0
   fi

   ${EDITOR:-vi} "${executable}"
}


# "hidden" function used for testing

monitor::callback::locate()
{
   log_entry "monitor::callback::locate" "$@"

   monitor::callback::_cheap_help_options "monitor::callback::run_usage"

   [ "$#" -lt 1 ] && monitor::callback::run_usage

   local callback="$1"; shift


   if ! monitor::callback::_r_locate "${callback}"
   then
      return 1
   fi

   rexekutor printf "%s\n" "${RVAL}"
}


monitor::callback::run()
{
   log_entry "monitor::callback::run" "$@"

   monitor::callback::_cheap_help_options "monitor::callback::run_usage"

   [ "$#" -lt 1 ] && monitor::callback::run_usage

   local callback="$1" # not shifted anymore

   [ -z "${callback}" ] && monitor::callback::run_usage "empty callback"

   local executable

   if ! monitor::callback::_r_locate "${callback}"
   then
      return 1
   fi
   executable="${RVAL}"

   log_verbose "Execute callback \"${executable#${MULLE_USER_PWD}/}\""

   case "${executable}" in
      echo\ *)
         rexekutor ${executable}
         return 0
      ;;
   esac

   local rval 

   MULLE_BASHFUNCTIONS_LIBEXEC_DIR="${MULLE_BASHFUNCTIONS_LIBEXEC_DIR}" \
      exekutor "${executable}" ${MULLE_MONITOR_CALLBACK_FLAGS} "$@"
   rval=$?

   if [ $rval -ne 0 ]
   then
      log_error "${executable} ${MULLE_MONITOR_CALLBACK_FLAGS} $* failed"
   fi
   return $rval
}


monitor::callback::_list()
{
   local directory="$1"
   local mode="$2"

   (
      cd "${directory}" || exit 1

      local filename

      shell_enable_nullglob
      for filename in *-callback
      do
         case "${mode}" in
            'output-name')
               printf "   %s\n" "${filename%-callback}"
               continue
            ;;

            'output-path')
               printf "   %s/%s\n" "${directory#${MULLE_USER_PWD}/}" "${filename}"
            ;;

            'output-cat')
               log_info "${C_RESET_BOLD}   ${filename%-callback}:"
               sed -e '/^#/d' -e '/^$/d' -e 's/^/     /' "${filename}"
               echo
            ;;

            *)
               internal_fail "unknown mode \"${mode}\""
            ;;
         esac
      done
   )
}


monitor::callback::list()
{
   log_entry "monitor::callback::list" "$@"

   local OPTION_MODE="output-name"

   while :
   do
      case "$1" in
         -h*|--help|help)
            monitor::callback::list_usage
         ;;

         --output-path)
            OPTION_MODE='output-path'
         ;;

         --output-cat|--cat)
            OPTION_MODE="output-cat"
         ;;

         -*)
            monitor::callback::list_usage "Unknown option \"$1\""
         ;;

         *)
            break
         ;;
      esac

      shift
   done


   [ "$#" -ne 0 ] && monitor::callback::list_usage

   if [ -d "${MULLE_MONITOR_ETC_DIR}/bin" ]
   then
      log_info "User Callbacks"
      log_verbose "Custom callbacks override extension callbacks of same name"
      log_verbose "   ${C_RESET_BOLD}${MULLE_MONITOR_ETC_DIR#${MULLE_USER_PWD}/}/bin"
      monitor::callback::_list "${MULLE_MONITOR_ETC_DIR}/bin" "${OPTION_MODE}"
   fi

   if [ -d "${MULLE_MONITOR_SHARE_DIR}/bin" ]
   then
      log_info "Extension Callbacks"
      log_verbose "   ${C_RESET_BOLD}${MULLE_MONITOR_SHARE_DIR#${MULLE_USER_PWD}/}/bin"

      monitor::callback::_list "${MULLE_MONITOR_SHARE_DIR}/bin" "${OPTION_MODE}"
   fi
}


monitor::callback::cat()
{
   log_entry "monitor::callback::cat" "$@"

   monitor::callback::_cheap_help_options "monitor::callback::cat"

   [ "$#" -lt 1 ] && monitor::callback::cat_usage

   local callback="$1"; shift

   [ -z "${callback}" ] && monitor::callback::cat_usage "empty callback"

   if ! monitor::callback::_r_locate "${callback}"
   then
      fail "Callback \"${callback}\" not found"
      return 1
   fi

   exekutor cat "${RVAL}"
}


###
###  MAIN
###
monitor::callback::main()
{
   log_entry "monitor::callback::main" "$@"

   if [ -z "${MULLE_PATH_SH}" ]
   then
      # shellcheck source=../../mulle-bashfunctions/src/mulle-path.sh
      . "${MULLE_BASHFUNCTIONS_LIBEXEC_DIR}/mulle-path.sh" || exit 1
   fi
   if [ -z "${MULLE_FILE_SH}" ]
   then
      # shellcheck source=../../mulle-bashfunctions/src/mulle-file.sh
      . "${MULLE_BASHFUNCTIONS_LIBEXEC_DIR}/mulle-file.sh" || exit 1
   fi

   #
   # handle options
   #
   monitor::callback::_cheap_help_options "monitor::callback::usage"

   local cmd="${1:-list}"
   [ $# -ne 0 ] && shift

   case "${cmd}" in
      add|cat|create|edit|list|locate|remove|run)
         monitor::callback::${cmd} "$@"
      ;;

      *)
         monitor::callback::usage "unknown command \"${cmd}\""
      ;;
   esac
}
