#!/usr/bin/env -S jq -sR -f

def parse_range:
  split("-") | map(tonumber);

def parse_line:
  split(",") | map(parse_range);

def distinct:
  # Two ranges are distinct if end1 < start2 || start1 > end2
  (.[0][1] < .[1][0]) or (.[0][0] > .[1][1]);

split("\n") | map(select(length > 0) | parse_line | select(distinct | not)) | length
