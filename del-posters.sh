#!/bin/bash

# Delete all existing Season posters for TV shows.

# This script: /mnt/user/Media/admin/scripts/del-posters.sh

# NOTE: THIS IS MEANT TO RUN FROM THE NAS. ALL PATHS ARE FROM THE UNRAID
# NAS PERSPECTIVE.

#---------------------------------------------------------------------------------------
# change internal field separator to newline only to allow spaces in name
IFS='
'
#shopt -s dotglob
#shopt -s nullglob

# list directories to scan for posters using an array
declare -a MEDIA_DIRS=("/mnt/user/Media/Adam/TV" "/mnt/user/Media/Donna/TV" "/mnt/user/Media/Joey/TV" "/mnt/user/Media/Everyone/TV" "/mnt/disks/temp/TV")
#declare -a MEDIA_DIRS=("/mnt/disks/temp/TV")

# Repeat given char 90 times using shell function
repeat(){
	for i in {1..90}; do echo -n "$1"; done
  echo;
}


# loop through array
for dir in "${MEDIA_DIRS[@]}"; do

  repeat "=" echo \n;
  echo "Processing: $dir";

  # change to media location
  cd "$dir"

  # delete existing season posters
  echo "Deleting existing posters"
#  find "$dir" -type f -iname 'theme.mp3' -delete
  find "$dir" -type f -name 'season*.jpg' -delete
  find "$dir" -type f -name 'Season*.jpg' -delete
  find "$dir" -type f -name 'season*.tbn' -delete
  find "$dir" -type f -name '.-poster.jpg' -delete
  find "$dir" -type f -name '.actors-poster.jpg' -delete
  find "$dir" -type f -name 'extrafanart-poster.jpg' -delete


done;
repeat "=" echo \n;

