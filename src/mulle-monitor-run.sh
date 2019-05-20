#! /usr/bin/env bash
#
#   Copyright (c) 2016 Nat! - Mulle kybernetiK
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
MULLE_MONITOR_RUN_SH="included"


monitor_run_usage()
{
   [ "$#" -ne 0 ] && log_error "$*"

   cat <<EOF >&2
Usage:
   ${MULLE_USAGE_NAME} run [options]

   Monitor changes in the working directory. Determine which task to call
   with callbacks. The run tasks.

Options:
   -i             : monitor only non-ignored files and folders
   -if <filter>   : specify a filter for ignoring <type>
   -mf <filter>   : specify a filter for matching <type>
EOF
   if [ "${MULLE_FLAG_LOG_VERBOSE}" ]
   then
     cat <<EOF >&2
                    A filter is a comma separated list of type expressions.
                    A type expression is either a type name with wildcard
                    characters or a negated type expression. An expression is
                    negated by being prefixed with !.
                    Example: filter is "header*,!header_private"
EOF
   fi
   cat <<EOF >&2
   -p             : pause monitoring during callback and task
   -s             : run task synchronously
EOF
   exit 1
}


#
# misc handling
#
is_binary_missing()
{
   if which "$1" > /dev/null 2> /dev/null
   then
      return 1
   fi
   return 0
}


check_fswatch()
{
   log_entry "check_fswatch" "$@"

   FSWATCH="${FSWATCH:-fswatch}"

   if ! is_binary_missing "${FSWATCH}"
   then
      return
   fi

   local info

   case "${MULLE_UNAME}" in
      darwin)
         info="brew install fswatch"
      ;;

      linux)
         info="sudo apt-get install inotify-tools"
      ;;

      *)
         info="You have to install
       https://emcrisostomo.github.io/fswatch/
   yourself on this platform"
      ;;
   esac

   fail "To use monitor you have to install the prerequisite \"fswatch\":
${C_BOLD}${C_RESET}   ${info}
${C_INFO}You then need to exit ${MULLE_USAGE_NAME} and reenter it."
}


check_inotifywait()
{
   log_entry "check_inotifywait" "$@"

   # for testing
   INOTIFYWAIT="${INOTIFYWAIT:-inotifywait}"

   if ! is_binary_missing "${INOTIFYWAIT}"
   then
      return
   fi

   local info

   case "${MULLE_UNAME}" in
      linux)
         info="sudo apt-get install inotify-tools"
      ;;

      *)
         info="I have no idea where you can get it from."
      ;;
   esac

   fail "To use monitor you have to install the prerequisite \"inotifywait\":
${C_BOLD}${C_RESET}   ${info}
${C_INFO}You then need to exit ${MULLE_USAGE_NAME} and reenter it."
}


#
# return _action in global variable
#
_action_of_event_command()
{
   log_entry "_action_of_event_command" "$@"

   local cmd="$1"

   case "${cmd}" in
      *CREATE*|*MOVED_TO*|*RENAMED*)
         _action="create"
      ;;

      *DELETE*|*MOVED_FROM*)
         _action="delete"
      ;;

      # PLATFORMSPECIFIC:ISFILE is touch apparently (at least on OS X)
      *CLOSE_WRITE*|PLATFORMSPECIFIC:ISFILE|*UPDATED*|*MODIFY*)
         _action="update"
      ;;

      *)
         log_debug "\"${cmd}\" is boring"
         _action="boring"
         return 1
      ;;
   esac
   return 0
}


#
# process event, return in global variables for speeds sake
#
# _callback
# _action
# _category
# _
_process_event()
{
   log_entry "_process_event" "${1:0:30}..." "${2:0:30}..." "$3" "$4"

   local ignore="$1"
   local match="$2"
   local filepath="$3"
   local cmd="$4"

     # cheap
   if ! _action_of_event_command "${cmd}"
   then
      return 1
   fi

   case "${filepath}" in
      ${MULLE_MONITOR_PROJECT_DIR}/.mulle/var*)
         return 1
      ;;
   esac

   local _patternfile
   #
   # not as cheap. If mulle-match is our script stuff, it's too expensive
   # to fork this everytime. We use it as a library.
   #
   case "${MULLE_MATCH}" in
      ""|*/mulle-match)

         if ! [ -z "${MULLE_MATCH_MATCH_SH}" ]
         then
            . "${MULLE_MATCH_LIBEXEC_DIR}/mulle-match-match.sh" || exit 1
         fi

         # returns 0,1,2
         r_match_filepath "${ignore}" "${match}" "${filepath}"
         case $?  in
            1)
               return 1
            ;;

            2)
               _callback="default"
               _category="all"
               return 0
            ;;
         esac
         _patternfile="${RVAL}"
      ;;

      *)
         if ! _patternfile="`"${MULLE_MATCH:-mulle-match}" \
                --ignore-filter "${OPTION_IGNORE_FILTER}" \
                --match-filter "${OPTION_MATCH_FILTER}" \
                "${filepath}" `"
         then
            return 1
         fi
      ;;
   esac

   _callback="${_patternfile%%--*}"
   _callback="${_callback#*-}"
   _category="${_patternfile##*--}"

   [ -z "${_callback}" ] && internal_fail "_callback is empty"

   return 0
}


run_tasks_synchronously()
{
   log_entry 'run_tasks_synchronously' "$@"

   local tasks="$1"

   local rval
   local task

   rval=0

   set -f
   for task in ${tasks}
   do
      set +f
      log_verbose "Task ${C_MAGENTA}${C_BOLD}${task}"

      eval run_task_main "${task}"
      rval=$?

      if [ "${rval}" -ne 0 ]
      then
         break
      fi
   done
   set +f

   return $rval
}


__async_task_run()
{
   log_entry "__async_task_run" "$@"

   run_tasks_synchronously "$@"
}


callback_and_task()
{
   log_entry "callback_and_task" "$@"

   local callback="$1"
   local action="$2"
   local filepath="$3"
   local category="$4"

   local tasks
   local rval

   tasks="`run_callback_main "${callback}" \
                             "${action}" \
                             "${filepath}" \
                             "${category}"`"
   rval=$?

   if [ $rval -ne 0 -o -z "${tasks}" ]
   then
      return $rval
   fi

   if [ "${tasks}" = "echo" ]
   then
      rexekutor echo "${filepath}"
      return
   fi

   # don't wrap for echo
   if [ "${OPTION_SYNCHRONOUS}" = 'YES' ]
   then
      r_add_line "${MULLE_MONITOR_PRELUDE_TASK}" "${tasks}"
      r_add_line "${RVAL}" "${MULLE_MONITOR_CODA_TASK}"
      tasks="${RVAL}"
      run_tasks_synchronously "${tasks}"
      return $?
   fi

   eval add_task_job "__async" "${tasks}"
}


_watch_using_fswatch()
{
   log_entry "_watch_using_fswatch" "$@"

   local ignore="$1" ; shift
   local match="$1" ; shift

   local cmd
   local workingdir
   local escaped_workingdir
   workingdir="`pwd -P`"

   r_escaped_sed_pattern "${workingdir}/"
   escaped_workingdir="${RVAL}"

   while IFS=$'\n' read -r line
   do
      #
      # extract filepath from line and
      # make it a relative filepath
      #
      _filepath="`LC_ALL=C sed -e 's/^\(.*\) \(.*\)$/\1/' \
                               -e "s/^${escaped_workingdir}//" <<< "${line}" `"

      [ -z "${_filepath}" ] && internal_fail "failed to parse \"${line}\""

      cmd="`echo "${line}" | LC_ALL=C sed 's/^\(.*\) \(.*\)$/\2/' | tr '[a-z]' '[A-Z]'`"

      if _process_event "${ignore}" "${match}" "${_filepath}" "${cmd}"
      then
         if [ "${OPTION_PAUSE}" = 'YES' ]
         then
            return 0
         else
            callback_and_task "${_callback}" "${_action}" "${_filepath}" "${_category}"
         fi
      fi
   done < <( eval_exekutor "'${FSWATCH}'" -r -x --event-flag-separator : "$@" )  # bashism

   return 1
}


watch_using_fswatch()
{
   log_entry "watch_using_fswatch" "$@"

   local task
   local _action
   local _category
   local _callback
   local _filepath

   while _watch_using_fswatch "$@"
   do
      callback_and_task "${_callback}" "${_action}" "${_filepath}" "${_category}"
   done
}


_watch_using_inotifywait()
{
   log_entry "_watch_using_inotifywait" "$@"

   local ignore="$1"; shift
   local match="$1"; shift

   # see watch_using_fswatch comment
   local directory
   local filename
   local cmd
   local _line
   local _field

   #
   # https://unix.stackexchange.com/questions/166546/bash-cannot-break-out-of-piped-while-read-loop-process-substitution-works
   #
   while IFS=$'\n' read -r _line # directory cmd filename
   do
      log_debug "${_line}"

      case "${_line}" in
         \"*)
            directory="${_line%%\",*}"  # not perfect but ..
            directory="${directory:1}"
            _line="${_line#*\",}"
         ;;

         *)
            directory="${_line%%,*}"
            _line="${_line#*,}"
         ;;
      esac

      case "${_line}" in
         \"*)
            cmd="${_line%%\",*}"
            cmd="${cmd:1}"
            _line="${_line#*\",}"
         ;;

         *)
            cmd="${_line%%,*}"
            _line="${_line#*,}"
         ;;
      esac

      # remove quotes
      filename="${_line}"
      case "${filename}" in
         \"*\")
            filename="${filename:1}"
            filename="${filename%?}"
         ;;
      esac

      _filepath="` filepath_concat "${directory}" "${filename}" `"

      if _process_event "${ignore}" "${match}" "${_filepath}" "${cmd}"
      then
         if [ "${OPTION_PAUSE}" = 'YES' ]
         then
            return 0
         else
            callback_and_task "${_callback}" "${_action}" "${_filepath}" "${_category}"
         fi
      fi
   done < <( eval_exekutor "'${INOTIFYWAIT}'" -q -r -m -c "$@" )  # bashism

   return 1
}


watch_using_inotifywait()
{
   log_entry "watch_using_inotifywait" "$@"

   local task
   local _action
   local _category
   local _callback
   local _filepath

   while _watch_using_inotifywait "$@"
   do
      # only if OPTION_PAUSE=YES
      callback_and_task "${_callback}" "${_action}" "${_filepath}" "${_category}"
   done
}


cleanup_monitor()
{
   log_entry "cleanup_monitor" "$@"

   local killnowait="$1"

   if [ "${killnowait}" = 'YES' ]
   then
      log_fluff "==> Kill jobs"
      local job

      for job in `jobs -pr`
      do
         kill $job
      done
   else
      log_fluff "==> Wait for jobs"

      wait
   fi

   remove_file_if_present "${MONITOR_PIDFILE}"

   log_fluff "==> Exit"
}


kill_monitor()
{
   log_entry "kill_monitor" "$@"

   cleanup_monitor 'YES'
   exit 1
}


prevent_superflous_monitor()
{
   log_entry "prevent_superflous_monitor" "$@"

   if check_pid "${MONITOR_PIDFILE}"
   then
      fail "Another monitor seems to be already running here
${C_INFO}If this is not the case:
${C_RESET_BOLD}   rm \"${MONITOR_PIDFILE#${MULLE_USER_PWD}/}\""
   fi

   #
   # unconditionally remove this
   #
   if [ "${RUN_TESTS}" = 'YES' ]
   then
      rm "${TEST_JOB_PIDFILE}" 2> /dev/null
   fi

   trap kill_monitor 2 3
   announce_pid $$ "${MONITOR_PIDFILE}"
}


# merely exists for -ld tracing
change_working_directory()
{
   log_entry "change_working_directory" "$@"

   exekutor cd "$1" || fail "could not cd to \"$1\""
}


###
###  MAIN
###
monitor_run_main()
{
   log_entry "monitor_run_main" "$@"

   local OPTION_IGNORE_FILTER
   local OPTION_MATCH_FILTER
   local OPTION_MONITOR_WITH_IGNORE_D='NO'
   local OPTION_PAUSE='NO'
   local OPTION_SYNCHRONOUS='YES'

   local OPTION_DIR

   OPTION_DIR="${PWD}"

   #
   # handle options
   #
   while :
   do
      case "$1" in
         -h*|--help|help)
            monitor_run_usage
         ;;

         -a|--all)
            OPTION_MONITOR_WITH_IGNORE_D='NO'
         ;;

         -d)
            [ $# -eq 1 ] && monitor_run_usage "missing argument to $1"
            shift

            OPTION_DIR="$1"
         ;;

         -i|--ignore)
            OPTION_MONITOR_WITH_IGNORE_D='YES'
         ;;

         -if|--ignore-filter)
            [ $# -eq 1 ] && monitor_run_usage "missing argument to $1"
            shift

            OPTION_IGNORE_FILTER="$1"
         ;;

         -mf|--match-filter)
            [ $# -eq 1 ] && monitor_run_usage "missing argument to $1"
            shift

            OPTION_MATCH_FILTER="$1"
         ;;

         --craft)
            MULLE_MONITOR_CODA_TASK="craft"
         ;;

         --prelude-task)
            [ $# -eq 1 ] && monitor_run_usage "missing argument to $1"
            shift

            MULLE_MONITOR_PRELUDE_TASK="$1"
         ;;

         --coda-task)
            [ $# -eq 1 ] && monitor_run_usage "missing argument to $1"
            shift

            MULLE_MONITOR_CODA_TASK="$1"
         ;;

         -p|--pause)
            OPTION_PAUSE='YES'
         ;;

         --no-pause)
            OPTION_PAUSE='NO'
         ;;

         -s|--synchronous)
            OPTION_SYNCHRONOUS='YES'
         ;;

         --asynchronous)
            OPTION_SYNCHRONOUS='NO'
         ;;

         -*)
            monitor_run_usage "Unknown option \"$1\""
         ;;

         *)
            break
         ;;
      esac

      shift
   done

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

   if [ -z "${MULLE_MONITOR_PROCESS_SH}" ]
   then
      # shellcheck source=src/mulle-monitor-process.sh
      . "${MULLE_MONITOR_LIBEXEC_DIR}/mulle-monitor-process.sh" || exit 1
   fi
   if [ -z "${MULLE_MONITOR_CALLBACK_SH}" ]
   then
      # shellcheck source=src/mulle-monitor-callback.sh
      . "${MULLE_MONITOR_LIBEXEC_DIR}/mulle-monitor-callback.sh" || exit 1
   fi
   if [ -z "${MULLE_MONITOR_TASK_SH}" ]
   then
      # shellcheck source=src/mulle-monitor-task.sh
      . "${MULLE_MONITOR_LIBEXEC_DIR}/mulle-monitor-task.sh" || exit 1
   fi

   if [ -z "${MULLE_HOSTNAME}" ]
   then
      MULLE_HOSTNAME="`hostname -s`"
   fi

   mkdir_if_missing "${MULLE_MONITOR_VAR_DIR}"
   MONITOR_PIDFILE="${MULLE_MONITOR_VAR_DIR}/run/monitor-pid"

   change_working_directory "${OPTION_DIR}"

   export MULLE_MONITOR_LIBEXEC_DIR
   export MULLE_BASHFUNCTIONS_LIBEXEC_DIR
   export MULLE_MONITOR_DIR
   export MULLE_MONITOR_ETC_DIR
   export MULLE_MONITOR_MATCH_DIR
   export MULLE_MONITOR_IGNORE_DIR

   case "${MULLE_UNAME}" in
      linux)
         check_inotifywait
      ;;

      *)
         check_fswatch
      ;;
   esac

   prevent_superflous_monitor

   if [ "${OPTION_SYNCHRONOUS}" = 'NO' ]
   then
      [ -z "${MULLE_MONITOR_PRELUDE_TASK}" ] && fail "--prelude-task requires --serial"
      [ -z "${MULLE_MONITOR_PRELUDE_TASK}" ] && fail "--coda-task requires --serial"
   fi

   if [ ! -d "${MULLE_MONITOR_ETC_DIR}" -a ! -d "${MULLE_MONITOR_SHARE_DIR}" ]
   then
      MULLE_MONITOR_DEFAULT_CALLBACK="echo echo"
   fi

   log_verbose "==> Start monitoring"
   log_fluff "Edits in your directory \"${OPTION_DIR#${MULLE_USER_PWD}/}\" are now monitored."

   log_info "Monitor is running. [CTRL]-[C] to quit"

   if [ -z "${MULLE_MATCH_MATCH_SH}" ]
   then
      MULLE_MATCH_LIBEXEC_DIR="`"${MULLE_MATCH:-mulle-match}" libexec-dir`" || exit 1

      . "${MULLE_MATCH_LIBEXEC_DIR}/mulle-match-environment.sh" || exit 1

      match_environment "${MULLE_MONITOR_PROJECT_DIR}"

      . "${MULLE_MATCH_LIBEXEC_DIR}/mulle-match-match.sh" || exit 1
   fi

   local _cache
   local ignore
   local match

   _define_patternfilefunctions "${MULLE_MATCH_SKIP_DIR}"  \
                                "${MULLE_MONITOR_VAR_DIR}/cache/ignore"
   ignore="${_cache}"

   _define_patternfilefunctions "${MULLE_MATCH_USE_DIR}" \
                                "${MULLE_MONITOR_VAR_DIR}/cache/match"
   match="${_cache}"

   #
   # Only monitor **existing** top level folders. WHY ?
   # Because when you have the build folder in the project directory
   # the amount of file change events is not really nice
   #
   local quoted_toplevel

   if [ "${OPTION_MONITOR_WITH_IGNORE_D}" = 'YES' ]
   then
      quoted_toplevel="`_find_toplevel_files "${ignore}"`"
      if [ -z "${quoted_toplevel}" ]
      then
         fail "\"ignore.d\" leaves nothing to be monitored"
      fi
   else
      quoted_toplevel="'.'"
   fi

   log_verbose "Monitoring: ${quoted_toplevel}"

   case "${MULLE_UNAME}" in
      linux)
         watch_using_inotifywait "${ignore}" "${match}" "${quoted_toplevel}"
      ;;

      *)
         watch_using_fswatch "${ignore}" "${match}" "${quoted_toplevel}"
      ;;
   esac

   cleanup_monitor
}
