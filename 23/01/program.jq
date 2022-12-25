#!/usr/bin/env -S jq -R -f

def map_key($y; $x):
  "\($x)x\($y)"
  ;

def read_map:
  . as $grid
  | reduce range($grid | length) as $y (
      {};
      reduce range($grid[$y] | length) as $x (
        .;
        if $grid[$y][$x] == 35 then
          .[map_key($y; $x)] = {
            y: $y,
            x: $x
          }
        else
          .
        end
      )
    )
  | {
      map: .,
      directions: [
        { # North
          move: {y: -1, x: 0},
          check: [{y: -1, x: -1}, {y: -1, x: 0}, {y: -1, x: 1}]
        },
        { # South
          move: {y: 1, x: 0},
          check: [{y: 1, x: -1}, {y: 1, x: 0}, {y: 1, x: 1}]
        },
        { # West
          move: {y: 0, x: -1},
          check: [{y: -1, x: -1}, {y: 0, x: -1}, {y: 1, x: -1}]
        },
        { # East
          move: {y: 0, x: 1},
          check: [{y: -1, x: 1}, {y: 0, x: 1}, {y: 1, x: 1}]
        }
      ],
    }
  ;

def is_available($direction; $location):
  . as $map
  | $direction.check
  | all(
      $map[map_key($location.y + .y; $location.x + .x)] == null
    )
  ;

def propose_coordinates($id; $elf):
  .map as $map
  | reduce .directions[] as $direction (
      { any_free: false, all_free: true, coordinates: $elf };
      if $map | is_available($direction; $elf) then
        if .any_free then
          .
        else
          .any_free = true
          | .coordinates = {
              y: ($elf.y + $direction.move.y),
              x: ($elf.x + $direction.move.x)
            }
        end
      else
        .all_free = false
      end
    )
  | if .all_free then
      $elf
    else
      .coordinates
    end
  ;

def propose_moves:
  reduce (.map | to_entries[]) as {$key, $value} (
    .moves = {};
    propose_coordinates($key; $value) as {$x, $y}
    | map_key($y; $x) as $move_key
    | if .moves[$move_key] != null then
        .moves[$move_key].sources += [$key]
      else
        .moves[$move_key] = { y: $y, x: $x, sources: [$key] }
      end
  )
  | .moves
  ;

def apply_moves($moves):
  .map as $original
  | .map = reduce ($moves | to_entries[]) as {$key, $value} (
    {};
    if $value.sources | length > 1 then
      # clash, go back to original
      # (["cannot move", $value.sources[]] | debug) as $_|
      reduce $value.sources[] as $original_key (
        .;
        .[$original_key] = $original[$original_key]
      )
    else
      # we can move!
      # (["move from", $value.sources[], "to", $key] | debug) as $_|
      .[$key] = { x: $value.x, y: $value.y }
    end
  )
  ;

def round:
  apply_moves(propose_moves)
  | .directions = [.directions[1:][], .directions[0]]
  ;

def empty_ground:
  .map
  | to_entries
  | map(.value.y) as $ys
  | map(.value.x) as $xs
  # | ([($ys | max), ($ys | min),($xs | max), ($xs | min), length] | debug) as $_
  | (($ys | max) - ($ys | min) + 1) * (($xs | max) - ($xs | min) + 1) - length
  ;

[., inputs]
| map(explode)
| reduce range(10) as $_ (read_map; round)
| empty_ground
