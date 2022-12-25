#!/usr/bin/env -S jq -sR -f

def priority:
  if . >= 97 then # "a" = 97
    . + 1 - 97
  else
    . + 27 - 65 # "A" = 65
  end;

def group_by_three:
  if length == 0 then
    []
  else
    [.[0:3], (.[3:] | group_by_three[])]
  end;

def is_in($arr):
  . as $el |
  $arr | bsearch($el) > -1;

def mutual:
  (.[0]) as $first |
  (.[1]) as $second |
  .[2][] |
  select(is_in($first) and is_in($second));


split("\n") | map(select(length > 0) | explode | unique) |
  group_by_three |
  map(mutual | priority) |
  add