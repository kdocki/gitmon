#!/bin/bash
#
# first you will need to setup a file that tells
# gitmon what to do anytime this git repository
# is updated
#
#   your/path/to/git/repo/.gitmon/changed
#
# next, to run script
#
#   ./gitmon path/to/git/repo
#
# lastly you'll likely want to add this to crontab
# to run gitmon every 2 minutes to check for updates
#
#   crontab -e
#   */2 * * * * gitmon path/to/git/repo



########################################################
# variables that we need for this script to work
########################################################
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
MONITOR_DIR="$1"
MONITOR_BRANCH="HEAD"
GITMON_DIR=".gitmon"
HISTORY_FILE="$GITMON_DIR/local.commit";
LOCK_FILE="$GITMON_DIR/running.lock";
ONCHANGED_FILE="$GITMON_DIR/changed";



#######################################################
# show usage if there aren't any arguments from user
#######################################################
if [ -z "$MONITOR_DIR" ]; then
  echo "usage:"
  echo "$0 path/to/git/repository"
  exit;
fi



########################################################
# ensure that this directory has .git repo in it
########################################################
if [ ! -d "$MONITOR_DIR/.git" ]; then
  echo "Could not find .git in: '$MONITOR_DIR'"
  exit
fi



#######################################################
# no point in running if we don't have onchanged file
#######################################################
if [ ! -f "$MONITOR_DIR/$ONCHANGED_FILE" ]; then
  echo "You need to create on changed script: $MONITOR_DIR/$ONCHANGED_FILE"
  exit
fi


########################################################
# only run this script when lock file doesn't exist
########################################################
cd $MONITOR_DIR

if [ -f $LOCK_FILE ]; then exit; fi;
touch $LOCK_FILE



########################################################
# find the last local and remote commit so we can
# compare them and see if they are different
########################################################
HISTORY=($(git ls-remote --quiet))

LOCAL_BRANCH=$(git symbolic-ref -q HEAD)
LOCAL_BRANCH=${LOCAL_BRANCH##refs/heads/}
LOCAL_BRANCH=${LOCAL_BRANCH:-HEAD}
LOCAL_COMMIT=$(git log -n 1 $LOCAL_BRANCH --pretty=format:"%H")

REMOTE_BRANCH=$(git symbolic-ref -q HEAD)
for ((i=0; i < ${#HISTORY[*]}; i+=2)) do
  if [[ "${HISTORY[i+1]}" == "$REMOTE_BRANCH" ]]; then
    REMOTE_COMMIT="${HISTORY[i]}"
  fi
done



########################################################
# if no remote commit is set then we need to bail
########################################################
if [ -z "$REMOTE_COMMIT" ]; then
  echo "Could not find remote branch commit for $REMOTE_BRANCH"
  rm $LOCK_FILE
  cd $SCRIPT_DIR
  exit
fi



########################################################
# compares the LOCAL_COMMIT with REMOTE_COMMIT and if
# things have changed then onChange function is called
########################################################
if [ "$LOCAL_COMMIT" != "$REMOTE_COMMIT" ]; then
  . $ONCHANGED_FILE "$LOCAL_BRANCH" "$REMOTE_BRANCH" "$LOCAL_COMMIT" "$REMOTE_COMMIT"
fi



########################################################
# remove the lock file now that we are done with script
########################################################
rm $LOCK_FILE
cd $SCRIPT_DIR
