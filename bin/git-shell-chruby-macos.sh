#!/bin/bash

source /usr/local/opt/chruby/share/chruby/chruby.sh
source /usr/local/opt/chruby/share/chruby/auto.sh

# Go to the git-shell repository
dir="$(dirname $0)"
cd $dir/..

# Replace this process to propagate the exit code
exec bundle exec bin/git-shell "$@"
