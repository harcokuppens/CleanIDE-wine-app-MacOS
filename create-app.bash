#!/bin/bash

# Create MacOS app for Windows CleanIDE GUI app running with wine on MacOS
#
# requirements:
#  -  Platypus app from https://sveinbjorn.org/platypus
#    After installing Platypus app install the platypus command via the App
#    by pressing an install button at:
#      menu  "Platypus -> Settings -> click "Install" button
# - wine
#      install via homebrew with :  brew install wine-stable

CLEAN_URL="https://ftp.cs.ru.nl/Clean/Clean31/windows/Clean_3.1_64.zip"
TMP_FILE="/tmp/clean$RANDOM.zip"
TMP_DIR="/tmp/cleanWineApp$RANDOM"
WINDOWS_CLEAN_DIR="$TMP_DIR/clean3.1/"

script_dir=$(dirname $0)
script_dir="$(realpath $script_dir)"
script_dir=${script_dir:?} # aborts with error if script_dir not set
cd "$script_dir" || exit
ICON="$script_dir/CleanIDE.icns"

APP_LAUNCHER="$script_dir/launcher.bash"

curl -L -o "$TMP_FILE" "$CLEAN_URL"
# zip already contains "Clean 3.1/" folder so just unzip in project folder
unzip -d "$TMP_DIR" "$TMP_FILE"
rm "$TMP_FILE"
mv "$TMP_DIR/Clean 3.1/" "$WINDOWS_CLEAN_DIR"

/usr/local/bin/platypus --quit-after-execution --droppable --app-icon "$ICON" \
    --document-icon "$ICON" --name 'CleanIDE' \
    --interface-type 'None' --interpreter '/bin/bash' --bundle-identifier nl.ru.cs.wineclean \
    --suffixes 'icl|prj|dcl' --uniform-type-identifiers 'public.item' \
    --bundled-file "$WINDOWS_CLEAN_DIR" --bundled-file remove_env.py \
    --bundled-file nitrile.env --author 'Harco Kuppens' \
    "$APP_LAUNCHER"
