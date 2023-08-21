
LibreElec uses a stripped-down version of Linux and uses Busybox for many commands.

For this reason several commands take for granted on full-fledged Linux systems.

Missing Command       Work-around
--------------------  ---------------------------------------------------
shuf                  Use awk - query $RANDOM to get a random seed
sort                  Use awk
savelog               Manually rotate logs with bash script



There is also no support for arrays in bash scripts.


