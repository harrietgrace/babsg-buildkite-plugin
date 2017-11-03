#!/bin/bash

# BKBH Deprecation Warning
#
# Really looking forward to writing a new function to safely deprecate this one
while [ "$1" ]; do
  echo "--- :rage1:"
  echo "---  :rage2:"
  echo "---   :rage3:"
  echo "---    :rage4:"
  echo "---     <<DEPRECATION WARNING>>"
  echo "---     $1"
  echo "---    :rage4:"
  echo "---   :rage3:"
  echo "---  :rage2:"
  echo "--- :rage1:"
  shift
done
