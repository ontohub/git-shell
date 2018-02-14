#!/bin/bash

# Go to the git-shell repository
dir="$(dirname $0)"
cd $dir/..

# Get this path with `rvm $(cat .ruby-version) do rvm env --path`:
source /home/travis/.rvm/environments/ruby-$(cat .ruby-version)

# Replace this process to propagate the exit code
exec bin/git-shell "$@"
