#!/bin/sh

DEFAULT_BINDINGS="\
copy-mode o open
copy-mode s search
copy-mode-vi o open
copy-mode-vi s search
"

main() {
    local option curdir

    while getopts C: option; do
        case "$option" in
            C) curdir=$OPTARG ;;
        esac
    done

    shift "$((OPTIND-1))"

    case $# in
        (0)
            configure_tmux ;;
        (1)
            # Read text from stdin and trim surrounding whitespace
            local text=$(expr "$(cat)" : '^[[:space:]]*\(.*[^[:space:]]\)')
            exec tmux run-shell "$(shellescape "$0" -C "${curdir:-.}" "$1" "$text")" ;;
        (2)
            [ -z "$curdir" ] || cd -- "$curdir" || exit
            local command="$1" text="$2"

            [ -n "$text" ] || exit 0

            case "$command" in
                (open)
                    case "$2" in
                        (*://*)
                            command=browse ;;
                        (*)
                            command=edit ;;
                    esac
            esac

            case "$command" in
                (browse)
                    open_with_browser "$text" ;;
                (edit)
                    open_with_editor "$text" ;;
                (search)
                    search_with_browser "$text" ;;
                (*)
                    echo "unknown command: $command" >&2
                    exit 1
            esac
    esac
}

if printf %q '' >/dev/null 2>&1; then
    shellescape() {
        local q="$(printf " %q" "$@")"
        printf %s "${q#?}"
    }
else
    shellescape() {
        case "$*" in
            ('')
                printf %s "''" ;;
            (*[!A-Za-z0-9_.,:/@-]*)
                awk 'BEGIN {
                    n = ARGC - 1
                    for (i = 1; i <= n; i++) {
                        s = ARGV[i]
                        gsub(/[^\nA-Za-z0-9_.,:\/@-]/, "\\\\&", s)
                        gsub(/\n/, "\"\n\"", s)
                        printf "%s", s
                        if (i != n) printf " "
                    }
                    exit 0
                }' "$@" ;;
            (*)
                printf %s "$*" ;;
        esac
    }
fi

configure_tmux() {
    local bindings="$(tmux show-options -gqv @open-anything:bindings)" keymap key command
    local pipe_command="$(tmux show-options -gqv @open-anything:pipe-command)"
    : "${bindings:="$DEFAULT_BINDINGS"}" "${pipe_command:=pipe-no-clear}"
    echo "$bindings" | while read keymap key command; do
        [ -n "$command" ] || continue
        tmux bind-key -T "$keymap" "$key" \
             send -X "$pipe_command" "$(shellescape "$0") -C #{pane_current_path} $(shellescape "$command")"
    done
}

open_with_editor() {
    local tmux_value="$(tmux show-options -gqv @open-anything:editor)"
    local editor="${tmux_value:-"${VISUAL:-"${EDITOR:-vi}"}"}"
    local file lineno

    # filename:lineno:column
    file=$(expr "$1" : "\(.*\):[[:digit:]]\{1,\}:[[:digit:]]\{1,\}$")

    if [ -n "$file" ]; then
        lineno=${1%:*}
        lineno=${lineno##*:}
    else
        # filename:lineno
        file=$(expr "$1" : "\(.*\):[[:digit:]]\{1,\}$")
        if [ -n "$file" ]; then
            lineno=${1##*:}
        else
            # just filename
            file=$1
        fi
    fi

    case "${editor##*/}" in
        (*vi*|*emacs*|*nano|*pico)
            exec tmux new-window "$editor" ${lineno:+"+$lineno"} "$file" ;;
        (code)
            if [ -n "$lineno" ]; then
                exec tmux new-window "$editor" -g "$file:$lineno"
            else
                exec tmux new-window "$editor" "$file"
            fi ;;
        (*)
            exec tmux new-window "$editor" "$file"
    esac
}

open_with_browser() {
    local tmux_value="$(tmux show-options -gqv @open-anything:browser)"
    local browser="${tmux_value:-"$BROWSER"}"
    if [ -z "$browser" ]; then
        case "$(uname -s)" in
            (Darwin)
                browser=open ;;
            (*)
                browser=xdg-open ;;
        esac
    fi
    case "$browser" in
        (*%s*)
            exec tmux new-window "$(printf "$browser" "$(shellescape "$1")")" ;;
        (*)
            exec tmux new-window "$browser" "$1" ;;
    esac
}

search_with_browser() {
    local query="$(printf %s "$1" | curl -Gs -w %{url_effective} --data-urlencode @- ./ | sed 's/^[^?]*?//')"
    local tmux_value="$(tmux show-options -gqv @open-anything:search-url)"
    local url_template="${tmux_value:-"https://www.google.com/search?q="}"
    case "$url_template" in
        (*%s*)
            open_with_browser "$(printf "$url_template" "$query")" ;;
        (*)
            open_with_browser "$url_template$query"
    esac
}

expand_path() {
    case "$1" in
        (~*)
            local tilde
            eval "printf %s\\\\n ~$(shellescape "${1#?}")" ;;
        (*)
            printf %s\\n "$1"
    esac
}

main "$@"
