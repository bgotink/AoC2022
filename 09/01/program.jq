#!/usr/bin/env -S jq -R -f

def move_head($direction):
  .head |= if $direction == "D" then
    .y -= 1
  elif $direction == "U" then
    .y += 1
  elif $direction == "L" then
    .x -= 1
  else # $direction == "R" then
    .x += 1
  end;

def abs:
  if . < 0 then . * -1 else . end;

def sign:
  if . < 0 then
    -1
  elif . > 0 then
    1
  else
    0
  end;

def move_tail:
  if ((.tail.y - .head.y) | abs > 1) or ((.tail.x - .head.x) | abs > 1) then
    .tail.y += ((.head.y - .tail.y) | sign) |
    .tail.x += ((.head.x - .tail.x) | sign)
  else
    .
  end;

def mark_tail_visited:
  .visited += {"\(.tail.x)x\(.tail.y)": true};

[., inputs] |
  reduce .[] as $cmd (
    {
      visited: {},
      head: {
        x: 0,
        y: 0,
      },
      tail: {
        x: 0,
        y: 0,
      }
    };
    reduce range($cmd[2:]| tonumber) as $_ (
      .;
      move_head($cmd[0:1]) |
      move_tail |
      mark_tail_visited
    )
  ) |
  .visited |
  to_entries |
  length