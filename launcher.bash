#!/bin/bash
# Set up any environment variables needed for your GUI app
# For a Wine app, this might involve setting WINEPREFIX:

export WINE_PATH="/opt/homebrew/bin/wine"

LOGFILE="/tmp/clean_launcher_log.txt"

LOGGING_ENABLED="false"

log() {
    if [[ ! "$LOGGING_ENABLED" == "true" ]]; then
        return 0
    fi

    printf "%s - " "$(date)" >>"$LOGFILE"
    for arg in "$@"; do
        printf "'%s'" "$arg" >>"$LOGFILE"
    done
    printf "\n" >>"$LOGFILE"

}
#export WINEPREFIX="/path/to/your/wine/prefix" # Use an absolute path or a path relative to the app bundle if bundled
# By default, Wine uses a prefix located at ~/.wine, but you can create and use custom prefixes.

log "$@"

script_dir=$(dirname $0)
script_dir="$(realpath $script_dir)"
script_dir=${script_dir:?} # aborts with error if script_dir not set
cd "$script_dir" || exit

CLEAN_UNIX_PATH="$script_dir/clean3.1/CleanIDE.exe"
CLEAN_IDEENVS_PATH="$script_dir/clean3.1/Config/IDEEnvs"
CLEAN_WINDOWS_PATH="$(
    /opt/homebrew/bin/winepath -w "$CLEAN_UNIX_PATH" 2>/dev/null
)"

# Check if any arguments were passed (i.e., if a file was opened with the app)
if [ "$#" -gt 0 ]; then
    log "Files opened with the app:"
    # Loop through all passed arguments (file paths)
    for file_path in "$@"; do
        log "Processing file: $file_path"
        windows_path="$(
            /opt/homebrew/bin/winepath -w "$file_path" 2>/dev/null
        )"

        # patch compiler/linker/codegen paths in IDEEnvs for nitrile project
        extension="${file_path##*.}"
        if [[ "$extension" == "prj" ]] && grep "^\s*Target:\s*nitrile\s*$" "$file_path" >/dev/null; then
            log "patching paths for nitrile project in IDEEnvs to point to compiler/linker/codegen in current project"
            # remove old nitrile env
            /usr/bin/python3 remove_env.py "$CLEAN_IDEENVS_PATH" nitrile
            # add new nitrile env with current project path
            PROJECT_PATH=$(dirname "$file_path")
            WINDOWS_PROJECT_PATH="$(
                /opt/homebrew/bin/winepath -w "$PROJECT_PATH" 2>/dev/null
            )"
            cat "$script_dir/nitrile.env" | sed -e "s/PROJECT_PATH/${WINDOWS_PROJECT_PATH}/" >>"$CLEAN_IDEENVS_PATH"
        fi

        log "Converted to Windows path: $windows_path"
        log "running cmd: \"$WINE_PATH\" start \"$CLEAN_WINDOWS_PATH\" \"$windows_path\" 2>/dev/null"
        "$WINE_PATH" start "$CLEAN_WINDOWS_PATH" "$windows_path" 2>/dev/null
    done
else
    # If no arguments were passed, launch the app without a file (e.g., if double-clicked)
    log "No files opened, launching app normally."
    log "running cmd: \"$WINE_PATH\" start \"$CLEAN_WINDOWS_PATH\"  2>/dev/null"
    "$WINE_PATH" start "$CLEAN_WINDOWS_PATH" 2>/dev/null
    #"$WINE_PATH" WINEPREFIX="$WINEPREFIX" C:\\path\\to\\your\\windows\\app.exe &
fi
