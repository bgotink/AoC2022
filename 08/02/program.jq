#!/usr/bin/env -S jq -R -f

def at($pos):
  .[$pos[0]][$pos[1]];

def out_of_bounds($pos):
  length as $length |
  $pos[0] < 0 or $pos[1] < 0  or $pos[1] >= $length or $pos[0] >= $length;

def count_visible($start; step):
  def _step($pos; $count; $own_height):
    if out_of_bounds($pos) then
      $count
    elif at($pos) >= $own_height then
      $count + 1
    else
      _step($pos | step; $count + 1; $own_height)
    end;
  _step($start | step; 0; at($start));

def score($x; $y):
  count_visible([$x, $y]; .[1] += 1) *
  count_visible([$x, $y]; .[0] += 1) *
  count_visible([$x, $y]; .[1] -= 1) *
  count_visible([$x, $y]; .[0] -= 1);

[., inputs] | map(split("") | map(tonumber)) |
  . as $trees |
  length as $length |
  reduce range(1; $length - 1) as $x (
    map(map(0));
    reduce range(1; $length - 1) as $y (
      .;
      .[$x][$y] = ($trees | score($x; $y))
    )
  ) |
  # (map(join("  ") | debug)) as $debug |
  flatten |
  max
