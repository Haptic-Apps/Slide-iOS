#!/usr/bin/sh

# This shell script requires imagemagick to be installed.

# This is a utility that takes a 1024x1024 png image and turns it into
# the 3 image sizes you need for a community icon submission.

# Usage:
# Suppose you have a 1024x1024 png called icon.png, and you want to make 
# a community icon Called "MyIcon".
# That would be:
# sh ./create-community-icon-images.sh icon.png MyIcon

INPUT_PATH="$1"
NAME=$2

convert $INPUT_PATH -interpolate Nearest -resize 120x120 -density 72 "./ic_$NAME@2x.png"
convert $INPUT_PATH -interpolate Nearest -resize 167x167 -density 72 "ic_$NAME@2x~IPAD.png"
convert $INPUT_PATH -interpolate Nearest -resize 180x180 -density 72 "ic_$NAME@3x.png"