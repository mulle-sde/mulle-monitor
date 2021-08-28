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


task_print_commands()
{
   local show_all="${1:-NO}"

      SHOWN_COMMANDS="\
   add        : install a bash script as a task
   kill       : kill a running task
   list       : list installed tasks
   ps         : list running tasks
   remove     : remove a task
   run        : run task"

      HIDDEN_COMMANDS="\
   cat        : print the task script to stdout
   create     : create a minimal example task
   edit       : edit a task script
   status     : get status of running or last ran task
   test       : load task and check that the required main function is present"

   printf "%s\n" "${SHOWN_COMMANDS}"

   if [ "${show_all}" != 'NO' ]
   then
      printf "%s\n" "${HIDDEN_COMMANDS}"
   fi
}


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
EOF

   task_print_commands "${MULLE_FLAG_LOG_VERBOSE}" | LC_ALL=C sort >&2

   if [ "${MULLE_FLAG_LOG_VERBOSE}" != 'YES' ]
   then
      cat <<EOF >&2
      (use ${MULLE_USAGE_NAME} -v task help to show more commands)
EOF
   fi

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

   Install a sourceable bash script as a mulle-sde task. You may specify '-'
   as to read it from stdin. See task create for a more quick way to create
   simple tasks.

   Your script should query the environment variable MULLE_FLAG_DRY_RUN and
   conditionally execute/print statements like so:

      if [ "${MULLE_FLAG_DRY_RUN}" = 'YES' ]
      then
         echo 'git commit -m "xxx"' >&2
      else
         git commit -m "xxx'
      fi

   Or do it mulle-style like so:

      exekutor git commit -m "xxx'

EOF
   exit 1
}


create_task_usage()
{
   if [ "$#" -ne 0 ]
   then
      log_error "$*"
   fi

   cat <<EOF >&2
Usage:
   ${MULLE_USAGE_NAME} task create <task> ...

   Create a task from commandline arguments. This is the simplest albeit
   somewhat limited from of creating a task. You can then edit the task with
   \`${MULLE_USAGE_NAME} task edit\`.

   ${MULLE_USAGE_NAME} task create echo "Hello World"
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
   ${MULLE_USAGE_NAME} callback list [options]

   List installed tasks.

Options:
   --output-name : output the name of the task (default)
   --output-path : output the location of the task in the filesystem
   --cat         : show contents of the task (assumed to be a shellscript)

EOF
   exit 1
}


edit_task_usage()
{
   if [ "$#" -ne 0 ]
   then
      log_error "$*"
   fi

   cat <<EOF >&2
Usage:
   ${MULLE_USAGE_NAME} task edit <task>

   Use the default editor to edit a task inplace. A lazy shortcut for remove
   and add.

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

   r_identifier "${task}"
   RVAL="${MULLE_MONITOR_VAR_DIR}/run/monitor/${RVAL}-task"
}


r_task_pidfile()
{
   log_entry "r_task_pidfile" "$@"

   local task="$1"

   r_identifier "${task}"
   RVAL="${MULLE_MONITOR_VAR_DIR}/run/monitor/${RVAL}-task.pid"
}


echo_task_run()
{
   log_entry "echo_task_run" "$@"

   rexekutor echo "The echo task does nothing. ($*)"
}


r_task_get_entry_functionname()
{
   log_entry "r_task_get_entry_functionname" "$@"

   local task="$1"

   [ -z "${task}" ] && internal_fail "empty task"

   r_identifier "${task}"
   RVAL="${RVAL}_task_run"

   log_debug "task functionname: \"${RVAL}\""
}


r_task_plugin_install_filename()
{
   log_entry "r_task_plugin_install_filename" "$@"

   local task="$1"

   r_identifier "${task//_/+}"  # make underscores fail too
   if [ "${RVAL}" != "${task}" ]
   then
      fail "\"${task}\" must be a-zA-Z0-9-"
   fi

   [ -z "${MULLE_MONITOR_SHARE_DIR}" ] && internal_fail "MULLE_MONITOR_SHARE_DIR not set"

   RVAL="${MULLE_MONITOR_SHARE_DIR}/libexec/${task}-task.sh"
}


r_task_plugin_filename()
{
   log_entry "r_task_plugin_filename" "$@"

   local task="$1"

   [ -z "${MULLE_MONITOR_ETC_DIR}" ] && internal_fail "MULLE_MONITOR_ETC_DIR not set"

   if [ "${task}" = 'echo' ]
   then
      RVAL='echo'
      return 0
   fi

   RVAL="${MULLE_MONITOR_ETC_DIR}/libexec/${task}-task.sh"
   if [ -f "${RVAL}" ]
   then
      return 0
   fi

   RVAL="${MULLE_MONITOR_SHARE_DIR}/libexec/${task}-task.sh"
   [ -f "${RVAL}" ]
}


r_locate_task()
{
   log_entry "r_locate_task" "$@"

   local task="$1"

   if ! r_task_plugin_filename "${task}"
   then
      log_error "There is no installed task \"${task}\" (${RVAL})."
      return 1
   fi

   r_absolutepath "${RVAL}"
}


_load_task()
{
   log_entry "_load_task" "$@"

   local task="$1"


   local filename
   if ! r_locate_task "${task}"
   then
      exit 1
   fi
   filename="${RVAL}"

   if [ "${filename}" = 'echo' ]
   then
      return 0
   fi

   # scripts can skip some test code here if MULLE_MONITOR_TASK_LOAD is set
   log_debug "Include \"${filename}\""
   MULLE_MONITOR_TASK_LOAD='YES' . "${filename}" || fail  "\"${filename}\" failed on include"
}


__require_filename()
{
   log_entry "__require_filename" "$@"

   local task="$1"
   local filename="$2"

   local functionname

   r_task_get_entry_functionname "${task}"
   functionname="${RVAL}"

   unshell_disable_glob "${functionname}"

   . "${filename}" 2> /dev/null || fail "\"${filename}\" is not a valid bash script"

   if ! shell_is_function "${functionname}"
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

   if ! shell_is_function "${functionname}"
   then
      _load_task "${task}"
   fi

   # assume function is defined, get error later when we call
   RVAL="${functionname}"
   return 0
}


remove_task_job()
{
   log_entry "remove_task_job" "$@"

   local task="$1"

   r_task_pidfile "${task}"
   kill_pid "${RVAL}"
}


remember_task_rval()
{
   log_entry "remember_task_rval" "$@"

   local task="$1"
   local rval="$2"

   local taskdonefile
   local taskstatus

   taskstatus="failed"
   case "${rval}" in
      0)
         taskstatus="done"
      ;;

      "")
         internal_fail "rval is empty"
      ;;
   esac

   r_task_donefile "${task}"
   taskdonefile="${RVAL}"

   r_mkdir_parent_if_missing "${taskdonefile}"
   redirect_exekutor "${taskdonefile}" printf "%s\n" "${taskstatus}"
}


add_task_job_sync()
{
   local task="$1" ; shift
   local sleepexe="$1"; shift
   local taskdelay="$1" ; shift

   # rest commandline

   local taskpidfile

   r_task_pidfile "${task}"
   taskpidfile="${RVAL}"

   #
   # there could be a race here with two tasks writing into the same file
   # the last one wins...
   # We can be harmlessly killed now
   #
   trap 'log_fluff "Task \"${task}\" with pid ${BASHPID} killed" ; exit 1' TERM
   announce_current_pid "${taskpidfile}"

   local timestamp

   timestamp="`date +"%s"`"
   timestamp=$(( $timestamp + ${taskdelay%.*} ))
   timestamp=$(( $timestamp + 1 ))  # close to that date...

   case "${MULLE_UNAME}" in
      darwin)
         log_fluff "==> Scheduled task \"${task}\" for" `exekutor date -r ${timestamp} "+%H:%M:%S"`
      ;;

      *)
         log_fluff "==> Scheduled task \"${task}\" for" `exekutor date --date=@${timestamp} "+%H:%M:%S"`
      ;;
   esac

   exekutor "${sleepexe}" "${taskdelay}"

   local modifier

   modifier=" "
   if [ "${MULLE_MONITOR_PREEMPT}" = 'NO' ]
   then
      trap 'log_fluff "Task \"${task}\" ignores TERM ${BASHPID} now"' TERM
      modifier=" uninterruptible "
   fi

   #
   # depending on the setup, we may now want to hide the current pid
   # so it doesn't get killed (need a locking scheme ?)
   #
   log_fluff "==> Starting${modifier}task"

   local rval

   PATH="${MULLE_MONITOR_SHARE_DIR}/bin:${PATH}" \
      eval_exekutor "$@"
   rval=$?

   remember_task_rval "${task}" "${rval}"

   log_fluff "==> Ended task ($rval)"

   done_pid "${taskpidfile}"
}


wait_for_previous_task()
{
   local taskpidfile="$1"

   #
   # There are three possibilities:
   #    1) the task is still sleeping, it was harmlessly killed
   #    2) the task can be killed while running (-> make), same as 1
   #    3) the task can not be killed while running (-> git push). Then we
   #       have to wait for completion.
   #

   #
   # We could be unlucky here with another process grabbing the same pid ?
   #
   while check_pid "${taskpidfile}"
   do
      log_fluff "Waiting for previous uninterruptible task to complete"
      sleep 1
   done
}


# asynchronously
add_task_job()
{
   log_entry "add_task_job" "$@"

   local task="$1"

   # rest commandline

   r_require_task "${task}" || exit 1
   functionname="${RVAL}"

   local taskpidfile

   r_task_pidfile "${task}"
   taskpidfile="${RVAL}"

   #
   # There are three possibilities:
   #    1) the task is still sleeping, it was harmlessly killed
   #    2) the task can be killed while running (-> make), same as 1
   #    3) the task can not be killed while running (-> git push). Then we
   #       have to wait for completion.
   #
   if [ "${MULLE_MONITOR_PREEMPT}" = 'NO' ]
   then
      wait_for_previous_task "${taskpidfile}"
   else
      kill_pid "${taskpidfile}"
   fi

   (
      add_task_job_sync "${task}" \
                        "${MULLE_MONITOR_SLEEP_EXE:-sleep}" \
                        "${MULLE_MONITOR_SLEEP_TIME:-1}" \
                        "'${functionname}'" \
                        "$@"
   ) &
}


# synchronously
run_task_job()
{
   log_entry "run_task_job" "$@"

   local task="$1"; shift

   local functionname
   r_require_task "${task}" || exit 1
   functionname="${RVAL}"

   #
   # check that a task of same name is not running/schedulded. If yes
   # prempt it.
   #

   if [ "${MULLE_MONITOR_PREEMPT}" = 'NO' ]
   then
      wait_for_previous_task "${taskpidfile}"
   else
      kill_pid "${taskpidfile}"
   fi

   # Delay task schedule by 1 second, so that we can "coalesce"
   # incoming events
   #
   add_task_job_sync "${task}" \
                     "${MULLE_MONITOR_SLEEP_EXE:-sleep}" \
                     "${MULLE_MONITOR_SLEEP_TIME:-1}" \
                     "'${functionname}'" \
                     "$@"
}


#
# just runs the task, doesn't care if other monitor is running or not
# just clobbers
#
run_task_main()
{
   log_entry "run_task_main" "$@"

   local task="$1"

   [ -z "${task}" ] && cat_task_usage "Empty task"

   shift

   local functionname

   r_require_task "${task}" || exit 1
   functionname="${RVAL}"

   local taskpidfile

   r_task_pidfile "${task}"
   taskpidfile="${RVAL}"

   kill_pid "${taskpidfile}"

   local rval

   announce_current_pid "${taskpidfile}"
   PATH="${MULLE_MONITOR_SHARE_DIR}/bin:${MULLE_MONITOR_SHARE_DIR}/bin:${PATH}" \
      exekutor "${functionname}" ${MULLE_MONITOR_TASK_FLAGS} "$@"
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

   r_locate_task "${task}" || exit 1

   exekutor cat "${RVAL}"
}


emit_default_task()
{
   log_entry "emit_default_task" "$@"

   local task="$1"; shift

   r_task_get_entry_functionname "${task}"

   cat <<EOF
#! /usr/bin/env bash

#
# This function will be called by mulle-monitor
#
${RVAL}()
{
   log_entry "${RVAL}" "\$@"

   exekutor $*
}

#
# Convenience to test your script standalone
#
if [ -z "\${MULLE_MONITOR_TASK_LOAD}" ]
then
   if [ -z "\${MULLE_BASHFUNCTIONS_LIBEXEC_DIR}" ]
   then
      MULLE_BASHFUNCTIONS_LIBEXEC_DIR="\`mulle-bashfunctions-env libexec-dir 2> /dev/null\`"
      [ -z "\${MULLE_BASHFUNCTIONS_LIBEXEC_DIR}" ] && \\
         echo "mulle-bashfunctions are not installed" >&2 && \\
         exit 1

      . "\${MULLE_BASHFUNCTIONS_LIBEXEC_DIR}/mulle-bashfunctions.sh" || exit 1
   fi

   ${RVAL} "\$@"
fi

EOF
}


add_task_main()
{
   log_entry "add_task_main" "$@"

   _cheap_help_options "add_task_usage"

   [ "$#" -ne 2 ] && add_task_usage

   local task="$1"
   local filename="$2"

   validate_monitor_identifier "${task}"

   [ -z "${filename}" ] && add_task_usage "missing filename"

   local plugin

   r_task_plugin_install_filename "${task}"
   plugin="${RVAL}"

   [ -e "${plugin}" -a "${MULLE_FLAG_MAGNUM_FORCE}" = 'NO' ] \
      && fail "\"${plugin}\" already exists. Use -f to clobber"

   # check that it's valid
   local plugindir

   r_dirname "${plugin}"
   plugindir="${RVAL}"

   if [ "${filename}" = "-" ]
   then
      local text

      text="`cat`"
      mkdir_if_missing "${plugindir}" # do as late as possible
      redirect_exekutor "${plugin}" printf "%s\n" "${text}"
   else
      (
         __require_filename "${task}" "${filename}"
      ) || exit 1

      mkdir_if_missing "${plugindir}"
      exekutor cp "${filename}" "${plugin}"
   fi
   exekutor chmod -x "${plugin}"
}


create_task_main()
{
   log_entry "create_task_main" "$@"

   _cheap_help_options "create_task_main"

   [ "$#" -lt 1 ] && create_task_usage

   local task="$1"; shift

   validate_monitor_identifier "${task}"

   emit_default_task "${task}" "$@" | add_task_main "${task}" "-"
}



edit_task_main()
{
   log_entry "edit_task_main" "$@"

   _cheap_help_options "edit_task_usage"

   [ "$#" -ne 1 ] && edit_task_usage

   local task="$1"

   local _plugin
   r_task_plugin_install_filename "${task}"
   _plugin="${RVAL}"

   if [ ! -e "${_plugin}" ]
   then
      log_warning "\"${_plugin}\" does not exist."
      return 0
   fi

   ${EDITOR:-vi} "${_plugin}"
}


remove_task_main()
{
   log_entry "remove_task_main" "$@"

   _cheap_help_options "remove_task_usage"

   [ "$#" -ne 1 ] && remove_task_usage

   local task="$1"

   local _plugin
   r_task_plugin_install_filename "${task}"
   _plugin="${RVAL}"

   if [ ! -e "${_plugin}" ]
   then
      log_warning "\"${_plugin}\" does not exist."
      return 0
   fi

   remove_file_if_present "${_plugin}"
}


list_tasks()
{
   local directory="$1"
   local mode="$2"

   (
      rexekutor cd "${directory}" || exit 1

      local filename

      shell_enable_nullglob
      IFS=$'\n'
      for filename in *-task.sh
      do
         case "${mode}" in
            'output-name')
               printf "   %s\n" "${filename%-task.sh}"
               continue
            ;;

            'output-path')
               printf "   %s/%s\n" "${directory#${MULLE_USER_PWD}/}" "${filename}"
            ;;

            'output-cat')
               log_info "${C_RESET_BOLD}   ${filename%-task.sh}:"
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


list_task_main()
{
   log_entry "list_task_main" "$@"

   local OPTION_MODE="output-name"

   while :
   do
      case "$1" in
         -h*|--help|help)
            list_task_usage
         ;;

         --output-path)
            OPTION_MODE='output-path'
         ;;

         --output-cat|--cat)
            OPTION_MODE="output-cat"
         ;;

         -*)
            list_task_usage "Unknown option \"$1\""
         ;;

         *)
            break
         ;;
      esac

      shift
   done


   [ "$#" -ne 0 ] && list_task_usage

   if [ -d "${MULLE_MONITOR_ETC_DIR}/libexec" ]
   then
      log_info "User Tasks"
      log_verbose "User tasks override extension tasks of same name"
      log_verbose "   ${C_RESET_BOLD}${MULLE_MONITOR_ETC_DIR#${MULLE_USER_PWD}/}/libexec"

      list_tasks "${MULLE_MONITOR_ETC_DIR}/libexec" "${OPTION_MODE}"
   fi

   if [ -d "${MULLE_MONITOR_SHARE_DIR}/libexec" ]
   then
      log_info "Extension Tasks"
      log_verbose "   ${C_RESET_BOLD}${MULLE_MONITOR_ETC_DIR#${MULLE_USER_PWD}/}/libexec"

      list_tasks "${MULLE_MONITOR_SHARE_DIR}/libexec" "${OPTION_MODE}"
   fi
}


test_task_main()
{
   log_entry "test_task_main" "$@"

   _cheap_help_options "test_task_usage"

   local task="$1"

   [ "$#" -lt 1 ] && test_task_usage

   r_require_task "$@"

   if ! shell_is_function "${RVAL}"
   then
      fail "\"${task}\" does not define function \"${RVAL}\""
   fi
   return 0
}


status_task_main()
{
   log_entry "status_task_main" "$@"

   _cheap_help_options "status_task_usage"

   [ "$#" -lt 1 ] && status_task_usage

   local task="$1"

   local taskpidfile
   local taskdonefile

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

   log_info "Running Tasks"
   if [ -d "${MULLE_MONITOR_VAR_DIR}/run/monitor" ]
   then
   (
      cd "${MULLE_MONITOR_VAR_DIR}/run/monitor"
      IFS=$'\n'
      for pidfile in `ls -1 *-task.pid 2> /dev/null`
      do
         task="${pidfile%-task\.pid}"
         pid="`cat "${pidfile}"`"
         if [ "${pid}" = "$$" ]
         then
            pid=""
         fi
         printf "%s\n" "$pid" "${task}"
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

   r_locate_task "${task}" || exit 1

   # keep absolute for tests and ease of use
   rexekutor printf "%s\n" "${RVAL}"
}



###
###  MAIN
###
monitor_task_main()
{
   log_entry "monitor_task_main" "$@"

   if [ -z "${MULLE_MONITOR_PROCESS_SH}" ]
   then
      # shellcheck source=src/mulle-monitor-process.sh
      . "${MULLE_MONITOR_LIBEXEC_DIR}/mulle-monitor-process.sh" || exit 1
   fi

   _cheap_help_options "monitor_task_usage"


   local cmd="${1}"
   [ $# -ne 0 ] && shift

   case "${cmd}" in
      add|cat|create|edit|kill|list|locate|ps|run|status|test|remove)
         ${cmd}_task_main "$@"
      ;;

      "")
         monitor_task_usage
      ;;

      *)
         monitor_task_usage "unknown command \"${cmd}\""
      ;;
   esac
}
