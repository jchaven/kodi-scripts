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
VIDEO_PATH="/var/media/USB128/Music Videos"

LOGFILE="/storage/temp/make-musicvideo-m3u.log"
OUTFILE="/storage/temp/out.txt"
LOCKFILE="/storage/temp/make-musicvideo-m3u.lock"
PLAYLIST="/storage/.kodi/userdata/playlists/video/MusicVideos.m3u"

#------------------------------------------------------------------
# FUNCTIONS
#------------------------------------------------------------------
GetBumper(){
  $(awk '
    BEGIN{ srand() } 
    rand() * NR < 1 { 
        line = $0 
    } 
    END { print line }' $BUMPERS)

}

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
    #shuf -n 1 $BUMPERS >> $OUTFILE
    #a=$(shuf -n 1 $BUMPERS)

    # "shuf" not supported in LibreElec - use awk
    a=$(awk '
    BEGIN{ srand() } 
    rand() * NR < 1 { 
        line = $0 
    } 
    END { print line }' $BUMPERS)

    # check if file exists
    f="$VIDEO_PATH/$a"
    if [ -e "$f" ]; then

        # add entry to playlist
        echo $(date)"|INFO|Adding bumper $a" >> $LOGFILE

        # append new line with new path to playlist
        echo $f >> $OUTFILE
    else
        echo $(date)"|ERROR|File not found: $f" >> $LOGFILE
    fi


    # output multiple rows of random videos to file
    # get multiple random lines from file list
    #shuf -n $VIDEOLIMIT $VIDEOS >> $OUTFILE

    # get just filename from file list and prepend player's local path
    while [  $ROWCOUNT -lt $VIDEOLIMIT ]; do
    #for i in {1..$VIDEOLIMIT}
    #do
        # get single random line from file list
        a=$(shuf -n 1 $VIDEOS)

        # strip-off path
        b=$(basename "$a")

        # check if file exists
        f="$NASPATH/$b"
        if [ -e "$f" ]; then

            # add entry to playlist
            echo $(date)"|INFO|Adding music video $a" >> $LOGFILE
            echo $LOCALPATH/$b >> $OUTFILE

        else
            echo $(date)"|ERROR|File not found: $f" >> $LOGFILE
        fi

        # increment file limit counter
        let ROWCOUNT=ROWCOUNT+1

    done
    # reset row counter
    ROWCOUNT=0

    # increment file limit counter
    let FILECOUNT=FILECOUNT+1
done

# copy new playlist to XBMC - /storage/.kodi/userdata/playlists/video
echo $(date)"|INFO|Copying playlist to XBMC2" >> $LOGFILE
cp $OUTFILE $PLAYLIST

# delete temp file
echo $(date)"|INFO|Deleting temp file: $OUTFILE" >> $LOGFILE
rm $OUTFILE

# restore IFS
IFS=$OLDIFS

echo "$(date)|INFO|Finished running script. Exiting" >> "$LOGFILE"
exit




