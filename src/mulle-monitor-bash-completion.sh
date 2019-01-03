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
[ "${TRACE}" = 'YES' ] && set -x && : "$0" "$@"


if [ "`type -t "_mulle_match_complete"`" != "function" ]
then
   . "$(mulle-match libexec-dir)/mulle-match-bash-completion.sh"
fi


_mulle_monitor_complete()
{
   local cur=${COMP_WORDS[COMP_CWORD]}
   local prev=${COMP_WORDS[COMP_CWORD-1]}

   local list
   local i
   local context

   for i in "${COMP_WORDS[@]}"
   do
      case "$i" in
         callback|clean|find|match|patternfile|run|task)
            context="$i"
         ;;
      esac
   done

   case "${context}" in
      clean|find|match|patternfile)
         _mulle_match_complete "$@"
      ;;

      run)
      ;;

      callback)
         case "$prev" in
            cat|remove|run)
               list="`mulle-monitor -s callback list`"
               COMPREPLY=( $( compgen -W "${list}" -- "$cur" ) )
            ;;

            add)
               COMPREPLY=( $( compgen -f -- "$cur" ) )
            ;;

            *)
               COMPREPLY=( $( compgen -W "add cat list remove run" -- "$cur" ) )
            ;;
         esac
      ;;

      task)
         case "$prev" in
            cat|kill|locate|ps|remove|run|status|test)
               list="`mulle-monitor -s task list`"
               COMPREPLY=( $( compgen -W "${list}" -- "$cur" ) )
            ;;

            add)
            ;;

            *)
               local prevprev

               if [ ${COMP_CWORD} -gt 1 ]
               then
                  prevprev=${COMP_WORDS[COMP_CWORD-2]}
               fi

               case "$prevprev" in
                  add)
                      COMPREPLY=( $( compgen -f -- "$cur" ) )
                  ;;

                  *)
                     COMPREPLY=( $( compgen -W "add cat kill list locate ps remove run status test" -- "$cur" ) )
                  ;;
               esac
            ;;
         esac
      ;;

      *)
         COMPREPLY=( $( compgen -W "callback clean find match patternfile run task" -- "$cur" ) )
      ;;
   esac
}

complete -F _mulle_monitor_complete mulle-monitor

