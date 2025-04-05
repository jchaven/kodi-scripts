#!/bin/bash
#
# UPDATE FAVORITES
#
# Based on specific days or time of year update the XML file
# to show different options (weekly cartoons, holidays, etc.)
# Note: limited to one change per day as coded.
#
# NOTE: THIS USES LOCAL CONTENT - NOT NAS CONTENT
# NOTE: THIS IS MEANT TO RUN FROM THE KODI DEVICE.
# NOTE: Librelec does not support GNU sort or GNU shuf commands
#
# Note: for day of week this script uses the "u" option:
#       %u     day of week (1..7); 1 is Monday
#       %w     day of week (0..6); 0 is Sunday
#
# Crontab entry
# Mn  Hr     Da   Mo   WD        COMMAND
# --  --     --   --   --        -----------------------------------------------
# 0    1      *    *    *        /storage/scripts/update-favorites.sh
#
#-------------------------------------------------------------------------------
# change internal field separator to newline only to allow spaces in name
OLDIFS=$IFS
IFS='
'

SCRIPT=`basename "$0"`      # get name of this script
RUN_DATE=$(date +"%Y%m%d")  # save current date (YYYYMMDD)

# file locations (from Kodi perspective)
LOGFILE="/storage/temp/$SCRIPT-$RUN_DATE.log"
LOCKFILE="/storage/temp/$SCRIPT.lock"
ERRORFILE="/storage/temp/$SCRIPT.error"

TELEGRAM_TOKEN=$(cat /storage/scripts/TELEGRAM_TOKEN)
TELEGRAM_CHAT_ID=$(cat /storage/scripts/TELEGRAM_CHATID)

DAYOFWEEK=$(date +"%u")

FILE_NAME="/storage/.kodi/userdata/favourites.xml"
UPDATE_FAVORITES=0           # Flag to initiate an update of favorites

#------------------------------------------------------------------
# FUNCTIONS
#------------------------------------------------------------------


#------------------------------------------------------------------
# PROCESS
#------------------------------------------------------------------
echo "$(date)|INFO|Starting script: $SCRIPT" >> "$LOGFILE"
echo "$(date)|INFO|Using Telegram Chat ID: $TELEGRAM_CHAT_ID" >> "$LOGFILE"

# CHECK FOR ISSUES
# if lock file exists something is wrong - abort
if [ -f "$LOCKFILE" ]; then
  # lock file exists
  echo "$(date)|ERROR|Lock file exists. Aborting." >> "$LOGFILE"

  # write to lock will be used to detect lock file existing too long
  echo $(date)" This file should not exist for more than a few minutes." >> $LOCKFILE

  # get number of lines in lock file
  LINES=$(wc -l < "$LOCKFILE")
  echo "$(date)|INFO|Lock file contains $LINES lines." >> "$LOGFILE"
  if [ $LINES -gt 5 ]; then

    TELEGRAM_MESSAGE="XBMC-2308: Error running script $SCRIPT. Lock file exists."
    curl -s -X POST https://api.telegram.org/bot$TELEGRAM_TOKEN/sendMessage -d chat_id=$TELEGRAM_CHAT_ID -d text="$TELEGRAM_MESSAGE" > /dev/null

  fi
  exit
fi
echo $(date)"|INFO|Lock file not found. Continuing." >> $LOGFILE


# create lock file
echo $(date)" This file should not exist for more than a few minutes." >> $LOCKFILE

#------------------------------------------------------------------
# START MAIN ROUTINE
#------------------------------------------------------------------
echo "$(date)|INFO|Today is: $(date +"%A") ($(date +"%u"))" >> "$LOGFILE"

# If Monday (1) change 'Saturday Morning Cartoons' back to 'Looney Tunes'
if [ $DAYOFWEEK -eq 1 ]; then
  UPDATE_FAVORITES=1
  OLD_VALUE="<favourite name=\"Cartoons\" thumb=\"/storage/nas/media/admin/graphics/Square Covers/cartoons.png\">PlayMedia(\"special://profile/playlists/video/Cartoons.xsp\")</favourite>"
  NEW_VALUE="<favourite name=\"Looney Tunes\" thumb=\"/storage/nas/media/admin/graphics/Square Covers/looneytunes.jpg\">PlayMedia(\"special://profile/playlists/video/Looney Tunes.xsp\")</favourite>"
fi

# If Saturday (6) change 'Looney Tunes' to 'Saturday Morning Cartoons'
if [ $DAYOFWEEK -eq 6 ]; then
  UPDATE_FAVORITES=1
  OLD_VALUE="<favourite name=\"Looney Tunes\" thumb=\"/storage/nas/media/admin/graphics/Square Covers/looneytunes.jpg\">PlayMedia(\"special://profile/playlists/video/Looney Tunes.xsp\")</favourite>"
  NEW_VALUE="<favourite name=\"Cartoons\" thumb=\"/storage/nas/media/admin/graphics/Square Covers/cartoons.png\">PlayMedia(\"special://profile/playlists/video/Cartoons.xsp\")</favourite>"
fi

# If flag to update set
if [ $UPDATE_FAVORITES -eq 1 ]; then
  # Note: using "~" as sed command separator
  echo "$(date)|INFO|Updating Kodi favorites.xml file" >> "$LOGFILE"
  sed -i.bak$DAYOFWEEK "s~$OLD_VALUE~$NEW_VALUE~g" "$FILE_NAME"
fi


#------------------------------------------------------------------
# END MAIN ROUTINE
#------------------------------------------------------------------
echo "$(date)|INFO|Processing complete. Restoring file system separator" >> "$LOGFILE"

# restore IFS
IFS=$OLDIFS

# delete temp files
echo $(date)"|INFO|Deleting lock file: $LOCKFILE" >> $LOGFILE
rm $LOCKFILE

echo "$(date)|INFO|Exiting script" >> "$LOGFILE"
exit
