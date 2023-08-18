#!/bin/bash

# NOTE: THIS IS MEANT TO RUN FROM THE KODI DEVICE.
# NOTE: Librelec does not support GNU sort or GNU shuf commands

# Note: The number of lines added to the playlist (number of videos played)
# is determined by the FILELIMIT * VIDEOLIMIT + FILELIMIT.
# For example, 80 loops with 3 videos between bumpers = 320
#              (80 * 3 + 80 for the bumpers = 320 total videos including bumpers)
#
# Too many entries in playlist will load slower in XBMC. 300 videos is roughly 20 hours!
#---------------------------------------------------------------------------------------
# change internal field separator to newline only to allow spaces in name
OLDIFS=$IFS
IFS='
'

FILECOUNT=0
ROWCOUNT=0
FILELIMIT=80    # number of loops (see Note above)
VIDEOLIMIT=3    # number of videos to play between bumpers

# file locations (from Kodi perspective)
BUMPER_LIST="/storage/nas/media/admin/mtv_bumpers.txt"
VIDEO_LIST="/storage/nas/media/admin/mtv_videos.txt"
VIDEO_PATH="/storage/nas/media/Everyone/Music Videos"
OUTFILE="/storage/temp/musicvideo-work.txt"
PLAYLIST="/storage/.kodi/userdata/playlists/video/Music Videos.m3u"
LOGFILE="/storage/temp/make-musicvideo-m3u_v2.log"
LOCKFILE="/storage/temp/make-musicvideo-m3u.lock"
SCRIPT=`basename "$0"`                     # get name of this script


#------------------------------------------------------------------
# FUNCTIONS
#------------------------------------------------------------------


#------------------------------------------------------------------
# PROCESS
#------------------------------------------------------------------
echo "$(date)|INFO|Starting script: $SCRIPT" >> "$LOGFILE"

# if lock file exists something is wrong - abort
if [ -f "$LOCKFILE" ]; then
  # lock file exists
  echo "$(date)|ERROR|Lock file exists. Aborting." >> "$LOGFILE"
  exit

else    
  echo "$(date)|INFO|Lock file not found. Continuing." >> "$LOGFILE"
  echo $(date)"|INFO|Start building playlist: $PLAYLIST" >> $LOGFILE
  echo $(date)"|INFO|Using video list: $VIDEO_LIST" >> $LOGFILE
  echo $(date)"|INFO|Using bumper list: $BUMPER_LIST" >> $LOGFILE
  echo $(date)"|INFO|Using video path: $VIDEO_PATH" >> $LOGFILE
  
  # create lock file
  echo 'This file should not exist for more than a few minutes.' >> "$LOCKFILE"

  # delete old playlist
  echo $(date)"|INFO|Deleting old playlist file: $PLAYLIST" >> $LOGFILE
  rm "$PLAYLIST"

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

    # reset row counter
    ROWCOUNT=0

    # increment file limit counter
    let FILECOUNT=FILECOUNT+1

  done

  # Finish up

  # copy outfile to playlist removing lines with "-----" (separater for favorites)
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

fi

echo "$(date)|INFO|Processing complete. Restoring file system separator" >> "$LOGFILE"

# restore IFS
IFS=$OLDIFS

echo "$(date)|INFO|Exiting script" >> "$LOGFILE"
exit
