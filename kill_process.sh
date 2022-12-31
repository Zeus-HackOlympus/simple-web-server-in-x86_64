#!/usr/bin/env sh

######################################################################
# @author      : HackOlympus (zeus@hackolympus)
# @file        : kill_process
# @created     : Monday Dec 26, 2022 06:57:45 MST
#
# @description : 
######################################################################

sudo kill $(sudo lsof -i:80 | awk '{if (NR==2) print $2}')


