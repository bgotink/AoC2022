#!/bin/bash

set -e

cd "$(dirname "$0")"

input_filename="input.dat"

folder=

while [ $# -gt 0 ]; do
  case "$1" in
    -n|--name)
      input_filename="$2"
      shift
      ;;
    -e|--example)
      input_filename="test.dat"
      ;;
    *)
      folder="$folder/$1"
      ;;
  esac
  shift
done

if [ -z $folder ]; then
  echo "Usage: run.sh [--example, -e] <day> [part]" >&2
  echo "" >&2
  echo "Options:" >&2
  echo "  --example, -e         Use the example data given in the exercise description" >&2
  echo "" >&2
  echo "Examples:" >&2
  echo "  run.sh 01 01" >&2
  echo "  run.sh 24" >&2
  exit 1
fi

folder="${folder:1}"

if ! [ -f "$folder/$input_filename" ]; then
  echo "Can't find $input_filename in $folder" >&2
  exit 1
fi

if test -f "$folder/program.rs"; then
  if ! command -v cargo >/dev/null 2>&1; then 
    echo "Couldn't find cargo, visit https://doc.rust-lang.org/cargo/getting-started/installation.html and install the software" >&2
    exit 1
  fi

  cargo run -r --bin "${folder//\//-}" "$folder/$input_filename"
elif test -f "$folder/program.jq"; then
  if ! command -v jq >/dev/null 2>&1; then 
    echo "Couldn't find jq, visit https://stedolan.github.io/jq/ and install the software" >&2
    exit 1
  fi
  "$folder/program.jq" "$folder/$input_filename"
fi
