#!/bin/bash
#
# COPY NAS BACKUP
#
# The Unraid server uses the Appdata Backup plugin to backup all containers,
# plugin data, and the flash drive. The backup for NAS3 is currently scheduled
# to run on Wednesdays at 3:10 AM.
#
# This script will copy only the latest backup to this device. This should avoid
# having to download a backup from High Point if the flash drive fails in the
# Unraid server here. If this script fails to copy the latest backup there will
# be no backup on this device. This is an acceptable risk.
#
# Example directory name for backup: ab_20250329_030501
#
# Note: SSH keys need to be exchanged first
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
# 30   0      *    *   Thursday  /storage/scripts/copy-NAS-backup.sh
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

# If Thursday (4) run
if [ $DAYOFWEEK -eq 4 ]; then

  # Delete local backup(s) - only need one (the latest) saved locally
  rm -r /storage/backup/ab_*/

  # Get filename of newest directory on remote host and save to variable
  DIR=$(ssh root@haven-nas3.local ls -tr1 /mnt/user/Backups/Unraid/NAS3/ | tail -1)

  # Copy file from remote host using variable
  scp -r root@haven-nas3.local:/mnt/user/Backups/Unraid/NAS3/$DIR/ /storage/backup/

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
