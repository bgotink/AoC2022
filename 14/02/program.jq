#!/usr/bin/env -S jq -R -f

def read_initial_state:
  def line:
    if .start[0] == .end[0] then
      .start[0] as $x
      | if .start[1] < .end[1] then
          range(.start[1]; .end[1] + 1)
        else
          range(.end[1]; .start[1] + 1)
        end
      | [$x, .]
    else
      .start[1] as $y
      | if .start[0] < .end[0] then
          range(.start[0]; .end[0] + 1)
        else
          range(.end[0]; .start[0] + 1)
        end
      | [., $y]
    end;
  def points:
    split(" -> ")
    | map(split(",") | map(tonumber))
    | .[0] as $first
    | foreach .[1:][] as $point(
        {end: $first};
        {start: .end, end: $point};
        line
      );
  reduce .[] as $line (
    {points: {}, max_y: 0};
    reduce ($line | points) as $point (
      .;
      {
        points: (.points + {"\($point[0])x\($point[1])": "#"}),
        max_y: ([.max_y, $point[1]] | max),
      }
    )
  );

def draw:
  . as $state
  | (.points | keys | map(split("x")[0] | tonumber)) as $xs
  | ($xs | min) as $x_min
  | ($xs | max) as $x_max
  | 0 as $y_min
  | (.max_y + 1) as $y_max
  | ("" | debug) as $_
  | [
      range($y_min; $y_max + 1)
      | . as $y
      | [range($x_min; $x_max + 1)]
      | map(. as $x | $state.points["\($x)x\($y)"] // ".")
      | join("")
      | debug
    ] as $_ | .;

def is_free($x; $y):
  .points["\($x)x\($y)"] == null;

def add_unit:
  def add_unit($x; $y):
    if $y < .max_y + 1 then
      if is_free($x; $y + 1) then
        add_unit($x; $y + 1)
      elif is_free($x - 1; $y + 1) then
        add_unit($x - 1; $y + 1)
      elif is_free($x + 1; $y + 1) then
        add_unit($x + 1; $y + 1)
      else
        .points += {"\($x)x\($y)": "o"}
      end
    else
      .points += {"\($x)x\($y)": "o"}
    end;
  add_unit(500; 0)
  # | draw
  ;

def run_sand:
  .counter = 0
  | until(is_free(500; 0) | not; .counter += 1 | add_unit)
  # | draw
  | .counter;

[., inputs]
| read_initial_state
| run_sand
