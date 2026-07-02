# wktrees shell integration for zsh

if (( ${+commands[wktrees]} )); then
    wktrees() {
        local args=() use_source=0

        for arg in "$@"; do
            if [[ "$arg" == "--source" ]]; then
                use_source=1
            else
                args+=("$arg")
            fi
        done

        if [[ -n "${COMPLETE:-}" ]]; then
            command wktrees "${args[@]}"
            return
        fi

        local cd_file exec_file exit_code=0
        cd_file="$(mktemp)"
        exec_file="$(mktemp)"

        WORKTRUNK_DIRECTIVE_CD_FILE="$cd_file" WORKTRUNK_DIRECTIVE_EXEC_FILE="$exec_file" command wktrees "${args[@]}" || exit_code=$?

        if [[ -s "$cd_file" ]]; then
            cd -- "$(<"$cd_file")"
        fi

        if [[ -s "$exec_file" ]]; then
            source "$exec_file"
        fi

        rm -f "$cd_file" "$exec_file"
        return "$exit_code"
    }
fi
