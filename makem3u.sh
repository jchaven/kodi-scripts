#!/bin/bash

# NOTE: THIS IS MEANT TO RUN FROM THE NAS. ALL PATHS ARE FROM THE UNRAID
# NAS PERSPECTIVE.

# NOTE: Run chmod 777 on script after saving!

# Note: The number of lines added to the playlist (number of videos played)
# is determined by the FILELIMIT * VIDEOLIMIT + FILELIMIT.
# For example, 80 loops with 3 videos between bumpers = 320
#              (80 * 3 + 80 for the bumpers = 320 total videos including bumpers)
#
# Too many entries in playlist will load slower in XBMC. 300 videos is roughly 20 hours!
#---------------------------------------------------------------------------------------
# change internal field separator to newline only to allow spaces in name
IFS='
'

FILECOUNT=0
ROWCOUNT=0
FILELIMIT=80    # number of loops (see Note above)
VIDEOLIMIT=3    # number of videos to play between bumpers

BUMPERS="/mnt/user/Media/admin/mtv_bumpers.txt"
VIDEOS="/mnt/user/Media/admin/mtv_videos.txt"
LOGFILE="/mnt/user/Media/admin/makem3u.log"
OUTFILE="/tmp/out.txt"
LOCALPATH="/var/media/USB128/Music Videos"
PLAYLIST="/storage/.kodi/userdata/playlists/video/MusicVideos.m3u"

# start
echo $(date) "Start building playlist: $PLAYLIST" > $LOGFILE

# delete old playlist
echo $(date) "Deleting old playlist temp file: $OUTFILE" >> $LOGFILE
rm $OUTFILE

# start creating new playlist
while [  $FILECOUNT -lt $FILELIMIT ]; do

    # get a random bumper and create file
    #shuf -n 1 $BUMPERS >> $OUTFILE
    a=$(shuf -n 1 $BUMPERS)
    echo $(date) "Adding bumper $a" >> $LOGFILE

    # strip-off path
    b=$(basename "$a")
    # append new line with new path to playlist
    echo $LOCALPATH/$b >> $OUTFILE

    # output multiple rows of random videos to file
    # get multiple random lines from file list
    #shuf -n $VIDEOLIMIT $VIDEOS >> $OUTFILE

    # get just filename from file list and prepend player's local path
    while [  $ROWCOUNT -lt $VIDEOLIMIT ]; do
    #for i in {1..$VIDEOLIMIT}
    #do
        # get single random line from file list
        a=$(shuf -n 1 $VIDEOS)
        echo $(date) "Adding music video $a" >> $LOGFILE
        # strip-off path
        b=$(basename "$a")
        echo $LOCALPATH/$b >> $OUTFILE

        # increment file limit counter
        let ROWCOUNT=ROWCOUNT+1

    done
    # reset row counter
    ROWCOUNT=0

    # increment file limit counter
    let FILECOUNT=FILECOUNT+1
done

# copy new playlist to XBMC - /storage/.kodi/userdata/playlists/video
echo $(date) "Copying playlist to XBMC2" >> $LOGFILE
#scp $OUTFILE root@XBMC1:$PLAYLIST
scp $OUTFILE root@XBMC2:$PLAYLIST

echo $(date) "Finished running script. Exiting" >> $LOGFILE
