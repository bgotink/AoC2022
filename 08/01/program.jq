#!/usr/bin/env -S jq -R -f

def at($pos):
  .[$pos[0]][$pos[1]];

def modify_at($pos; mod):
  .[$pos[0]][$pos[1]] |= mod;

def mark_visible($trees; $start; step):
  def _step($pos; $previous_val):
    ($trees | at($pos)) as $val |
    if $val <= $previous_val then
      .
    else
      .[$pos[0]][$pos[1]] |= 1
    end |
    ($pos | step) as $next_pos |
    if at($next_pos) == null then
      .
    else
      _step($next_pos; [$val, $previous_val] | max)
    end;
  _step($start; -1);

[., inputs] | map(split("") | map(tonumber)) |
  . as $trees |
  length as $length |
  reduce range($length) as $a (
    map(map(0));
    mark_visible($trees; [$a, 0]; .[1] += 1) |
    mark_visible($trees; [0, $a]; .[0] += 1) |
    mark_visible($trees; [$a, $length - 1]; .[1] -= 1) |
    mark_visible($trees; [$length - 1, $a]; .[0] -= 1)
  ) |
  (map(join("") | debug)) as $debug |
  flatten | map(select(. == 1)) | length