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
MULLE_MONITOR_TASK_SH="included"


monitor_task_usage()
{
   if [ "$#" -ne 0 ]
   then
      log_error "$*"
   fi

   cat <<EOF >&2
Usage:
   ${MULLE_USAGE_NAME} task <command>

   Manage tasks. A task is a plugin that is loaded by the monitor and executed
   on behalf of a callback. A callback may print a taskname to stdout. This is
   then used by the monitor to run the task.

Commands:
   cat        : print the task script to stdout
   add        : install a bash script as a task
   kill       : kill a running task
   list       : list installed tasks
   ps         : list running tasks
   remove     : remove a task
   test       : load task and check that the required main function is present
   run        : run task
   status     : get status of running or last ran task
EOF
   exit 1
}


add_task_usage()
{
   if [ "$#" -ne 0 ]
   then
      log_error "$*"
   fi

   cat <<EOF >&2
Usage:
   ${MULLE_USAGE_NAME} task add <task> <script>

   Install a sourceable bash script as a mulle-sde task. You may specify '-' as
   to read it from stdin.
EOF
   exit 1
}


remove_task_usage()
{
   if [ "$#" -ne 0 ]
   then
      log_error "$*"
   fi

   cat <<EOF >&2
Usage:
   ${MULLE_USAGE_NAME} task remove <task>

   Remove a task.
EOF
   exit 1
}


list_task_usage()
{
   if [ "$#" -ne 0 ]
   then
      log_error "$*"
   fi

   cat <<EOF >&2
Usage:
   ${MULLE_USAGE_NAME} task list

   List installed tasks.
EOF
   exit 1
}


test_task_usage()
{
   if [ "$#" -ne 0 ]
   then
      log_error "$*"
   fi

   cat <<EOF >&2
Usage:
   ${MULLE_USAGE_NAME} task test <task>

   Load a task and check that the task provides an entry function called
   <task>_task_run.
EOF
   exit 1
}


ps_task_usage()
{
   if [ "$#" -ne 0 ]
   then
      log_error "$*"
   fi

   cat <<EOF >&2
Usage:
   ${MULLE_USAGE_NAME} task ps

   List running tasks and their pids.
EOF
   exit 1
}


kill_task_usage()
{
   if [ "$#" -ne 0 ]
   then
      log_error "$*"
   fi

   cat <<EOF >&2
Usage:
   ${MULLE_USAGE_NAME} task kill <task>

   Kill a running task.
EOF
   exit 1
}


status_task_usage()
{
   if [ "$#" -ne 0 ]
   then
      log_error "$*"
   fi

   cat <<EOF >&2
Usage:
   ${MULLE_USAGE_NAME} task status <task>

   Check status of a task. These are the returned values:

   done    : task successfully
   failed  : task completed with errors
   running : still running
   unknown : possibly never ran yet

EOF
   exit 1
}


run_task_usage()
{
   if [ "$#" -ne 0 ]
   then
      log_error "$*"
   fi

   cat <<EOF >&2
Usage:
   ${MULLE_USAGE_NAME} task run <task> ...

   Run a task. Depending on the task, you may be able to pass additional
   arguments to the task.
EOF
   exit 1
}


cat_task_usage()
{
   if [ "$#" -ne 0 ]
   then
      log_error "$*"
   fi

   cat <<EOF >&2
Usage:
   ${MULLE_USAGE_NAME} task cat <task>

   Print the task script to stdout.

EOF
   exit 1
}


#
#
#
_cheap_help_options()
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


r_task_donefile()
{
   log_entry "r_task_donefile" "$@"

   local task="$1"

   RVAL="${MULLE_MONITOR_DIR}/var/${MULLE_HOSTNAME}/run/monitor/${task}-task"
}


r_task_pidfile()
{
   log_entry "r_task_pidfile" "$@"

   local task="$1"

   RVAL="${MULLE_MONITOR_DIR}/var/${MULLE_HOSTNAME}/run/monitor/${task}-task.pid"
}


r_task_get_entry_functionname()
{
   log_entry "r_task_get_entry_functionname" "$@"

   local task="$1"

   [ -z "${task}" ] && internal_fail "empty task"

   local taskidentifier

   taskidentifier="`tr -c '[a-zA-Z0-9_\n]' '_' <<< "${task}"`"
   RVAL="${taskidentifier}_task_run"

   log_debug "task functionname: \"${RVAL}\""
}


r_task_plugin_install_filename()
{
   log_entry "r_task_plugin_install_filename" "$@"

   local task="$1"

   local name

   name="`tr -c '[a-zA-Z0-9-\n]' '_' <<< "${task}"`"
   if [ "${name}" != "${task}" ]
   then
      fail "\"${task}\" must be a-zA-Z0-9-"
   fi

   [ -z "${MULLE_MONITOR_DIR}" ] && internal_fail "MULLE_MONITOR_DIR not set"

   RVAL="${MULLE_MONITOR_DIR}/libexec/${task}-task.sh"
}


# sets _plugin
r_task_plugin_filename()
{
   log_entry "r_task_plugin_filename" "$@"

   local task="$1"

   [ -z "${MULLE_MONITOR_DIR}" ] && internal_fail "MULLE_MONITOR_DIR not set"

   RVAL="${MULLE_MONITOR_DIR}/share/libexec/${task}-task.sh"
   if [ ! -f "${_plugin}" ]
   then
      RVAL="${MULLE_MONITOR_DIR}/libexec/${task}-task.sh"
   fi
}


# returns plugin filename
r_locate_task()
{
   log_entry "r_locate_task" "$@"

   local task="$1"

   r_task_plugin_filename "${task}"

   if [ ! -f "${RVAL}" ]
   then
      log_error "There is no installed task \"${task}\"."
      return 1
   fi
}


_load_task()
{
   log_entry "_load_task" "$@"

   local task="$1"

   local RVAL

   if ! r_locate_task "${task}"
   then
      exit 1
   fi

   . "${RVAL}" || exit 1
}


__require_filename()
{
   log_entry "__require_filename" "$@"

   local task="$1"
   local filename="$2"

   local functionname
   local RVAL

   r_task_get_entry_functionname "${task}"
   functionname="${RVAL}"

   unset -f "${functionname}"

   . "${filename}" 2> /dev/null || fail "\"${filename}\" is not a valid bash script"

   if [ "`type -t "${functionname}"`" != "function" ]
   then
      fail "\"${filename}\" does not define function \"${functionname}\""
   fi
}


r_require_task()
{
   log_entry "r_require_task" "$@"

   local task="$1"

   local functionname

   r_task_get_entry_functionname "${task}"
   functionname="${RVAL}"

   if [ "`type -t "${functionname}"`" != "function" ]
   then
      _load_task "${task}"
   fi

   if [ "${MULLE_FLAG_LOG_VERBOSE}" = "YES" ]
   then
      if [ "`type -t "${functionname}"`" != "function" ]
      then
         fail "\"${task}\" does not define function \"${functionname}\""
      fi
   fi

   RVAL="${functionname}"
}


remove_task_job()
{
   log_entry "remove_task_job" "$@"

   local task="$1"

   local RVAL

   r_task_pidfile "${task}"
   kill_pid "${RVAL}"
}


remember_task_rval()
{
   log_entry "remember_task_rval" "$@"

   local task="$1"
   local rval="$2"

   local taskdonefile
   local status
   local RVAL

   status="failed"
   case "${rval}" in
      0)
         status="done"
      ;;

      "")
         internal_fail "rval is empty"
      ;;
   esac

   r_task_donefile "${task}"
   taskdonefile="${RVAL}"
   r_fast_dirname "${taskdonefile}"
   mkdir_if_missing "${RVAL}"
   redirect_exekutor "${taskdonefile}" echo "${status}"
}


add_task_job()
{
   log_entry "add_task_job" "$@"

   local task="$1" ; shift
   local sleepexe="$1"; shift
   local taskdelay="$1" ; shift

   # rest commandline

   local taskpidfile
   local RVAL

   r_task_pidfile "${task}"
   taskpidfile="${RVAL}"
   kill_pid "${taskpidfile}"

   local timestamp

   timestamp="`date +"%s"`"
   timestamp="`expr $timestamp + ${taskdelay%.*}`"
   timestamp="`expr $timestamp + 1`"  # close to that date...

   case "${MULLE_UNAME}" in
      darwin)
         log_fluff "==> Scheduled task \"${task}\" for" `exekutor date -r ${timestamp} "+%H:%M:%S"`
      ;;

      *)
         log_fluff "==> Scheduled task \"${task}\" for" `exekutor date --date=@${timestamp} "+%H:%M:%S"`
      ;;
   esac

   (
      trap 'log_fluff "Task \"${task}\" with pid ${BASHPID} killed" ; exit 1' TERM

      announce_current_pid "${taskpidfile}"
      exekutor "${sleepexe}" "${taskdelay}"

      log_fluff "==> Starting task"

      local rval

      PATH="${MULLE_MONITOR_DIR}/bin:${MULLE_MONITOR_DIR}/share/bin:${PATH}" \
         eval_exekutor "$@"
      rval=$?

      remember_task_rval "${task}" "${rval}"

      log_fluff "==> Ended task ($rval)"

      done_pid "${taskpidfile}"
   ) &
}


run_task_job()
{
   log_entry "run_task_job" "$@"

   local task="$1"; shift

   local functionname
   local RVAL

   r_require_task "${task}" || exit 1
   functionname="${RVAL}"
   #
   # check that a task of same name is not running/schedulded. If yes
   # prempt it.
   #
   # Delay task schedule by 1 second, so that we can "coalesce"
   # incoming events
   #
   case "${MULLE_UNAME}" in
      linux|darwin)
         add_task_job "${task}" sleep "0.3s" "'${functionname}'" "$@"
      ;;

      *)
         add_task_job "${task}" sleep "1" "'${functionname}'" "$@"
      ;;
   esac
}


run_task_main()
{
   log_entry "run_task_main" "$@"

   local task="$1"

   [ -z "${task}" ] && cat_task_usage "Empty task"

   shift

   local taskidentifier

   taskidentifier="`tr -c '[a-zA-Z0-9_\n]' '_' <<< "${task}"`"

   local functionname
   local RVAL

   r_require_task "${task}" || exit 1
   functionname="${RVAL}"

   local taskpidfile

   r_task_pidfile "${task}"
   taskpidfile="${RVAL}"
   kill_pid "${taskpidfile}"

   local rval

   announce_current_pid "${taskpidfile}"
   PATH="${MULLE_MONITOR_DIR}/bin:${MULLE_MONITOR_DIR}/share/bin:${PATH}" \
      exekutor "${functionname}" ${MULLE_TASK_FLAGS} "$@"

   rval=$?
   remember_task_rval "${task}" "${rval}"

   done_pid "${taskpidfile}"

   return $rval
}


cat_task_main()
{
   log_entry "cat_task_main" "$@"

   local task="$1"

   [ -z "${task}" ] && cat_task_usage "Empty task"

   local RVAL

   r_locate_task "${task}" || exit 1

   exekutor cat "${RVAL}"
}


add_task_main()
{
   log_entry "add_task_main" "$@"

   _cheap_help_options "add_task_usage"

   [ "$#" -ne 2 ] && add_task_usage

   local task="$1"
   local filename="$2"

   [ -z "${task}" ] && add_task_usage "Empty task"
   [ -z "${filename}" ] && add_task_usage "missing filename"

   local _plugin
   local RVAL

   r_task_plugin_install_filename "${task}"
   _plugin="${RVAL}"

   [ -e "${_plugin}" -a "${MULLE_FLAG_MAGNUM_FORCE}" = "NO" ] \
      && fail "\"${_plugin}\" already exists. Use -f to clobber"

   __require_filename "${task}" "${filename}"

   local plugindir

   r_fast_dirname "${_plugin}"
   plugindir="${RVAL}"

   patternfile="${OPTION_POSITION}-${typename}--${OPTION_CATEGORY}"
   if [ "${filename}" = "-" ]
   then
      local text

      text="`cat`"
      mkdir_if_missing "${plugindir}" # do as late as possible
      redirect_exekutor "${_plugin}" echo "${text}"
   else
      mkdir_if_missing "${plugindir}"
      exekutor cp "${filename}" "${_plugin}"
   fi
   exekutor chmod -x "${_plugin}"
}


remove_task_main()
{
   log_entry "remove_task_main" "$@"

   _cheap_help_options "remove_task_usage"

   [ "$#" -ne 1 ] && remove_task_usage

   local task="$1"

   local _plugin
   local RVAL

   r_task_plugin_install_filename "${task}"
   _plugin="${RVAL}"

   if [ ! -e "${_plugin}" ]
   then
      log_warning "\"${_plugin}\" does not exist."
      return 0
   fi

   remove_file_if_present "${_plugin}"
}


list_task_main()
{
   log_entry "list_task_main" "$@"

   [ "$#" -ne 0 ] && list_task_usage

   if [ -d "${MULLE_MONITOR_DIR}/libexec" ]
   then
   (
      log_info "Custom Tasks:"
      log_verbose "Custom tasks override extension tasks of same name"

      cd "${MULLE_MONITOR_DIR}/libexec"
      ls -1 *-task.sh 2> /dev/null | sed -e 's/-task\.sh//'
   )
   fi

   if [ -d "${MULLE_MONITOR_DIR}/share/libexec" ]
   then
   (
      log_info "Extension Tasks:"

      cd "${MULLE_MONITOR_DIR}/share/libexec"
      ls -1 *-task.sh 2> /dev/null | sed -e 's/-task\.sh//'
   )
   fi
}


test_task_main()
{
   log_entry "test_task_main" "$@"

   _cheap_help_options "test_task_usage"

   [ "$#" -lt 1 ] && test_task_usage

   local RVAL

   r_require_task "$@"
}


status_task_main()
{
   log_entry "status_task_main" "$@"

   _cheap_help_options "status_task_usage"

   [ "$#" -lt 1 ] && status_task_usage

   local task="$1"

   local taskpidfile
   local taskdonefile
   local RVAL

   r_task_pidfile "${task}"
   taskpidfile="${RVAL}"

   if [ -f "${taskpidfile}" ]
   then
      echo "running"
      return
   fi

   r_task_donefile "${task}"
   taskdonefile="${RVAL}"
   if [ -f "${taskdonefile}" ]
   then
      cat "${taskdonefile}"
      return
   fi

   echo "unknown"
}


kill_task_main()
{
   log_entry "status_task_main" "$@"

   _cheap_help_options "kill_task_usage"

   [ "$#" -lt 1 ] && kill_task_usage

   local task="$1"

   local taskdonefile
   local RVAL

   r_task_pidfile "${task}"
   taskpidfile="${RVAL}"

   if [ ! -f "${taskpidfile}" ]
   then
      log_warning "Task \"${task}\" not known to be running. \
Started by a different monitor ?"
      return 1
   fi

   local pid

   pid="`cat "${taskpidfile}"`"
   if [ "${pid}" != "$$" ]
   then
      log_fluff "Killing \"${task}\" with pid $pid"
      kill $pid
   else
      log_warning "Task \"${task}\" is running synchronous, can't kill"
   fi
}


ps_task_main()
{
   log_entry "ps_task_main" "$@"

   [ "$#" -ne 0 ] && list_task_usage

   log_info "Running Tasks:"
   if [ -d "${MULLE_MONITOR_DIR}/var/${MULLE_HOSTNAME}/run/monitor" ]
   then
   (
      cd "${MULLE_MONITOR_DIR}/var/${MULLE_HOSTNAME}/run/monitor"
      IFS="
"
      for pidfile in `ls -1 *-task.pid 2> /dev/null`
      do
         task="${pidfile%-task\.pid}"
         pid="`cat "${pidfile}"`"
         if [ "${pid}" = "$$" ]
         then
            pid=""
         fi
         echo "$pid" "${task}"
      done
   )
   fi
}


# "Hidden" command for testing
locate_task_main()
{
   log_entry "locate_task_main" "$@"

   _cheap_help_options "run_task_usage"

   [ "$#" -lt 1 ] && run_task_usage

   local task="$1"; shift

   local RVAL

   r_locate_task "${task}" || exit 1

   exekutor echo "${RVAL}"
}



###
###  MAIN
###
monitor_task_main()
{
   log_entry "monitor_task_main" "$@"

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

   _cheap_help_options "monitor_task_usage"


   local cmd="${1:-list}"
   [ $# -ne 0 ] && shift

   case "${cmd}" in
      add|cat|kill|list|locate|ps|run|status|test|remove)
         ${cmd}_task_main "$@"
      ;;

      *)
         monitor_task_usage "unknown command \"${cmd}\""
      ;;
   esac
}
