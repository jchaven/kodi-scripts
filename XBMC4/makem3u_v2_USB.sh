#!/bin/bash

# NOTE: THIS IS MEANT TO RUN ON LAPTOP.
# NOTE: This is a temporary solution to slow-loading videos on XBMC4.
#       Select music videos are stored on a USB drive in XBMC4. 

# Note: The number of lines added to the playlist (number of videos played)
# is determined by the FILELIMIT * VIDEOLIMIT + FILELIMIT.
# For example, 80 loops with 3 videos between bumpers = 320
#              (80 * 3 + 80 for the bumpers = 320 total videos including bumpers)
#
# Too many entries in playlist will load slower in XBMC. 300 videos is roughly 20 hours!
#
# Run from via cron:
# ---------- copy ----------
# Create new MTV playlist and copy to XBMC4 at minute 1 past every 2nd hour
# 1 */2 * * * /home/joey/Scripts/USB128/makem3u_v2_USB.sh 1> /dev/null
# ---------- copy ----------
#
#
#---------------------------------------------------------------------------------------
# change internal field separator to newline only to allow spaces in name
OLDIFS=$IFS
IFS='
'

FILECOUNT=0
ROWCOUNT=0
FILELIMIT=80    # number of loops (see Note above)
VIDEOLIMIT=3    # number of videos to play between bumpers

VIDEO_PATH="/var/media/USB128/Music Videos"
SCRIPT_PATH="/home/joey/Scripts/USB128"

# file locations
BUMPER_LIST="$SCRIPT_PATH/bumpers.txt"            # List of MTV bumpers on USB stick
VIDEO_LIST="$SCRIPT_PATH/videos.txt"              # List of all music videos on USB stick
SCRIPT_LOG="/home/joey/script.log"                # main system script log
LOGFILE="$SCRIPT_PATH/make-musicvideo-m3u.log"    # log specific to this script
OUTFILE="$SCRIPT_PATH/temp_out.txt"
LOCKFILE="$SCRIPT_PATH/make-musicvideo-m3u.lock"
PLAYLIST="$SCRIPT_PATH/Music Videos.m3u"

SCRIPT=`basename "$0"`                     # get name of this script

echo --------------------------------------------------------------------------  | tee -a "$SCRIPT_LOG"
echo "Executing script: $SCRIPT" | tee -a "$SCRIPT_LOG"


#------------------------------------------------------------------
# FUNCTIONS
#------------------------------------------------------------------

#------------------------------------------------------------------
# START
#------------------------------------------------------------------
echo $(date)"|INFO|Start building playlist: $PLAYLIST" > $LOGFILE

# if lock file exists something is wrong - abort
if [ -f "$LOCKFILE" ]; then
  # lock file exists
  echo "$(date)|ERROR|Lock file exists. Aborting." >> "$LOGFILE"
  exit

else    
  echo "$(date)|INFO|Lock file not found. Continuing." >> "$LOGFILE"
  
  # create lock file
  echo 'This file should not exist for more than a few minutes.' > "$LOCKFILE"

  # start creating new playlist
  while [  $FILECOUNT -lt $FILELIMIT ]; do

    # get a random bumper and create file
    echo "$(date)|INFO|Adding 1 bumper to outfile" >> "$LOGFILE"
    shuf -n 1 $BUMPER_LIST >> $OUTFILE

    # output multiple rows of random videos to file
    # get multiple random lines from file list
    echo "$(date)|INFO|Adding $VIDEOLIMIT videos to outfile" >> "$LOGFILE"
    shuf -n $VIDEOLIMIT $VIDEO_LIST >> $OUTFILE

    # reset row counter
    echo "$(date)|INFO|Resetting row counter" >> "$LOGFILE"
    ROWCOUNT=0

    # increment file limit counter
    echo "$(date)|INFO|Incrementing file counter" >> "$LOGFILE"
    let FILECOUNT=FILECOUNT+1
  done

fi

# copy new playlist to XBMC - /storage/.kodi/userdata/playlists/video
echo $(date)"|INFO|Copying playlist to XBMC4.local" >> $LOGFILE
scp $PLAYLIST root@xbmc4.local:/storage/.kodi/userdata/playlists/video/


# delete temp files
echo $(date)"|INFO|Deleting temp file: $OUTFILE" >> $LOGFILE
rm $OUTFILE
echo $(date)"|INFO|Deleting lock file: $LOCKFILE" >> $LOGFILE
rm $LOCKFILE

# restore IFS
IFS=$OLDIFS

echo "$(date)|INFO|Finished running script. Exiting" >> "$LOGFILE"

echo "Script completed: `date`" | tee -a "$SCRIPT_LOG"
exit
