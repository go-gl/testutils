#! /usr/bin/env bash

wget -q https://raw.github.com/go-gl/testutils/master/imgurbash.sh
chmod u+x imgurbash.sh

# Error log
erl() {
  "$@" &>> error.log
}

failure() {
  at "Failure"
  at "Error log contents:"
  cat error.log
  upload_to_imgur
}

at() {
  echo "--" "$@"
  erl date +%H:%M:%S.%N
}

upload_to_imgur() {
  at "Uploading to imgur"
  for file in *.png;
  do
    at "Uploading $file"
    ./imgurbash.sh $file
    echo
  done
}

at "Installing eatmydata"
erl sudo apt-get install eatmydata

at "Installing packages"
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
