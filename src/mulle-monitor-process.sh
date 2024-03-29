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
MULLE_MONITOR_PROCESS_SH='included'

# obscure
# this works, when you execute
# monitor::process::get_current_pid in back ticks
#
monitor::process::get_current_pid()
{
   sh -c 'echo $PPID'
}


#
# pid handling
#
monitor::process::get_pid()
{
   log_entry "monitor::process::get_pid" "$@"

   local pid_file="$1"

   cat "${pid_file}" 2> /dev/null
}


monitor::process::does_pid_exist()
{
   log_entry "monitor::process::does_pid_exist" "$@"

   local pid="$1"

   local found

   case "${MULLE_UNAME}" in
      *)
         found="`ps -xef | grep "${pid}" | grep -v grep`"
      ;;
   esac

   [ ! -z "${found}" ]
}


monitor::process::done_pid()
{
   log_entry "monitor::process::done_pid" "$@"

   local pid_file="$1"

   rm "${pid_file}" 2> /dev/null
}


monitor::process::kill_pid()
{
   log_entry "monitor::process::kill_pid" "$@"

   local pid_file="$1"

   local old_pid

   old_pid="`monitor::process::get_pid "${pid_file}"`"
   if [ ! -z "${old_pid}" ]
   then
      log_verbose "Killing pid: ${old_pid} ($pid_file)"
      kill "${old_pid}" 2> /dev/null
   fi

   monitor::process::done_pid "${pid_file}"
}


monitor::process::announce_pid()
{
   log_entry "monitor::process::announce_pid" "$@"

   local pid="$1"
   local pid_file="$2"

   r_mkdir_parent_if_missing "${pid_file}"
   redirect_exekutor "${pid_file}" printf "%s\n" "${pid}" || exit 1
}


monitor::process::announce_current_pid()
{
   log_entry "monitor::process::announce_current_pid" "$@"

   local pid_file="$1"

   local pid

   if [ -z "${BASHPID}" ]
   then
      pid="$(sh -c 'echo $PPID && :')"
   else
      pid="${BASHPID}"
   fi
   monitor::process::announce_pid "${pid}" "$1"
}


monitor::process::check_pid()
{
   log_entry "monitor::process::check_pid" "$@"

   local pid_file="$1"

   local old_pid

   old_pid="`monitor::process::get_pid "${pid_file}"`"
   if [ -z "$old_pid" ]
   then
      return 1
   fi
   monitor::process::does_pid_exist "${old_pid}"
}

