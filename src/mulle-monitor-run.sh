# shellcheck shell=bash
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
MULLE_MONITOR_RUN_SH='included'


monitor::run::usage()
{
   [ "$#" -ne 0 ] && log_error "$*"

   cat <<EOF >&2
Usage:
   ${MULLE_USAGE_NAME} run [options]

   Monitor changes in the working directory. Determine which task to call
   with callbacks. The run tasks.

Options:
   -i             : monitor only non-ignored files and folders
   -q <filter>    : specify a qualifier for matching <type> or <category>

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
monitor::run::is_binary_missing()
{
   if which "$1" > /dev/null 2> /dev/null
   then
      return 1
   fi
   return 0
}


monitor::run::check_fswatch()
{
   log_entry "monitor::run::check_fswatch" "$@"

   FSWATCH="${FSWATCH:-fswatch}"

   if ! monitor::run::is_binary_missing "${FSWATCH}"
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

   fail "To use \"${MULLE_USAGE_NAME} run\" you have to install the prerequisite \"fswatch\":
${C_BOLD}${C_RESET}   ${info}
${C_INFO}You then need to exit ${MULLE_USAGE_NAME} and reenter it."
}


monitor::run::check_inotifywait()
{
   log_entry "monitor::run::check_inotifywait" "$@"

   # for testing
   INOTIFYWAIT="${INOTIFYWAIT:-inotifywait}"

   if ! monitor::run::is_binary_missing "${INOTIFYWAIT}"
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

   fail "To use \"${MULLE_USAGE_NAME} run\" you have to install the prerequisite \"inotifywait\":
${C_BOLD}${C_RESET}   ${info}
${C_INFO}You then need to exit ${MULLE_USAGE_NAME} and reenter it."
}


#
# return _action in global variable
#
monitor::run::__action_of_event_command()
{
   log_entry "monitor::run::__action_of_event_command" "$@"

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
# local _action
# local _callback
# local _category
#
monitor::run::__process_event()
{
   log_entry "monitor::run::__process_event" "${1:0:30}..." "${2:0:30}..." "$3" "$4"

   local ignore="$1"
   local match="$2"
   local filepath="$3"
   local cmd="$4"

     # cheap
   if ! monitor::run::__action_of_event_command "${cmd}"
   then
      return 1
   fi

   case "${filepath}" in
      ${MULLE_MONITOR_PROJECT_DIR}/.mulle/var*)
         return 1
      ;;
   esac

   local patternfile

   #
   # not as cheap. If mulle-match is our script stuff, it's too expensive
   # to fork this everytime. We use it as a library.
   #
   case "${MULLE_MATCH}" in
      ""|*/mulle-match)

         include "match::filename"

         # returns 0,1,4
         # 0: match
         # 1: no match
         # 4: match was empty

         match::filename::r_match_filepath "${ignore}" "${match}" "${filepath}"
         case $? in
            1)
               return 1
            ;;

            4)
               _callback="filesystem"
               _category="all"
               return 0
            ;;
         esac
         patternfile="${RVAL}"
      ;;

      *)
         if ! patternfile="`"${MULLE_MATCH:-mulle-match}" \
                --qualifier "${OPTION_MATCH_QUALIFIER}" \
                "${filepath}" `"
         then
            return 1
         fi
      ;;
   esac

   _callback="${patternfile%%--*}"
   _callback="${_callback#*-}"
   _category="${patternfile##*--}"

   [ -z "${_callback}" ] && _internal_fail "_callback is empty"

   return 0
}



monitor::run::run_tasks_synchronously()
{
   log_entry 'monitor::run::run_tasks_synchronously' "$@"

   local tasks="$1"

   local rval
   local task

   rval=0

   .for task in ${tasks}
   .do
      log_verbose "Task ${C_MAGENTA}${C_BOLD}${task}"

      monitor::task::run "'${task}'"
      rval=$?

      if [ "${rval}" -ne 0 ]
      then
         .break
      fi
   .done

   return $rval
}

monitor::run::run_tasks_async()
{
   log_entry 'monitor::run::run_tasks_async' "$@"

   local tasks="$1"

   local task

   .for task in ${tasks}
   .do
      log_verbose "Task ${C_MAGENTA}${C_BOLD}${task}"

      monitor::task::run_job "${task}" &
   .done
}


monitor::run::callback_and_task()
{
   log_entry "monitor::run::callback_and_task" "$@"

   local callback="$1"
   local action="$2"
   local filepath="$3"
   local category="$4"

   local tasks
   local rval

   tasks="`monitor::callback::run "${callback}" \
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
      rexekutor printf "%s\n" "${filepath}"
      return
   fi

   # don't wrap for echo
   if [ "${OPTION_SYNCHRONOUS}" = 'YES' ]
   then
      r_add_line "${MULLE_MONITOR_PRELUDE_TASK}" "${tasks}"
      r_add_line "${RVAL}" "${MULLE_MONITOR_CODA_TASK}"
      tasks="${RVAL}"
      monitor::run::run_tasks_synchronously "${tasks}"
      return $?
   fi

   monitor::run::run_tasks_async "${tasks}"
}


monitor::run::__watch_using_fswatch()
{
   log_entry "monitor::run::__watch_using_fswatch" "$@"

   local ignore="$1"
   local match="$2"

   shift 2

   local cmd
   local line
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
      _filepath="${line%\ *}"
      _filepath="${_filepath#"${workingdir}/"}"

      [ -z "${_filepath}" ] && _internal_fail "failed to parse \"${line}\""

      r_uppercase "${line##\* }"
      cmd="${RVAL}"

      if monitor::run::__process_event "${ignore}" "${match}" "${_filepath}" "${cmd}"
      then
         if [ "${OPTION_PAUSE}" = 'YES' ]
         then
            return 0
         else
            monitor::run::callback_and_task "${_callback}" "${_action}" "${_filepath}" "${_category}"
         fi
      fi
   done < <( eval_exekutor "'${FSWATCH}'" -r -x --event-flag-separator : "$@" )  # bashism

   return 1
}


monitor::run::watch_using_fswatch()
{
   log_entry "monitor::run::watch_using_fswatch" "$@"

   local _action
   local _category
   local _callback
   local _filepath

   while monitor::run::__watch_using_fswatch "$@"
   do
      monitor::run::callback_and_task "${_callback}" "${_action}" "${_filepath}" "${_category}"
   done
}


# local _action
# local _callback
# local _category
# local _filepath
monitor::run::__watch_using_inotifywait()
{
   log_entry "monitor::run::__watch_using_inotifywait" "$@"

   local ignore="$1"
   local match="$2"

   shift 2

   # see monitor::run::watch_using_fswatch comment
   local directory
   local filename
   local filepath
   local cmd
   local line

   #
   # https://unix.stackexchange.com/questions/166546/bash-cannot-break-out-of-piped-while-read-loop-process-substitution-works
   #
   while IFS=$'\n' read -r line # directory cmd filename
   do
      log_debug "${line}"

      case "${line}" in
         \"*)
            directory="${line%%\",*}"  # not perfect but ..
            directory="${directory:1}"
            line="${line#*\",}"
         ;;

         *)
            directory="${line%%,*}"
            line="${line#*,}"
         ;;
      esac

      case "${line}" in
         \"*)
            cmd="${line%%\",*}"
            cmd="${cmd:1}"
            line="${line#*\",}"
         ;;

         *)
            cmd="${line%%,*}"
            line="${line#*,}"
         ;;
      esac

      # remove quotes
      filename="${line}"
      case "${filename}" in
         \"*\")
            filename="${filename:1}"
            filename="${filename%?}"
         ;;
      esac

      r_filepath_concat "${directory}" "${filename}"
      _filepath="${RVAL}"

      if monitor::run::__process_event "${ignore}" "${match}" "${_filepath}" "${cmd}"
      then
         if [ "${OPTION_PAUSE}" = 'YES' ]
         then
            return 0
         else
            monitor::run::callback_and_task "${_callback}" "${_action}" "${_filepath}" "${_category}"
         fi
      fi
   done < <( eval_exekutor "'${INOTIFYWAIT}'" -q -r -m -c "$@" )  # bashism

   return 1
}


monitor::run::watch_using_inotifywait()
{
   log_entry "monitor::run::watch_using_inotifywait" "$@"

   local _action
   local _category
   local _callback
   local _filepath

   while monitor::run::__watch_using_inotifywait "$@"
   do
      # only if OPTION_PAUSE=YES
      monitor::run::callback_and_task "${_callback}" "${_action}" "${_filepath}" "${_category}"
   done
}


monitor::run::cleanup_monitor()
{
   log_entry "monitor::run::cleanup_monitor" "$@"

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


monitor::run::kill_monitor()
{
   log_entry "monitor::run::kill_monitor" "$@"

   monitor::run::cleanup_monitor 'YES'
   exit 1
}


monitor::run::prevent_superfluous_monitor()
{
   log_entry "monitor::run::prevent_superfluous_monitor" "$@"

   if monitor::process::check_pid "${MONITOR_PIDFILE}"
   then
      fail "Another monitor seems to be already running here
${C_INFO}If this is not the case:
${C_RESET_BOLD}   rm \"${MONITOR_PIDFILE#"${MULLE_USER_PWD}/"}\""
   fi

   #
   # unconditionally remove this
   #
   if [ "${RUN_TESTS}" = 'YES' ]
   then
      rm "${TEST_JOB_PIDFILE}" 2> /dev/null
   fi

   trap monitor::run::kill_monitor 2 3
   monitor::process::announce_pid $$ "${MONITOR_PIDFILE}"
}


# merely exists for -ld tracing
monitor::run::change_working_directory()
{
   log_entry "monitor::run::change_working_directory" "$@"

   exekutor cd "$1" || fail "could not cd to \"$1\""
}


###
###  MAIN
###
monitor::run::main()
{
   log_entry "monitor::run::main" "$@"

   local OPTION_MATCH_QUALIFIER
   local OPTION_MONITOR_WITH_IGNORE_D='NO'
   local OPTION_PAUSE='NO'
   local OPTION_SYNCHRONOUS='NO'

   local OPTION_DIR

   OPTION_DIR="${PWD}"

   #
   # handle options
   #
   while :
   do
      case "$1" in
         -h*|--help|help)
            monitor::run::usage
         ;;

         -a|--all)
            OPTION_MONITOR_WITH_IGNORE_D='NO'
         ;;

         -d)
            [ $# -eq 1 ] && monitor::run::usage "missing argument to $1"
            shift

            OPTION_DIR="$1"
         ;;

         -i|--ignore)
            OPTION_MONITOR_WITH_IGNORE_D='YES'
         ;;

         -q|--qualifier)
            [ $# -eq 1 ] && monitor::run::usage "missing argument to $1"
            shift

            OPTION_MATCH_QUALIFIER="$1"
         ;;

         --craft)
            MULLE_MONITOR_CODA_TASK="craft"
         ;;

         --prelude-task)
            [ $# -eq 1 ] && monitor::run::usage "missing argument to $1"
            shift

            MULLE_MONITOR_PRELUDE_TASK="$1"
         ;;

         --coda-task)
            [ $# -eq 1 ] && monitor::run::usage "missing argument to $1"
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
            monitor::run::usage "Unknown option \"$1\""
         ;;

         *)
            break
         ;;
      esac

      shift
   done

   include "path"
   include "file"
   include "monitor::process"
   include "monitor::callback"
   include "monitor::task"

   MULLE_HOSTNAME="${MULLE_HOSTNAME:-`hostname`}" # -s not available on solaris

   mkdir_if_missing "${MULLE_MONITOR_VAR_DIR}"
   MONITOR_PIDFILE="${MULLE_MONITOR_VAR_DIR}/run/monitor-pid"

   monitor::run::change_working_directory "${OPTION_DIR}"

   export MULLE_MONITOR_LIBEXEC_DIR
   export MULLE_BASHFUNCTIONS_LIBEXEC_DIR
   export MULLE_MONITOR_DIR
   export MULLE_MONITOR_ETC_DIR
   export MULLE_MONITOR_MATCH_DIR
   export MULLE_MONITOR_IGNORE_DIR

   case "${MULLE_UNAME}" in
      linux)
         monitor::run::check_inotifywait
      ;;

      *)
         monitor::run::check_fswatch
      ;;
   esac

   monitor::run::prevent_superfluous_monitor

   if [ "${OPTION_SYNCHRONOUS}" = 'NO' ]
   then
      [ -z "${MULLE_MONITOR_PRELUDE_TASK}" ] || fail "--prelude-task requires --serial"
      [ -z "${MULLE_MONITOR_CODA_TASK}" ]    || fail "--coda-task requires --serial"
   fi

   if [ ! -d "${MULLE_MONITOR_ETC_DIR}" -a ! -d "${MULLE_MONITOR_SHARE_DIR}" ]
   then
      MULLE_MONITOR_DEFAULT_CALLBACK="echo filesystem"
   fi

   log_verbose "==> Start monitoring"
   log_fluff "Edits in your directory \"${OPTION_DIR#"${MULLE_USER_PWD}/"}\" are now monitored."

   log_info "Monitor is running. [CTRL]-[C] to quit"

   if [ -z "${MULLE_MATCH_FILENAME_SH}" ]
   then
      include "match::environment"

      match::environment::init "${MULLE_MONITOR_PROJECT_DIR}"

      include "match::filename"
   fi

   local ignore

   match::filename::r_define_patternfilefunctions "${MULLE_MATCH_SKIP_DIR}"  \
                                                  "${MULLE_MONITOR_VAR_DIR}/cache/ignore"
   ignore="${RVAL}"

   local match

   match::filename::r_define_patternfilefunctions "${MULLE_MATCH_USE_DIR}" \
                                                  "${MULLE_MONITOR_VAR_DIR}/cache/match"
   match="${RVAL}"

   local pathitem
   local directories

   .foreachpath pathitem in ${MULLE_MATCH_PATH:-.}
   .do
      r_escaped_singlequotes "${pathitem}"
      r_concat "${directories}" "'${RVAL}'"
      directories="${RVAL}"
   .done

   log_verbose "Monitoring: ${directories}"

   case "${MULLE_UNAME}" in
      linux)
         eval monitor::run::watch_using_inotifywait "'${ignore}'" "'${match}'" "${directories}"
      ;;

      *)
         eval monitor::run::watch_using_fswatch "'${ignore}'" "'${match}'" "${directories}"
      ;;
   esac

   monitor::run::cleanup_monitor
}
