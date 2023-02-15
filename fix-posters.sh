#!/bin/bash

# Delete all existing Season posters and replace with hard links to poster for TV show.
# Example season poster: season10-poster.jpg

# This script: /mnt/user/Media/admin/scripts/fix-posters.sh 

# NOTE: THIS IS MEANT TO RUN FROM THE NAS. ALL PATHS ARE FROM THE UNRAID
# NAS PERSPECTIVE.

# NOTE: Run chmod 777 on script after saving!

# See site for how to recursively delete and recreate files:
# https://www.baeldung.com/linux/symbolic-and-hard-links
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


function create_posters {
  for f in *;  do
    if [ -d $f  -a ! -h $f ];    
      then      
        cd -- "$f";
        repeat "-" echo \n;
        echo "Variable (f): $f";
        echo "Folder: `pwd`";

        # if folder contains TV continue
        case `pwd` in
          *TV*)
            # if poster.jpg exists continue
            if [ -f "poster.jpg" ]; then
              echo "File poster exists"
              
              ## make copies of poster
              #for i in {01..50}; do cp -l "poster.jpg" "season$i-poster.jpg"; done

              repeat "-" echo \n;

              # for each subdirectory create a poster
              for d in $(find . -type d -maxdepth 1); do
              
                echo "Variable (d): $d";
                
                # remove space from season folder name
                x=$(echo $d | sed "s/ //g")
                echo "Variable (x): $x";

                # remove "./" from season folder name
                x=$(echo $x | sed "s/.\///g")
                echo "Variable (x): $x";

                # create a symlink to poster.jpg for this season
                echo "Season folder name: $x-poster.jpg";
                cp -l "poster.jpg" "${x,,}-poster.jpg";

              done;
              
            fi
            ;;
        esac

        # use recursion to navigate the entire tree
        create_posters;
        cd ..;

    fi;
  done;
};


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

  # create hard links to season posters
  create_posters
  repeat "-" echo \n;

  # delete unwanted posters created above
  echo "Deleting unwanted posters"
  find "$dir" -type f -name '.-poster.jpg' -delete
  find "$dir" -type f -name '.actors-poster.jpg' -delete
  find "$dir" -type f -name 'extrafanart-poster.jpg' -delete


done;
repeat "=" echo \n;

