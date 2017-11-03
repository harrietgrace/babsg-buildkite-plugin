#!/bin/bash

# BKBH Deprecation Warning
#
# Really looking forward to writing a new function to safely deprecate this one
while [ "$1" ]; do
  cat <<WARN
--- :rage1:
---  :rage2:
---   :rage3:
---    :rage4:
---     <<DEPRECATION WARNING>>
---     $1
---    :rage4:
---   :rage3:
---  :rage2:
--- :rage1:
WARN
  shift
done
