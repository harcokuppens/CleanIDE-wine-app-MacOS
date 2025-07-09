#!/bin/bash
# Set up any environment variables needed for your GUI app
# For a Wine app, this might involve setting WINEPREFIX:

export WINE_PATH="/opt/homebrew/bin/wine"

LOGFILE="/tmp/clean_launcher_log.txt"

LOGGING_ENABLED="true"

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

        # in nitrile project the compiler/linker/codegen are installed in the
        # project directory as nitrile packages.
        # Therefore we need to patch the IDEEnvs file to point to the
        # compiler/linker/codegen in the current project directory.
        # This is done by creating a new nitrile env in the IDEEnvs file
        # using the nitrile.env template file.
        # The nitrile.env template file contains the relative path to the
        # project directory containing the nitrile project file.
        # So if project is nitrile project we must patch compiler/linker/codegen paths in the IDEEnvs for nitrile target.
        extension="${file_path##*.}"
        if [[ "$extension" == "prj" ]] && /usr/bin/grep "^\s*Target:\s*nitrile\s*$" "$file_path" >/dev/null; then
            log "Found nitrile project file: $file_path"

            # first check whether the windows nitrile libraries are present
            # get the absolute path to the project directory
            PROJECT_PATH=$(dirname "$file_path")
            if [[ ! -d "$PROJECT_PATH/nitrile-packages/windows-x64" ]]; then
                log "ERROR: missing the windows nitrile libraries in the nitrile project."
                log "Please run the command 'nitrile-in-docker-fetch-windows-libs' in your project to install them."
                MESSAGE="Problem:\n\n\tMissing the windows nitrile libraries in the nitrile project.\n\nSolution:\n\n\tPlease run the command:\n\n\t\tnitrile-in-docker-fetch-windows-libs\n\n\tin your project to install them."
                TITLE="Problem in opening the nitrile project in CleanIDE"
                osascript -e "display dialog \"$MESSAGE\" with title \"$TITLE\" buttons {\"OK\"} default button \"OK\"" >/dev/null
                exit 1
            fi

            log "patching paths for nitrile project in IDEEnvs for nitrile target to point to compiler/linker/codegen in current project"
            # remove old nitrile env
            /usr/bin/python3 remove_env.py "$CLEAN_IDEENVS_PATH" nitrile >/dev/null

            # to create new nitrile env we first need to get the relative
            # windows path from the directory where CleanIDE.exe is located
            # to the project directory containing the nitrile project file
            # NOTE: this is necessary because the CleanIDE.exe only supports
            #       relative paths in the IDEEnvs file

            # get application path (directory where CleanIDE.exe is located)
            # e.g. for /Applications/CleanIDE.app/Contents/Resources/clean3.1/CleanIDE.exe
            #      it is /Applications/CleanIDE.app/Contents/Resources/clean3.1/
            APP_DIR="$script_dir/clean3.1"
            # get relative path from application path  to /
            # eg. /Applications/CleanIDE.app/Contents/Resources -> ../../../../
            RELATIVE_PATH_FROM_APPDIR_TO_ROOT=$(echo "$APP_DIR" | sed -e 's/\/[^/]*/..\//g')
            # make it a windows relative path
            # eg. ../../../../ -> ..\..\..\..\
            RELATIVE_PATH_FROM_APPDIR_TO_ROOT=${RELATIVE_PATH_FROM_APPDIR_TO_ROOT//\//\\}

            # convert the absolute project path to a Windows path
            WINDOWS_PROJECT_PATH="$(
                /opt/homebrew/bin/winepath -w "$PROJECT_PATH" 2>/dev/null
            )"
            # remove drive letter and colon and root \ from Windows absolute project path
            RELATIVE_PATH_FROM_ROOT_PROJECT=${WINDOWS_PROJECT_PATH##*:\\}

            # prepend relative path to root to get a relative windos path from the cleanide app
            # to the project directory
            RELATIVE_WINDOWS_PROJECT_PATH="$RELATIVE_PATH_FROM_APPDIR_TO_ROOT$RELATIVE_PATH_FROM_ROOT_PROJECT"
            # escape backslashes for sed
            RELATIVE_WINDOWS_PROJECT_PATH=${RELATIVE_WINDOWS_PROJECT_PATH//\\/\\\\}

            # create a new nitrile env in IDEEnvs file using the nitrile.env template
            # in which we replace the PROJECT_PATH variable with the
            # relative windows path to the project directory
            cat "$script_dir/nitrile.env" | sed -e "s/PROJECT_PATH/${RELATIVE_WINDOWS_PROJECT_PATH}/" >>"$CLEAN_IDEENVS_PATH"
        else
            log "Found classic project file: $file_path"
            # no nitrile project, so no need to patch nitrile target in IDEEnvs
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
fi
