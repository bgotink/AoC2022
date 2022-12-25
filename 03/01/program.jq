#!/usr/bin/env -S jq -sR -f

def priority:
  if . >= 97 then # "a" = 97
    . + 1 - 97
  else
    . + 27 - 65 # "A" = 65
  end;

def mutual:
  explode |
  length as $length |
  (.[($length / 2):] | unique) as $other_pack |
  .[0:($length / 2)] | unique | .[] |
  select(. as $inp | $other_pack | bsearch($inp) > -1);

split("\n") | map(select(length > 0) | mutual | priority) | add
