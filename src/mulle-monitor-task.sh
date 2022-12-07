# shellcheck shell=bash
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


monitor::task::print_commands()
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


monitor::task::usage()
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

   monitor::task::print_commands "${MULLE_FLAG_LOG_VERBOSE}" | LC_ALL=C sort >&2

   if [ "${MULLE_FLAG_LOG_VERBOSE}" != 'YES' ]
   then
      cat <<EOF >&2
      (use ${MULLE_USAGE_NAME} -v task help to show more commands)
EOF
   fi

   exit 1
}


monitor::task::add_usage()
{
   if [ "$#" -ne 0 ]
   then
      log_error "$*"
   fi

   cat <<EOF >&2
Usage:
   ${MULLE_USAGE_NAME} task add <task> <script>

   Install a sourceable bash script as a mulle-sde task. You may specify '-'
   as to read it from stdin. See task create for a quicker way to create
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


monitor::task::create_usage()
{
   if [ "$#" -ne 0 ]
   then
      log_error "$*"
   fi

   cat <<EOF >&2
Usage:
   ${MULLE_USAGE_NAME} task create [options] <task> ...

   Create a task from commandline arguments. This is the simplest albeit
   somewhat limited from of creating a task. You can then edit the task with
   \`${MULLE_USAGE_NAME} task edit\`.

Examples:
   ${MULLE_USAGE_NAME} task create echo "Hello World"
   ${MULLE_USAGE_NAME} task create ~/bin/my-script "whatever"

Options:
   --callback : also create a callback with the same name

EOF
   exit 1
}


monitor::task::remove_usage()
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


monitor::task::list_usage()
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


monitor::task::edit_usage()
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


monitor::task::kill_usage()
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


monitor::task::status_usage()
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


monitor::task::run_usage()
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


monitor::task::cat_usage()
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


monitor::task::test_usage()
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


monitor::task::ps_usage()
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
monitor::task::cheap_help_options()
{
   local usage="$1" ; shift

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


monitor::task::r_donefile()
{
   log_entry "monitor::task::r_donefile" "$@"

   local task="$1"

   r_extended_identifier "${task}"
   RVAL="${MULLE_MONITOR_VAR_DIR}/run/monitor/${RVAL}-task"
}


monitor::task::r_pidfile()
{
   log_entry "monitor::task::r_pidfile" "$@"

   local task="$1"

   r_extended_identifier "${task}"
   RVAL="${MULLE_MONITOR_VAR_DIR}/run/monitor/${RVAL}-task.pid"
}


monitor::task::echo_run()
{
   log_entry "monitor::task::echo_run" "$@"

   rexekutor echo "The echo task does nothing. ($*)"
}


monitor::task::r_get_entry_functionname()
{
   log_entry "monitor::task::r_get_entry_functionname" "$@"

   local task="$1"

   [ -z "${task}" ] && _internal_fail "empty task"

   r_extended_identifier "${task}"
   RVAL="${RVAL}_task_run"

   log_debug "task functionname: \"${RVAL}\""
}


monitor::task::r_plugin_install_filename()
{
   log_entry "monitor::task::r_plugin_install_filename" "$@"

   local task="$1"

   [ -z "${MULLE_MONITOR_ETC_DIR}" ] && _internal_fail "MULLE_MONITOR_ETC_DIR not set"

   RVAL="${MULLE_MONITOR_ETC_DIR}/libexec/${task}-task.sh"
}


monitor::task::r_plugin_filename()
{
   log_entry "monitor::task::r_plugin_filename" "$@"

   local task="$1"

   [ -z "${MULLE_MONITOR_ETC_DIR}" ] && _internal_fail "MULLE_MONITOR_ETC_DIR not set"

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


monitor::task::r_locate()
{
   log_entry "monitor::task::r_locate" "$@"

   local task="$1"

   if ! monitor::task::r_plugin_filename "${task}"
   then
      log_error "There is no installed task \"${task}\" (${RVAL})."
      return 1
   fi

   r_absolutepath "${RVAL}"
}


monitor::task::load()
{
   log_entry "monitor::task::load" "$@"

   local task="$1"


   local filename
   if ! monitor::task::r_locate "${task}"
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


monitor::task::require_filename()
{
   log_entry "monitor::task::require_filename" "$@"

   local task="$1"
   local filename="$2"

   local functionname

   monitor::task::r_get_entry_functionname "${task}"
   functionname="${RVAL}"

   unset -f "${functionname}"

   . "${filename}" 2> /dev/null || fail "\"${filename}\" is not a valid bash script"

   if ! shell_is_function "${functionname}"
   then
      fail "\"${filename}\" does not define function \"${functionname}\""
   fi
}


monitor::task::r_require()
{
   log_entry "monitor::task::r_require" "$@"

   local task="$1"

   local functionname

   monitor::task::r_get_entry_functionname "${task}"
   functionname="${RVAL}"

   if ! shell_is_function "${functionname}"
   then
      monitor::task::load "${task}"
   fi

   # assume function is defined, get error later when we call
   RVAL="${functionname}"
   return 0
}


monitor::task::remove_job()
{
   log_entry "monitor::task::remove_job" "$@"

   local task="$1"

   monitor::task::r_pidfile "${task}"
   monitor::process::kill_pid "${RVAL}"
}


# in here for backwards compatibility with non-upgraded projects
remove_task_job()
{
   monitor::task::remove_job "$@"
}



monitor::task::remember_rval()
{
   log_entry "monitor::task::remember_rval" "$@"

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
         _internal_fail "rval is empty"
      ;;
   esac

   monitor::task::r_donefile "${task}"
   taskdonefile="${RVAL}"

   r_mkdir_parent_if_missing "${taskdonefile}"
   redirect_exekutor "${taskdonefile}" printf "%s\n" "${taskstatus}"
}


monitor::task::add_job_sync()
{
   log_entry "monitor::task::add_job_sync" "$@"

   local task="$1" 
   local sleepexe="$2"
   local taskdelay="$3" 

   shift 3

   # rest commandline

   local taskpidfile

   monitor::task::r_pidfile "${task}"
   taskpidfile="${RVAL}"

   #
   # there could be a race here with two tasks writing into the same file
   # the last one wins...
   # We can be harmlessly killed now
   #
   trap 'log_fluff "Task \"${task}\" with pid ${BASHPID} killed" ; exit 1' TERM
   monitor::process::announce_current_pid "${taskpidfile}"

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
   log_verbose "Execute task \"${1#"${MULLE_USER_PWD}/"}\""


   log_fluff "==> Starting${modifier}task"

   local rval

   PATH="${MULLE_MONITOR_SHARE_DIR}/bin:${PATH}" \
      eval_exekutor "$@"
   rval=$?

   monitor::task::remember_rval "${task}" "${rval}"

   log_fluff "==> Ended task ($rval)"

   monitor::process::done_pid "${taskpidfile}"
}


monitor::task::wait_for_previous_job()
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
   while monitor::process::check_pid "${taskpidfile}"
   do
      log_fluff "Waiting for previous uninterruptible task to complete"
      sleep 1
   done
}


# asynchronously
monitor::task::add_job()
{
   log_entry "monitor::task::add_job" "$@"

   local task="$1"

   # rest commandline

   monitor::task::r_require "${task}" || exit 1
   functionname="${RVAL}"

   local taskpidfile

   monitor::task::r_pidfile "${task}"
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
      monitor::task::wait_for_previous_job "${taskpidfile}"
   else
      monitor::process::kill_pid "${taskpidfile}"
   fi

   include "parallel"

   (
      monitor::task::add_job_sync "${task}" \
                                  "${MULLE_MONITOR_SLEEP_EXE:-very_short_sleep}" \
                                  "${MULLE_MONITOR_SLEEP_TIME:-010}" \
                                  "'${functionname}'" \
                                  "$@"
   ) &
}


# synchronously
monitor::task::run_job()
{
   log_entry "monitor::task::run_job" "$@"

   local task="$1"; shift

   local functionname

   monitor::task::r_require "${task}" || exit 1
   functionname="${RVAL}"

   #
   # check that a task of same name is not running/schedulded. If yes
   # prempt it.
   #

   local taskpidfile

   monitor::task::r_pidfile "${task}"
   taskpidfile="${RVAL}"

   if [ "${MULLE_MONITOR_PREEMPT}" = 'NO' ]
   then
      monitor::task::wait_for_previous_job "${taskpidfile}"
   else
      monitor::process::kill_pid "${taskpidfile}"
   fi

   include "parallel"

   # Delay task schedule by 0.01 second, so that we can "coalesce"
   # incoming events
   #
   monitor::task::add_job_sync "${task}" \
                               "${MULLE_MONITOR_SLEEP_EXE:-very_short_sleep}" \
                               "${MULLE_MONITOR_SLEEP_TIME:-010}" \
                               "'${functionname}'" \
                               "$@"
}


#
# just runs the task, doesn't care if other monitor is running or not
# just clobbers
#
monitor::task::run()
{
   log_entry "monitor::task::run" "$@"

   local task="$1"

   [ -z "${task}" ] && monitor::task::cat_usage "Empty task"

   shift

   local functionname

   monitor::task::r_require "${task}" || exit 1
   functionname="${RVAL}"

   local taskpidfile

   monitor::task::r_pidfile "${task}"
   taskpidfile="${RVAL}"

   monitor::process::kill_pid "${taskpidfile}"

   local rval

   log_verbose "Execute task \"${functionname#"${MULLE_USER_PWD}/"}\""

   monitor::process::announce_current_pid "${taskpidfile}"
   PATH="${MULLE_MONITOR_SHARE_DIR}/bin:${MULLE_MONITOR_SHARE_DIR}/bin:${PATH}" \
      exekutor "${functionname}" ${MULLE_MONITOR_TASK_FLAGS} "$@"
   rval=$?

   monitor::task::remember_rval "${task}" "${rval}"
   monitor::process::done_pid "${taskpidfile}"

   return $rval
}


# in here for backwards compatibility with non-upgraded projects
run_task_main()
{
   monitor::task::run "$@"
}


monitor::task::cat()
{
   log_entry "monitor::task::cat" "$@"

   local task="$1"

   [ -z "${task}" ] && monitor::task::cat_usage "Empty task"

   monitor::task::r_locate "${task}" || exit 1

   exekutor cat "${RVAL}"
}


monitor::task::emit_default()
{
   log_entry "monitor::task::emit_default" "$@"

   local task="$1"; shift

   monitor::task::r_get_entry_functionname "${task}"

   cat <<EOF
#! /usr/bin/env mulle-bash
# shellcheck shell=bash

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
   ${RVAL} "\$@"
fi

EOF
}


#
# TODO: this is old code, that doesn't really understand the etc / share
#       mechanism
#
monitor::task::add()
{
   log_entry "monitor::task::add" "$@"

   monitor::task::cheap_help_options "monitor::task::add_usage" "$@"

   [ "$#" -ne 2 ] && monitor::task::add_usage

   local task="$1"
   local filename="$2"

   r_extended_identifier "${task}"
   [ "${RVAL}" != "${task}" ] && fail "\"${task}\" is not a valid task identifier"

   [ -z "${filename}" ] && monitor::task::add_usage "missing filename"

   local plugin

   monitor::task::r_plugin_install_filename "${task}"
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
         monitor::task::require_filename "${task}" "${filename}"
      ) || exit 1

      mkdir_if_missing "${plugindir}"
      exekutor cp "${filename}" "${plugin}"
   fi
   exekutor chmod +x "${plugin}"
}


monitor::task::create()
{
   log_entry "monitor::task::create" "$@"

   local OPTION_CALLBACK

   while :
   do
      case "$1" in
         -h*|--help|help)
            monitor::task::create_usage
         ;;

         --callback)
            OPTION_CALLBACK='YES'
         ;;

         -*)
            monitor::task::create_usage "Unknown option \"$1\""
         ;;

         *)
            break
         ;;
      esac

      shift
   done

   [ "$#" -lt 1 ] && monitor::task::create_usage

   local task="$1"; shift

   r_extended_identifier "${task}"
   [ "${RVAL}" != "${task}" ] && fail "\"${task}\" is not a valid task identifier"

   if monitor::task::emit_default "${task}" "$@" | monitor::task::add "${task}" "-"
   then
      if [ "${OPTION_CALLBACK}" = 'YES' ]
      then
         include "monitor::callback"

         monitor::callback::create "${task}"
         return $?
      fi
   fi

   return 1
}



monitor::task::edit()
{
   log_entry "monitor::task::edit" "$@"

   monitor::task::cheap_help_options "monitor::task::edit_usage" "$@"

   [ "$#" -ne 1 ] && monitor::task::edit_usage

   local task="$1"

   local plugin

   monitor::task::r_plugin_filename "${task}"
   plugin="${RVAL}"

   if [ ! -e "${plugin}" ]
   then
      log_warning "\"${plugin}\" does not exist."
      return 0
   fi

   ${EDITOR:-vi} "${plugin}"
}


monitor::task::remove()
{
   log_entry "monitor::task::remove" "$@"

   monitor::task::cheap_help_options "monitor::task::remove_usage" "$@"

   [ "$#" -ne 1 ] && monitor::task::remove_usage

   local task="$1"

   local plugin

   monitor::task::r_plugin_filename "${task}"
   plugin="${RVAL}"

   if [ ! -e "${plugin}" ]
   then
      log_warning "\"${plugin}\" does not exist."
      return 0
   fi

   remove_file_if_present "${plugin}"
}


# notice that this function always runs in a subshell
monitor::task::do_list()
(
   local directory="$1"
   local mode="$2"

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
            printf "   %s/%s\n" "${directory#"${MULLE_USER_PWD}/"}" "${filename}"
         ;;

         'output-cat')
            log_info "${C_RESET_BOLD}   ${filename%-task.sh}:"
            sed -e '/^#/d' -e '/^$/d' -e 's/^/     /' "${filename}"
            echo
         ;;

         *)
            _internal_fail "unknown mode \"${mode}\""
         ;;
      esac
   done
)



monitor::task::list()
{
   log_entry "monitor::task::list" "$@"

   local OPTION_MODE="output-name"

   while :
   do
      case "$1" in
         -h*|--help|help)
            monitor::task::list_usage
         ;;

         --output-path)
            OPTION_MODE='output-path'
         ;;

         --output-cat|--cat)
            OPTION_MODE="output-cat"
         ;;

         -*)
            monitor::task::list_usage "Unknown option \"$1\""
         ;;

         *)
            break
         ;;
      esac

      shift
   done

   [ "$#" -ne 0 ] && monitor::task::list_usage

   if [ -d "${MULLE_MONITOR_ETC_DIR}/libexec" ]
   then
      log_info "User Tasks"
      log_verbose "User tasks override extension tasks of same name"
      log_verbose "   ${C_RESET_BOLD}${MULLE_MONITOR_ETC_DIR#"${MULLE_USER_PWD}/"}/libexec"

      monitor::task::do_list "${MULLE_MONITOR_ETC_DIR}/libexec" "${OPTION_MODE}"
   fi

   if [ -d "${MULLE_MONITOR_SHARE_DIR}/libexec" ]
   then
      log_info "Extension Tasks"
      log_verbose "   ${C_RESET_BOLD}${MULLE_MONITOR_ETC_DIR#"${MULLE_USER_PWD}/"}/libexec"

      monitor::task::do_list "${MULLE_MONITOR_SHARE_DIR}/libexec" "${OPTION_MODE}"
   fi
}


monitor::task::test()
{
   log_entry "monitor::task::test" "$@"

   monitor::task::cheap_help_options "monitor::task::test_usage" "$@"

   local task="$1"

   [ "$#" -lt 1 ] && monitor::task::test_usage

   monitor::task::r_require "$@"

   if ! shell_is_function "${RVAL}"
   then
      fail "\"${task}\" does not define function \"${RVAL}\""
   fi
   return 0
}


monitor::task::status()
{
   log_entry "monitor::task::status" "$@"

   monitor::task::cheap_help_options "monitor::task::status_usage" "$@"

   [ "$#" -lt 1 ] && monitor::task::status_usage

   local task="$1"

   local taskpidfile
   local taskdonefile

   monitor::task::r_pidfile "${task}"
   taskpidfile="${RVAL}"

   if [ -f "${taskpidfile}" ]
   then
      echo "running"
      return
   fi

   monitor::task::r_donefile "${task}"
   taskdonefile="${RVAL}"
   if [ -f "${taskdonefile}" ]
   then
      cat "${taskdonefile}"
      return
   fi

   echo "unknown"
}


monitor::task::kill()
{
   log_entry "monitor::task::kill" "$@"

   monitor::task::cheap_help_options "monitor::task::kill_usage" "$@"

   [ "$#" -lt 1 ] && monitor::task::kill_usage

   local task="$1"

   local taskdonefile

   monitor::task::r_pidfile "${task}"
   taskpidfile="${RVAL}"

   if [ ! -f "${taskpidfile}" ]
   then
      _log_warning "Task \"${task}\" not known to be running. \
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


monitor::task::ps()
{
   log_entry "monitor::task::ps" "$@"

   [ "$#" -ne 0 ] && monitor::task::list_usage

   log_info "Running Tasks"
   if [ -d "${MULLE_MONITOR_VAR_DIR}/run/monitor" ]
   then
   (
      .foreachline pidfile in `dir_list_files "${MULLE_MONITOR_VAR_DIR}/run/monitor" "*-task.pid"`
      .do
         r_basename "${pidfile}"
         task="${RVAL%-task\.pid}"

         pid="`cat "${pidfile}"`"
         if [ "${pid}" = "$$" ]
         then
            pid=""
         fi
         printf "%s\n" "$pid" "${task}"
      .done
   )
   fi
}


# "Hidden" command for testing
monitor::task::locate()
{
   log_entry "monitor::task::locate" "$@"

   monitor::task::cheap_help_options "monitor::task::locate_usage" "$@"

   [ "$#" -lt 1 ] && monitor::task::run_usage

   local task="$1"; shift

   monitor::task::r_locate "${task}" || exit 1

   # keep absolute for tests and ease of use
   rexekutor printf "%s\n" "${RVAL}"
}



###
###  MAIN
###
monitor::task::main()
{
   log_entry "monitor::task::main" "$@"

   if [ -z "${MULLE_MONITOR_PROCESS_SH}" ]
   then
      # shellcheck source=src/mulle-monitor-process.sh
      . "${MULLE_MONITOR_LIBEXEC_DIR}/mulle-monitor-process.sh" || exit 1
   fi

   monitor::task::cheap_help_options "monitor::task::usage" "$@"

   local cmd="${1}"

   [ $# -ne 0 ] && shift

   case "${cmd:-list}" in
      add|cat|create|edit|kill|list|locate|ps|run|status|test|remove)
         monitor::task::${cmd} "$@"
         return $?
      ;;

      *)
         monitor::task::usage "unknown command \"${cmd}\""
      ;;
   esac
}
