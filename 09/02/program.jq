#!/usr/bin/env -S jq -R -f

def move_head($direction):
  if $direction == "D" then
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

def move_snake($direction):
  (.snake[0] | move_head($direction)) as $head |
  .snake = [
    $head,
    foreach .snake[1:][] as $part (
      $head;
      if (($part.y - .y) | abs > 1) or (($part.x - .x) | abs > 1) then
        { y: ($part.y + ((.y - $part.y) | sign)),
          x: ($part.x + ((.x - $part.x) | sign)) }
      else
        $part
      end;
      .
    )
  ];

def mark_tail_visited:
  .visited += {"\(.snake[-1].x)x\(.snake[-1].y)": true};

[., inputs] |
  reduce .[] as $cmd (
    {
      visited: {},
      snake: [range(10) | { x: 0, y: 0 }],
    };
    reduce range($cmd[2:]| tonumber) as $_ (
      .;
      move_snake($cmd[0:1]) |
      mark_tail_visited
    )
  ) |
  .visited |
  to_entries |
  length