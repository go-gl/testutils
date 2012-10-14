#! /usr/bin/env bash

read -r -d '' CODE_HEADER <<H
// Copyright 2012 The go-gl Authors. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

H

wget -q https://raw.github.com/go-gl/testutils/master/imgurbash.sh
chmod u+x imgurbash.sh

# Error log
erl() {
  "$@" &>> error.log
}

check_formatting() {
  if [[ -n "$(go fmt)" ]]
  then
    at "go fmt found problems"
    exit 1
  fi

  if [[ -n "$(go vet)" ]]
  then
    at "go vet found problems"
    exit 1
  fi

  if [[ -n "$(go fix)" ]]
  then
    at "go fix found problems"
    exit 1
  fi

  for f in $(find . -iname "*.go")
  do
    if ! pcregrep -M "$CODE_HEADER" "$f"
    then
      at " -- '$f' is missing license header:"
      echo "$CODE_HEADER"
    fi
  done
}

failure() {
  at "Failure - error log contents:"
  cat error.log
  upload_to_imgur
  exit 1
}

at() {
  echo "--" "$@"
  erl date +%H:%M:%S.%N
}

upload_to_imgur() {
  at "Uploading to imgur"
  for file in *.png
  do
    at "Uploading $file"
    ./imgurbash.sh $file
    echo
  done
}

at "Checking code formatting"
check_formatting

at "Installing eatmydata"
erl sudo apt-get install eatmydata

at "Installing packages"
# eatmydata provides a slight speedup for installing many packages. At one time
# it was significant (when installing the whole of lightdm for example), but
# I'm not sure if it's the case here. It doesn't cost anything, so here it is.
erl sudo eatmydata apt-get install -qq \
  libglfw-dev libglew-dev mesa-utils inotify-tools xserver-xorg

at "Starting X"
erl sudo mkdir -p /tmp/.X11-unix
(sleep 0.5 && sudo X) &>> error.log &

at "Waiting for X to come up"
erl inotifywait -t 4 -r /tmp/.X11-unix

export DISPLAY=:0

at "Running glxgears test"
(glxgears -info &) && sleep 10 && pkill glxgears

at "Fetching package dependencies"
go get -d -v

at "Fetching test dependencies"
go list -f '{{range .TestImports}}{{.}} {{end}}' | xargs go get -d -v

at "Installing test dependencies"
go test -i
