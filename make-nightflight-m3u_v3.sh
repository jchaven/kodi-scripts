#!/bin/bash

# NOTE: THIS IS MEANT TO RUN FROM THE KODI DEVICE.
# NOTE: Librelec does not support GNU sort or GNU shuf commands

# First create a temp file listing all videos in Night Flight directory.
# Then create a playlist from the directory listing pulling random lines.
#
# This script: /storage/nas/media/admin/scripts/make-nightflight-m3u_v3.sh
#---------------------------------------------------------------------------------------
# change internal field separator to newline only to allow spaces in name
OLDIFS=$IFS
IFS='
'

PLAYLIST="/storage/.kodi/userdata/playlists/video/Night Flight.m3u"
VIDEOS="/storage/nas/media/Other/Night Flight"
OUTFILE1="/storage/temp/nightflight-listing.txt"
OUTFILE2="/storage/temp/nightflight-random.txt"
LOCKFILE="/storage/temp/make-nightflight-m3u_v3.lock"
SCRIPT=`basename "$0"`                     # get name of this script
LOG_DATE=$(date +"%Y%m")  # save current date (YYYYMM)
LOGFILE="/storage/temp/make-nightflight-m3u_v3-$LOG_DATE.log"


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
  echo $(date)"|INFO|Using video path: $VIDEOS" >> $LOGFILE

  # create lock file
  echo 'This file should not exist for more than a few minutes.' > "$LOCKFILE"

  # create file listing of all videos (omit base path)
  echo "$(date)|INFO|Getting file names all videos on disk into temp file (OUTFILE1)." >> "$LOGFILE"
  find -L "$VIDEOS" -type f \( -iname "*.*" ! -iname "*.txt" ! -iname "*.srt" ! -iname "*.jpg" ! -iname "*.nfo" ! -iname "*.tbn" \) > $OUTFILE1

  # output 1000 rows of videos in random order to new file
  echo "$(date)|INFO|Pulling 1000 random lines from temp file (OUTFILE1)." >> "$LOGFILE"
  awk -v seed=$RANDOM 'BEGIN{srand(seed); }
  { a[NR]=$0 }
  END{
    for(i=1; i<=1000; i++){
      x=int(rand()*NR) + 1; print a[x];
      }
  }' $OUTFILE1 > $OUTFILE2

  # remove duplicate lines
  echo "$(date)|INFO|Removing duplicate lines." >> "$LOGFILE"
  awk '!a[$0]++' $OUTFILE2 > $OUTFILE1

  # output 150 rows from new file to playlist
  head -n150 $OUTFILE1 > $PLAYLIST

  # get number of lines in playlist
  LINES=$(wc -l < "$PLAYLIST")
  echo "$(date)|INFO|Created playlist containing $LINES lines." >> "$LOGFILE"


  # delete temp files
  echo $(date)"|INFO|Deleting temp files" >> $LOGFILE
  rm $OUTFILE1
  rm $OUTFILE2

  # delete lockfile
  echo $(date)"|INFO|Deleting lock file" >> $LOGFILE
  rm $LOCKFILE

fi

echo "$(date)|INFO|Processing complete. Restoring file system separator" >> "$LOGFILE"

# restore IFS
IFS=$OLDIFS

echo "$(date)|INFO|Exiting script." >> "$LOGFILE"
exit

