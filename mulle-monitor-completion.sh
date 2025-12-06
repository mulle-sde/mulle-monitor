_mulle_monitor_complete() {
    local cur prev words cword cmds subcmds options

    _get_comp_words_by_ref -n : cur prev words cword

    # Global commands from main script case statement
    cmds="callback clean help libexec-dir library-path list match patternfile run task uname version"

    # Global options from main script
    options="-e --help -f --preempt --no-preempt --default-callback --sleep --version"

    # Determine if we're choosing a command or handling a specific command
    if [[ ${cword} -eq 1 ]]; then
        if [[ "${cur}" == -* ]]; then
            COMPREPLY=($(compgen -W "${options}" -- "$cur"))
        else
            COMPREPLY=($(compgen -W "${cmds}" -- "$cur"))
        fi
        return 0
    fi

    local cmd=${words[1]}

    case ${cmd} in
        help|--help|-h)
            # Help doesn't take subcommands or args
            COMPREPLY=()
            ;;
        libexec-dir|library-path|uname|version)
            # These take no arguments
            COMPREPLY=()
            ;;
        clean|list|match|patternfile)
            # Passed to mulle-match, assume no completions
            COMPREPLY=()
            ;;
        run)
            # Run command options from monitor::run::main
            local run_options="-h --help -i --ignore -q --qualifier -p --pause --no-pause -s --synchronous --asynchronous -d --all --craft --prelude-task --coda-task"
            if [[ "${cur}" == -* ]]; then
                COMPREPLY=($(compgen -W "${run_options}" -- "$cur"))
            elif [[ "${prev}" == "-d" ]] || [[ "${prev}" == "--directory" ]]; then
                COMPREPLY=($(compgen -d -- "$cur"))  # Directory completion
            elif [[ "${prev}" == "-q" ]] || [[ "${prev}" == "--qualifier" ]]; then
                COMPREPLY=()  # Free form
            else
                # Positional: directories to monitor
                COMPREPLY=($(compgen -d -- "$cur"))
            fi
            ;;
        callback)
            # Callback subcommands from monitor::callback::main
            local callback_cmds="add cat create edit list remove run locate"
            if [[ ${cword} -eq 2 ]]; then
                COMPREPLY=($(compgen -W "${callback_cmds}" -- "$cur"))
                return 0
            fi
            local subcmd=${words[2]}
            case ${subcmd} in
                help|--help|-h)
                    COMPREPLY=()
                    ;;
                list)
                    local list_opts="--output-name --output-path --cat"
                    if [[ "${cur}" == -* ]]; then
                        COMPREPLY=($(compgen -W "${list_opts}" -- "$cur"))
                    else
                        COMPREPLY=()
                    fi
                    ;;
                add|create|edit|remove|cat|run)
                    # These take a <name> argument, free form for simplicity
                    COMPREPLY=()
                    ;;
            esac
            ;;
        task)
            # Task subcommands from monitor::task::main
            local task_cmds="add cat create edit kill list locate ps run status test remove"
            if [[ ${cword} -eq 2 ]]; then
                COMPREPLY=($(compgen -W "${task_cmds}" -- "$cur"))
                return 0
            fi
            local subcmd=${words[2]}
            case ${subcmd} in
                help|--help|-h)
                    COMPREPLY=()
                    ;;
                list)
                    local list_opts="--output-name --output-path --cat"
                    if [[ "${cur}" == -* ]]; then
                        COMPREPLY=($(compgen -W "${list_opts}" -- "$cur"))
                    else
                        COMPREPLY=()
                    fi
                    ;;
                add)
                    # add <task> <script>, script could be a file
                    COMPREPLY=($(compgen -f -- "$cur"))
                    ;;
                create)
                    local create_opts="--callback"
                    if [[ "${cur}" == -* ]]; then
                        COMPREPLY=($(compgen -W "${create_opts}" -- "$cur"))
                    else
                        COMPREPLY=()  # Task name and commands, free form
                    fi
                    ;;
                edit|remove|run|cat|kill|status|test|locate)
                    # Take <task>, free form
                    COMPREPLY=()
                    ;;
                ps)
                    # No additional args
                    COMPREPLY=()
                    ;;
            esac
            ;;
        *)
            return 0  # No completion
            ;;
    esac
}

complete -F _mulle_monitor_complete mulle-monitor
