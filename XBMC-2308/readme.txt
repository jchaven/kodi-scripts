
LibreElec uses a stripped-down version of Linux and uses Busybox for many commands.

For this reason several commands taken for granted on full-fledged Linux systems require
weird and complex work-arounds.

Missing Command       Work-around
--------------------  ---------------------------------------------------
shuf                  Use awk - query $RANDOM to get a random seed
sort                  Use awk
savelog               Manually rotate logs with bash script
rsync                 Use cp and scp


There is also no support for arrays in bash scripts.

Cannot use "<" to read text files. Must use "cat" command.
Example: TELEGRAM_CHAT_ID=$(cat TELEGRAM_CHATID)



