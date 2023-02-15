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
PLAYLIST="/storage/.kodi/userdata/playlists/video/Home and Garden.m3u"
OUTFILE0="/storage/temp/homegarden-work.txt"
OUTFILE1="/storage/temp/homegarden-listing.txt"
OUTFILE2="/storage/temp/homegarden-random.txt"
LOGFILE="/storage/temp/make-homegarden-m3u_v1.log"
LOCKFILE="/storage/temp/make-homegarden-m3u_v1.lock"
SCRIPT=`basename "$0"`                     # get name of this script

#------------------------------------------------------------------
# FUNCTIONS
#------------------------------------------------------------------
GetVideos(){

  # create single list of all videos in specific folders (array not supported)
  echo "$(date)|INFO|Processing directory: $1" >> "$LOGFILE"
  find -L "$1" -type f \( -iname "*.*" ! -iname "*.srt" ! -iname "*.jpg" ! -iname "*.nfo" ! -iname "*.tbn" ! -iname "*.png" \) >> $OUTFILE0

  # output 20 rows of videos in random order to new file - this is an attempt to get around
  # shows that have few episodes and shows that have many episodes to prevent a playlist that
  # has too many episodes of one particular show.
  echo "$(date)|INFO|Pull 20 random videos from work file and add to list file" >> "$LOGFILE"
  awk 'BEGIN{srand(); }
  { a[NR]=$0 }
  END{
    for(i=1; i<=20; i++){
      x=int(rand()*NR) + 1; print a[x];
    }
  }' $OUTFILE0 >> $OUTFILE1

  # Delete work file
  echo "$(date)|INFO|Deleting work file" >> "$LOGFILE"
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
  GetVideos "/storage/nas/temp/TV/Grand Designs"
  GetVideos "/storage/nas/temp/TV/Grand Designs New Zealand"
  GetVideos "/storage/nas/temp/TV/Tiny House Nation"
  GetVideos "/storage/nas/media/Other/Home and Garden/Big Dreams Small Spaces"
  GetVideos "/storage/nas/media/Other/Home and Garden/Gardeners' World"
  GetVideos "/storage/nas/media/Other/Home and Garden/Grow Your Own at Home with Alan Titchmarsh"
  GetVideos "/storage/nas/media/Other/Home and Garden/Love Your Garden"
  GetVideos "/storage/nas/media/Other/Home and Garden/Love Your Home and Garden"
  GetVideos "/storage/nas/media/Other/Home and Garden/This Old House"

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


  # output 50 rows from new file to playlist
  echo "$(date)|INFO|Pull 50 random videos from the new list into the final playlist" >> "$LOGFILE"
  awk 'BEGIN{srand(); }
  { a[NR]=$0 }
  END{
    for(i=1; i<=50; i++){
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
