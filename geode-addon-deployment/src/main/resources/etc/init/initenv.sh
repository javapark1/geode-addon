#!/usr/bin/env bash
SCRIPT_DIR="$(cd -P -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
. $SCRIPT_DIR/setenv.sh

#
# IMPORTANT: Do NOT modify the following.
#
. $GEODE_ADDON_HOME/bin_sh/.geode_addon_completion.bash

#
#  Set the default environment variable for this RWE.
#
RWE_DIR="$GEODE_ADDON_WORKSPACES_HOME/.rwe"
DEFAULTENV_FILE="$RWE_DIR/defaultenv.sh"
if [ -f "$DEFAULTENV_FILE" ]; then
   . "$DEFAULTENV_FILE"
fi

#
# Remove the previous paths from PATH to prevent duplicates
#
if [ "$GEODE_ADDON_PATH" == "" ]; then
   CLEANED_PATH=$PATH
else
   CLEANED_PATH=${PATH//$GEODE_ADDON_PATH:/}
fi

#
# Set PATH by removing old paths first to prevent duplicates
#
declare -a __PATHS
let __INDEX=0
if [ "$GEODE_HOME" != "" ]; then
   __PATHS[$__INDEX]="$GEODE_HOME/bin"
   let __INDEX=__INDEX+1
fi
if [ "$JAVA_HOME" != "" ]; then
   __PATHS[__INDEX]="$JAVA_HOME/bin"
   let __INDEX=__INDEX+1
fi
__PATHS[__INDEX]="$GEODE_ADDON_HOME/bin_sh"

for ((i = 0; i < ${#__PATHS[@]}; i++)); do
   __TOKEN="${__PATHS[$i]}"
   CLEANED_PATH=${CLEANED_PATH//$__TOKEN:/}
   CLEANED_PATH=${CLEANED_PATH//$__TOKEN/}
   CLEANED_PATH=${CLEANED_PATH//::/:}
done
GEODE_ADDON_PATH=""
for ((i = 0; i < ${#__PATHS[@]}; i++)); do
   __TOKEN="${__PATHS[$i]}"
   GEODE_ADDON_PATH=$__TOKEN:"$GEODE_ADDON_PATH"
done
export GEODE_ADDON_PATH="${GEODE_ADDON_PATH::-1}"
export PATH=$GEODE_ADDON_PATH:$CLEANED_PATH

#
# Display initialization info
#
if [ "$1" == "" ] || [ "$1" != "-quiet" ]; then
      echo ""
      echo "Workspaces Home:"
      echo "   GEODE_ADDON_WORKSPACES_HOME=$GEODE_ADDON_WORKSPACES_HOME"
      echo "Workspace:"
      echo "   GEODE_ADDON_WORKSPACE=$GEODE_ADDON_WORKSPACE"
      echo ""
      echo "All of your geode-addon operations will be recorded in the workspace directory."
      echo ""
fi
