#!/usr/bin/env -S jq -R -f

def read_map:
  . as $raw
  | reduce range(1; length - 1) as $y (
      [];
      reduce range(1; $raw[$y] | length - 1) as $x (
        .;
        if $raw[$y][$x] == 46 then # "."
          .
        elif $raw[$y][$x] == 62 then # ">"
          . + [{x: $x, y: $y, dx: 1, dy: 0}]
        elif $raw[$y][$x] == 118 then # "v"
          . + [{x: $x, y: $y, dx: 0, dy: 1}]
        elif $raw[$y][$x] == 60 then # "<"
          . + [{x: $x, y: $y, dx: -1, dy: 0}]
        elif $raw[$y][$x] == 94 then # "^"
          . + [{x: $x, y: $y, dx: 0, dy: -1}]
        else
          "unexpected character \([$raw[$y][$x]] | implode)" | error
        end
      )
    )
  | {
      storms: .,
      start_x: ($raw[0] | index(46)),
      start_y: 0,
      end_x: ($raw[-1] | index(46)),
      end_y: ($raw | length - 1),

      min_storm_x: 1,
      max_storm_x: ($raw[0] | length - 2),
      min_storm_y: 1,
      max_storm_y: ($raw | length - 2),

      raw_map: $raw
    }
  ;

def move_storms:
  . as {
    $min_storm_x,
    $max_storm_x,
    $min_storm_y,
    $max_storm_y
  }
  | .storms |= map(
      .x += .dx
      | .y += .dy
      | if .x < $min_storm_x then
          .x = $max_storm_x
        elif .x > $max_storm_x then
          .x = $min_storm_x
        elif .y < $min_storm_y then
          .y = $max_storm_y
        elif .y > $max_storm_y then
          .y = $min_storm_y
        else
          .
        end
    )
  ;

def move_self($map):
  . as { $x, $y }
  | [
      { x: ($x    ), y: ($y    ) },
      { x: ($x    ), y: ($y - 1) },
      { x: ($x    ), y: ($y + 1) },
      { x: ($x - 1), y: ($y    ) },
      { x: ($x + 1), y: ($y    ) }
    ]
  | map(
      select($map.raw_map[.y][.x] != 35) # filter out "#"
      | select(. as { $x, $y } | $map.storms | all(.x != $x or .y != $y))
    )
  | .[]
  ;

def solve:
  def tick:
    .minute += 1
    | move_storms
    | . as $map
    | .states |= (map(move_self($map)) | unique)
    | ([.minute, (.states | length)] | debug) as $_
    | if .states | any(.x == $map.end_x and .y == $map.end_y) then
        .minute
      else
        tick
      end
      ;
  .states = [{ x: .start_x, y: .start_y }]
  | tick
  ;

[., inputs]
| map(explode)
| read_map
| solve
