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
PLAYLIST="/storage/.kodi/userdata/playlists/video/Documentary.m3u"
OUTFILE0="/storage/temp/documentary-work.txt"
OUTFILE1="/storage/temp/documentary-listing.txt"
OUTFILE2="/storage/temp/documentary-random.txt"
LOCKFILE="/storage/temp/make-documentary-m3u_v1.lock"
SCRIPT=`basename "$0"`                     # get name of this script
LOG_DATE=$(date +"%Y%m")  # save current date (YYYYMM)
LOGFILE="/storage/temp/make-documentary-m3u_v1-$LOG_DATE.log"


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
  #echo "$(date)|INFO|Pull 20 random videos from work file and add to list file" >> "$LOGFILE"
  awk 'BEGIN{srand(); }
  { a[NR]=$0 }
  END{
    for(i=1; i<=20; i++){
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
  GetVideos "/storage/nas/media/Other/Science and Nature/Through the Wormhole"
  GetVideos "/storage/nas/media/Other/Science and Nature/Wonders of the Solar System"
  GetVideos "/storage/nas/media/Other/Science and Nature/The Universe"
  GetVideos "/storage/nas/media/Other/Science and Nature/The Secret Life of Machines"
  GetVideos "/storage/nas/media/Other/Science and Nature/The Nature of Things"
  GetVideos "/storage/nas/media/Other/Science and Nature/The Great Rift Africa's Wild Heart"
  GetVideos "/storage/nas/media/Other/Science and Nature/The Elegant Universe"
  GetVideos "/storage/nas/media/Other/Science and Nature/NOVA"
  GetVideos "/storage/nas/media/Other/Science and Nature/Nature"
  GetVideos "/storage/nas/media/Other/Science and Nature/National Geographic"
  GetVideos "/storage/nas/media/Other/Science and Nature/Earth at Night in Color"
  GetVideos "/storage/nas/media/Other/Science and Nature/Cosmos A Space-Time Odyssey"
  GetVideos "/storage/nas/media/Other/Science and Nature/Cosmos"
  GetVideos "/storage/nas/media/Other/Science and Nature/Bill Nye The Science Guy"
  GetVideos "/storage/nas/media/Other/Science and Nature/Africa"
  GetVideos "/storage/nas/media/Other/Science and Nature/Alien Worlds"
  GetVideos "/storage/nas/media/Other/Science and Nature/Big Cats"
  GetVideos "/storage/nas/media/Other/Science and Nature/Earth from Space"
  GetVideos "/storage/nas/media/Other/Science and Nature/Frozen Planet"
  GetVideos "/storage/nas/media/Other/Science and Nature/Years of Living Dangerously"
  GetVideos "/storage/nas/media/Other/Science and Nature/Wild China"
  GetVideos "/storage/nas/media/Other/Science and Nature/The Story of God with Morgan Freeman"
  GetVideos "/storage/nas/temp/Other/Current Events/Dateline SBS"
  GetVideos "/storage/nas/media/Other/Current Events/Catalyst"
  GetVideos "/storage/nas/media/Other/Current Events/Four Corners"
  GetVideos "/storage/nas/media/Other/Current Events/Frontline"
  GetVideos "/storage/nas/media/Other/Current Events/Panorama"
  GetVideos "/storage/nas/media/Other/Current Events/POV"
  GetVideos "/storage/nas/media/Other/Current Events/This World"
  GetVideos "/storage/nas/media/Other/History/The Day The Universe Changed"
  GetVideos "/storage/nas/media/Other/History/American Experience"
  GetVideos "/storage/nas/media/Other/History/Secrets of the Dead"
  GetVideos "/storage/nas/media/Other/History/Chris Tarrant Extreme Railways"
  GetVideos "/storage/nas/media/Other/History/Tough Trains"
  GetVideos "/storage/nas/media/Other/Food and Travel/Off Limits"
  GetVideos "/storage/nas/media/Other/Food and Travel/The Americas with Simon Reeve"
  GetVideos "/storage/nas/media/Other/Food and Travel/The Layover"
  GetVideos "/storage/nas/media/Other/Food and Travel/Tropic Of Cancer"
  GetVideos "/storage/nas/media/Other/Food and Travel/Anthony Bourdain No Reservations"
  GetVideos "/storage/nas/media/Other/Food and Travel/Anthony Bourdain Parts Unknown"

  # remove duplicate lines - without sorting
  #sort -u -o $OUTFILE1 $OUTFILE1
  awk '!a[$0]++' $OUTFILE1 > $OUTFILE0
  
  # output 150 rows of videos in random order to new file
  echo "$(date)|INFO|Pull 150 random videos from the list into a new file" >> "$LOGFILE"
  awk 'BEGIN{srand(); }
  { a[NR]=$0 }
  END{
    for(i=1; i<=150; i++){
      x=int(rand()*NR) + 1; print a[x];
    }
  }' $OUTFILE0 > $OUTFILE2


  # output 30 rows from new file to playlist
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
