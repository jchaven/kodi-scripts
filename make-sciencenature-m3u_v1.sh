#!/bin/bash

# NOTE: THIS IS MEANT TO RUN FROM THE KODI DEVICE.
# NOTE: Librelec does not support GNU sort or GNU shuf commands
#       Nor does it appear to support arrays! ugh!

#---------------------------------------------------------------------------------------
# change internal field separator to newline only to allow spaces in name
OLDIFS=$IFS
IFS='
'

# define variables
PLAYLIST="/storage/.kodi/userdata/playlists/video/Science and Nature.m3u"
OUTFILE0="/storage/temp/sciencenature-work.txt"
OUTFILE1="/storage/temp/sciencenature-listing.txt"
OUTFILE2="/storage/temp/sciencenature-random.txt"
LOCKFILE="/storage/temp/make-sciencenature-m3u_v1.lock"
SCRIPT=`basename "$0"`                     # get name of this script
LOG_DATE=$(date +"%Y%m")  # save current date (YYYYMM)
LOGFILE="/storage/temp/make-sciencenature-m3u_v1-$LOG_DATE.log"

#------------------------------------------------------------------
# FUNCTIONS
#------------------------------------------------------------------
GetVideos(){

  # create single list of all videos in specific folders (array not supported)
  #echo "$(date)|INFO|Processing directory: $1" >> "$LOGFILE"
  find -L "$1" -type f \( -iname "*.*" ! -iname "*.srt" ! -iname "*.jpg" ! -iname "*.nfo" ! -iname "*.tbn" ! -iname "*.png" \) >> $OUTFILE0

  # output 10 rows of videos in random order to new file - this is an attempt to get around
  # shows that have few episodes and shows that have many episodes to prevent a playlist that
  # has too many episodes of one particular show.
  echo "$(date)|INFO|Pull 10 random videos from: $1" >> "$LOGFILE"
  awk 'BEGIN{srand(); }
  { a[NR]=$0 }
  END{
    for(i=1; i<=10; i++){
      x=int(rand()*NR) + 1; print a[x];
    }
  }' $OUTFILE0 >> $OUTFILE1

  # Delete work file
  #echo "$(date)|INFO|Deleting work file" >> "$LOGFILE"
  rm $OUTFILE0

}

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

  # create lock file
  echo 'This file should not exist for more than a few minutes.' > "$LOCKFILE"

  # START PROCESSING
  echo "$(date)|INFO|Building a list of all videos in specific directories" >> "$LOGFILE"
  # create single list of all videos in specific folders (array not supported)
#  GetVideos "/storage/nas/media/Other/Science and Nature"

  # Loop through a master directory and process each subdirectory
  SOURCE_DIR="/storage/nas/media/Other/Science and Nature"
  #echo "$(date)|INFO|Processing source directory $SOURCE_DIR" >> "$LOGFILE"
  for dir in $(find $SOURCE_DIR -type d -mindepth 1 -maxdepth 1)
  do
    GetVideos "$dir"
  done

  # get number of lines in outfile
  LINES=$(wc -l < "$OUTFILE1")
  echo "$(date)|INFO|Created list file containing $LINES lines." >> "$LOGFILE"

  # remove duplicate lines - without sorting
  #sort -u -o $OUTFILE1 $OUTFILE1
  awk '!a[$0]++' $OUTFILE1 > $OUTFILE0

  # output 200 rows of videos in random order to new file
  echo "$(date)|INFO|Pull 150 random videos from the list into a new file" >> "$LOGFILE"
  awk 'BEGIN{srand(); }
  { a[NR]=$0 }
  END{
    for(i=1; i<=150; i++){
      x=int(rand()*NR) + 1; print a[x];
    }
  }' $OUTFILE0 > $OUTFILE2


  # output 60 rows from new file to playlist (this will yield ~50 lines after removing duplicates)
  echo "$(date)|INFO|Pull 60 random videos from the new list into the final playlist" >> "$LOGFILE"
  awk 'BEGIN{srand(); }
  { a[NR]=$0 }
  END{
    for(i=1; i<=60; i++){
      x=int(rand()*NR) + 1; print a[x];
    }
  }' $OUTFILE2 > $OUTFILE0

  # remove duplicate lines
  echo "$(date)|INFO|Removing duplicate lines." >> "$LOGFILE"
  awk '!a[$0]++' $OUTFILE0 > $PLAYLIST

  # get number of lines in playlist
  LINES=$(wc -l < "$PLAYLIST")
  echo "$(date)|INFO|Created playlist containing $LINES lines." >> "$LOGFILE"

  # delete temp files
  echo "$(date)|INFO|Deleting temp files" >> "$LOGFILE"
  rm $OUTFILE0
  rm $OUTFILE1
  rm $OUTFILE2

  # delete lockfile
  echo "$(date)|INFO|Deleting lock file" >> "$LOGFILE"
  rm $LOCKFILE

  # END PROCESSING
fi

echo "$(date)|INFO|Processing complete. Restoring file system separator" >> "$LOGFILE"

# restore IFS
IFS=$OLDIFS

echo "$(date)|INFO|Exiting script" >> "$LOGFILE"
exit

