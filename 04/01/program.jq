#!/usr/bin/env -S jq -sR -f

def parse_range:
  split("-") | map(tonumber);

def parse_line:
  split(",") | map(parse_range);

def complete_overlap:
  .[0][0] == .[1][0] or
  if .[0][0] > .[1][0] then
    .[0][1] <= .[1][1]
  else
    .[0][1] >= .[1][1]
  end;

split("\n") | map(select(length > 0) | parse_line | select(complete_overlap)) | length
