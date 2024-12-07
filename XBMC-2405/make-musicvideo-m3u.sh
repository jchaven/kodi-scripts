#!/bin/bash

# NOTE: THIS USES LOCAL CONTENT - NOT NAS CONTENT
# NOTE: THIS IS MEANT TO RUN FROM THE KODI DEVICE.
# NOTE: Librelec does not support GNU sort or GNU shuf commands

# Note: The number of lines added to the playlist (number of videos played)
# is determined by the FILELIMIT * VIDEOLIMIT + FILELIMIT.
# For example, 80 loops with 3 videos between bumpers = 320
#   (80 * 3 + 80 for the bumpers = 320 total videos including bumpers)
#
# Too many entries in playlist will load slower in XBMC. 300 videos is
# roughly 20 hours!
#-------------------------------------------------------------------------------
# change internal field separator to newline only to allow spaces in name
OLDIFS=$IFS
IFS='
'

#------------------------------------------------------------------
# VARIABLES
#------------------------------------------------------------------
SCRIPT=`basename "$0"`      # get name of this script
RUN_DATE=$(date +"%Y%m%d")  # save current date (YYYYMMDD)
FILECOUNT=0
ROWCOUNT=0
FILELIMIT=80                # number of loops (see Note above)
VIDEOLIMIT=3                # number of videos to play between bumpers
MODULONUM=4                 # modulo to pull favorites

# use for alerts
TELEGRAM_TOKEN=$(cat /storage/scripts/TELEGRAM_TOKEN)
TELEGRAM_CHAT_ID=$(cat /storage/scripts/TELEGRAM_CHATID)

# file locations (from Kodi perspective)
LOGFILE="/storage/temp/$SCRIPT-$RUN_DATE.log"
LOCKFILE="/storage/temp/$SCRIPT.lock"
ERRORFILE="/storage/temp/$SCRIPT.error"
BUMPER_LIST="/storage/nas/media/admin/mtv_bumpers.txt"
VIDEO_LIST="/storage/nas/media/admin/mtv_videos.txt"
FAVORITE_LIST="/storage/nas/media/admin/mtv_favorites.txt"
VIDEO_PATH="/storage/videos/mtv"
NAS_PATH="/storage/nas/media/Everyone/Music Videos"
OUTFILE="/storage/temp/musicvideo-work.txt"
PLAYLIST="/storage/.kodi/userdata/playlists/video/Music Videos.m3u"


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

    TELEGRAM_MESSAGE="XBMC-2405: Error creating M3U playlist. Lock file exists."
    curl -s -X POST https://api.telegram.org/bot$TELEGRAM_TOKEN/sendMessage -d chat_id=$TELEGRAM_CHAT_ID -d text="$TELEGRAM_MESSAGE" > /dev/null

  fi
  exit
fi
echo $(date)"|INFO|Lock file not found. Continuing." >> $LOGFILE

# if source files missing (broken mount) abort
if [ ! -f "$VIDEO_LIST" ]; then

  # file does not exist
  echo "$(date)|ERROR|Source files are missing. Aborting." >> "$LOGFILE"

  # write to error file will be used to detect error file existing too long
  echo $(date)" Source files are missing." >> $ERRORFILE

  # get number of lines in error file - if this is first time ignore for now
  LINES=$(wc -l < "$ERRORFILE")
  echo "$(date)|INFO|Error file contains $LINES lines." >> "$LOGFILE"
  if [ $LINES -gt 1 ]; then

    echo $(date)"|INFO|Sending Telegram alert. Continuing." >> $LOGFILE
    TELEGRAM_MESSAGE="XBMC-2405: Error creating M3U playlist. Source files missing."
    curl -s -X POST https://api.telegram.org/bot$TELEGRAM_TOKEN/sendMessage -d chat_id=$TELEGRAM_CHAT_ID -d text="$TELEGRAM_MESSAGE" > /dev/null

  fi
  exit

else

  echo $(date)"|INFO|Source files found. Continuing." >> $LOGFILE
  if [ -f "$ERRORFILE" ]; then
    # issue cleared-up on it's own - delete error file
    echo $(date)"|INFO|Deleting error file: $ERRORFILE" >> $LOGFILE
    rm $ERRORFILE
  fi

fi


# start building playlist
echo $(date)"|INFO|Start building playlist: $PLAYLIST" >> $LOGFILE
echo $(date)"|INFO|Using video list: $VIDEO_LIST" >> $LOGFILE
echo $(date)"|INFO|Using bumper list: $BUMPER_LIST" >> $LOGFILE
echo $(date)"|INFO|Using favorite list: $FAVORITE_LIST" >> $LOGFILE
echo $(date)"|INFO|Using video path: $VIDEO_PATH" >> $LOGFILE

# create lock file
echo $(date)" This file should not exist for more than a few minutes." >> $LOCKFILE

# count number of files in video path
FILE_COUNT=$(ls -1 "$VIDEO_PATH" | wc -l)
echo $(date)"|INFO|Number of files in local folder: $FILE_COUNT" >> $LOGFILE

# copying new files from NAS to local disk
echo $(date)"|INFO|Copying new files from NAS to: $VIDEO_PATH" >> $LOGFILE
cp -u "$NAS_PATH"/* $VIDEO_PATH

# count number of files in video path
FILE_COUNT=$(ls -1 "$VIDEO_PATH" | wc -l)
echo $(date)"|INFO|Number of files in local folder: $FILE_COUNT" >> $LOGFILE

# start creating new playlist
while [  $FILECOUNT -lt $FILELIMIT ]; do
  #echo $(date)"|INFO|File count: "$FILECOUNT >> $LOGFILE

  # get a single random bumper and create file
  #shuf -n 1 $BUMPERS >> $OUTFILE
  #a=$(shuf -n 1 $BUMPERS)
  # "shuf" not supported in LibreElec - use awk
  a=$(awk -v seed=$RANDOM '
  BEGIN{ srand(seed) }
  rand() * NR < 1 {
      line = $0
  }
  END { print line }' $BUMPER_LIST)

  # add entry to playlist
  echo $(date)"|INFO|Adding bumper: $a" >> $LOGFILE
  echo $VIDEO_PATH/$a >> $OUTFILE


  # get multiple random lines from file list
  #shuf -n $VIDEOLIMIT $VIDEOS >> $OUTFILE
  # "shuf" not supported in LibreElec - use awk 3x in while loop
  while [  $ROWCOUNT -lt $VIDEOLIMIT ]; do
  #echo $(date)"|INFO|Row count: "$ROWCOUNT >> $LOGFILE
  #for i in {1..$VIDEOLIMIT}
  #do
      # get single random line from file list
      a=$(awk -v seed=$RANDOM '
      BEGIN{ srand(seed) }
      rand() * NR < 1 {
          line = $0
      }
      END { print line }' $VIDEO_LIST)

      # add entry to playlist
      echo $(date)"|INFO|Adding music video: $a" >> $LOGFILE
      echo $VIDEO_PATH/$a >> $OUTFILE

      # increment file limit counter
      let ROWCOUNT=ROWCOUNT+1

  done

  # pull video from favorites list
  if [ $((FILECOUNT % MODULONUM)) -eq 0 ]; then

      # get single random line from file list
      a=$(awk -v seed=$RANDOM '
      BEGIN{ srand(seed) }
      rand() * NR < 1 {
          line = $0
      }
      END { print line }' $FAVORITE_LIST)

      # add entry to playlist
      echo $(date)"|INFO|Adding favorite video: $a" >> $LOGFILE
      echo $VIDEO_PATH/$a >> $OUTFILE

  fi

  # reset row counter
  ROWCOUNT=0

  # increment file limit counter
  let FILECOUNT=FILECOUNT+1

done

# Finish up

# delete old playlist
echo $(date)"|INFO|Deleting old playlist file: $PLAYLIST" >> $LOGFILE
rm "$PLAYLIST"

# copy outfile to playlist removing lines with "-----" (separator for favorites)
echo $(date)"|INFO|Copying outfile to playlist" >> $LOGFILE
sed '/---/d' $OUTFILE > $PLAYLIST

# get number of lines in playlist
LINES=$(wc -l < "$PLAYLIST")
echo "$(date)|INFO|Created playlist containing $LINES lines." >> "$LOGFILE"

# delete temp files
echo $(date)"|INFO|Deleting temp file: $OUTFILE" >> $LOGFILE
rm $OUTFILE
echo $(date)"|INFO|Deleting lock file: $LOCKFILE" >> $LOGFILE
rm $LOCKFILE

echo "$(date)|INFO|Processing complete. Restoring file system separator" >> "$LOGFILE"

# restore IFS
IFS=$OLDIFS

echo "$(date)|INFO|Exiting script" >> "$LOGFILE"
exit
