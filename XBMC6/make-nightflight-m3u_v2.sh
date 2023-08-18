#!/bin/bash

# NOTE: THIS IS MEANT TO RUN FROM THE NAS. ALL PATHS ARE FROM THE UNRAID
# NAS PERSPECTIVE.

# NOTE: Run chmod 777 on script after saving!

# First create a temp file listing all videos in Night Flight directory.
# Then create a playlist from the directory listing pulling random lines.
#
# This script: /mnt/user/Media/admin/scripts/make-nightflight-m3u.sh 
#---------------------------------------------------------------------------------------
# change internal field separator to newline only to allow spaces in name
IFS='
'

NAS1DIR="/usb/drive1/Night Flight/"
XBMCDIR="/storage/nas/media/Other/Night Flight/"
VIDEOS="/mnt/user/Media/Other/Night Flight"
OUTFILE1="/root/nightflight-temp.txt"
OUTFILE2="/root/nightflight.txt"
PLAYLIST="/storage/.kodi/userdata/playlists/video/nightflight.m3u"
VIDEOLIMIT=75    # number of videos to play

# delete old playlist
rm $OUTFILE1

# create file listing of all videos (omit base path)
find -L "$VIDEOS" -type f \( -iname "*.*" ! -iname "*.srt" ! -iname "*.jpg" ! -iname "*.nfo" ! -iname "*.tbn" \) | cut --complement -c 1-35 > $OUTFILE1

# output multiple rows of random videos to file
shuf -n $VIDEOLIMIT $OUTFILE1 > $OUTFILE2

# add XBMCDIR to the entries (use # instead of /)
sed -i -e "s#^#$XBMCDIR#" $OUTFILE2

# copy new playlist to XBMC - /storage/.kodi/userdata/playlists/video
#scp $OUTFILE2 root@XBMC1:$PLAYLIST
scp $OUTFILE2 root@XBMC3:$PLAYLIST


