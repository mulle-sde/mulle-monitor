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

MULLE_MONITOR_CLEAN_SH="included"



monitor_clean_usage()
{
   if [ "$#" -ne 0 ]
   then
      log_error "$*"
   fi

   cat <<EOF >&2
Usage:
   ${MULLE_USAGE_NAME} clean

   Remove housekeeping files.
EOF
   exit 1
}




###
###  MAIN
###
monitor_clean_main()
{
   log_entry "monitor_clean_main" "$@"

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

   while :
   do
      case "$1" in
         -h|--help)
            monitor_clean_usage
         ;;

         -*)
            monitor_clean_usage "unknown option \"$1\""
         ;;

         *)
            break
         ;;
      esac

      shift
   done

   [ -z "${MULLE_MONITOR_DIR}" ] && internal_fail "empty MULLE_MONITOR_DIR"

   #
   # why another /monitor ?
   # because MULLE_MONITOR_DIR could be shared with other MULLE tools
   # like mulle-sde and we don't want to wipe their stuff
   #
   rmdir_safer "${MULLE_MONITOR_DIR}/var/run/monitor"
   rmdir_safer "${MULLE_MONITOR_DIR}/var/cache/monitor"
}

