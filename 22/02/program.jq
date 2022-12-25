#!/usr/bin/env -S jq -R -f

def parse_instructions:
  gsub("(?<turn>L|R)"; "_\(.turn)_")
  | split("_")
  ;

def parse_state:
  split("\n") | map(explode)
  | length as $max_y
  | (map(length) | max) as $max_x
  | ([$max_y, $max_x] | min / 3) as $cube_size
  | {
      lines: .,
      cube_size: $cube_size,
      # We need to follow the cube. There are two patterns:
      #
      #          12
      #   1      3
      # 234     45
      #   56    6
      #
      # We can differentiate between the two based on the size, as the first
      # pattern is the example and the second is the actual input
      cube: (if $cube_size == 50 then
              {
                "1": {
                  y: 0,
                  x: $cube_size,
                  connections: {
                    right: ["2", "left"],
                    down:  ["3", "up"],
                    left:  ["4", "left"],
                    up:    ["6", "left"]
                  }
                },
                "2": {
                  y: 0,
                  x: (2 * $cube_size),
                  connections: {
                    right: ["5", "right"],
                    down:  ["3", "right"],
                    left:  ["1", "right"],
                    up:    ["6", "down"]
                  }
                },
                "3": {
                  y: $cube_size,
                  x: $cube_size,
                  connections: {
                    right: ["2", "down"],
                    down:  ["5", "up"],
                    left:  ["4", "up"],
                    up:    ["1", "down"]
                  }
                },
                "4": {
                  y: (2 * $cube_size),
                  x: 0,
                  connections: {
                    right: ["5", "left"],
                    down:  ["6", "up"],
                    left:  ["1", "left"],
                    up:    ["3", "left"]
                  }
                },
                "5": {
                  y: (2 * $cube_size),
                  x: $cube_size,
                  connections: {
                    right: ["2", "right"],
                    down:  ["6", "right"],
                    left:  ["4", "right"],
                    up:    ["3", "down"]
                  }
                },
                "6": {
                  y: (3 * $cube_size),
                  x: 0,
                  connections: {
                    right: ["5", "down"],
                    down:  ["2", "up"],
                    left:  ["1", "up"],
                    up:    ["4", "down"]
                  }
                }
              }
            else
              {
                "1": {
                  y: 0,
                  x: (2 * $cube_size),
                  connections: {
                    right: ["6", "right"],
                    down:  ["4", "up"],
                    left:  ["3", "up"],
                    up:    ["2", "up"]
                  }
                },
                "2": {
                  y: $cube_size,
                  x: 0,
                  connections: {
                    right: ["3", "left"],
                    down:  ["5", "down"],
                    left:  ["6", "down"],
                    up:    ["1", "up"]
                  }
                },
                "3": {
                  y: $cube_size,
                  x: $cube_size,
                  connections: {
                    right: ["4", "left"],
                    down:  ["5", "left"],
                    left:  ["2", "right"],
                    up:    ["1", "left"]
                  }
                },
                "4": {
                  y: $cube_size,
                  x: (2 * $cube_size),
                  connections: {
                    right: ["6", "up"],
                    down:  ["5", "up"],
                    left:  ["3", "right"],
                    up:    ["1", "down"]
                  }
                },
                "5": {
                  y: (2 * $cube_size),
                  x: (2 * $cube_size),
                  connections: {
                    right: ["6", "left"],
                    down:  ["2", "down"],
                    left:  ["3", "down"],
                    up:    ["4", "down"]
                  }
                },
                "6": {
                  y: (2 * $cube_size),
                  x: (3 * $cube_size),
                  connections: {
                    right: ["1", "right"],
                    down:  ["2", "left"],
                    left:  ["5", "right"],
                    up:    ["4", "right"]
                  }
                }
              }
            end),
      y: 0,
      x: (.[0] | index(46)),
      max_y: $max_y,
      max_x: $max_x,
      orientation_y: 0,
      orientation_x: 1
    }
  ;

def is_right:
  .orientation_x == 1
  ;

def is_up:
  .orientation_y == -1
  ;

def is_left:
  .orientation_x == -1
  ;

def is_down:
  .orientation_y == 1
  ;

def find_cube:
  .x as $x
  | .y as $y
  | .cube_size as $cube_size
  | .cube
  | to_entries
  | map(
      .value
      | select($x >= .x and $x < (.x + $cube_size) and $y >= .y and $y < (.y + $cube_size))
    )
  | .[0]
  ;

# Translate coordinates on the border to a single value "t" between 0 and .cube_size
#
# ^--->
# |   |
# |   |
# <---v
def to_t($cube):
  if .orientation_x == 1 then
    [
      (.y - $cube.y),
      $cube.connections.right
    ]
  elif .orientation_y == 1 then
    [
      (($cube.x + .cube_size - 1) - .x),
      $cube.connections.down
    ]
  elif .orientation_x == -1 then
    [
      (($cube.y + .cube_size - 1) - .y),
      $cube.connections.left
    ]
  elif .orientation_y == -1 then
    [
      (.x - $cube.x),
      $cube.connections.up
    ]
  else
    "invalid orientation \(.orientation_x)x\(.orientation_y)" | error
  end
  ;

# Translate coordinates on the border from the "t" value
#
# <---^
# |   |
# |   |
# v--->
def from_t($cube; $from_orientation; $t):
  if $from_orientation == "right" then
    {
      next_y: ($cube.y + .cube_size - 1 - $t),
      next_x: ($cube.x + .cube_size - 1),
      next_orientation_y: 0,
      next_orientation_x: -1
    }
  elif $from_orientation == "down" then
    {
      next_y: ($cube.y + .cube_size - 1),
      next_x: ($cube.x + $t),
      next_orientation_y: -1,
      next_orientation_x: 0
    }
  elif $from_orientation == "left" then
    {
      next_y: ($cube.y + $t),
      next_x: $cube.x,
      next_orientation_y: 0,
      next_orientation_x: 1
    }
  elif $from_orientation == "up" then
    {
      next_y: $cube.y,
      next_x: ($cube.x + .cube_size - 1 - $t),
      next_orientation_y: 1,
      next_orientation_x: 0
    }
  else
    "invalid orientation \($from_orientation)" | error
  end
  ;

def move($steps):
  def next_position:
    (.y + .orientation_y) as $next_y
    | (.x + .orientation_x) as $next_x
    | if $next_y < 0 or $next_x < 0 or .lines[$next_y] == null or .lines[$next_y][$next_x] == null or .lines[$next_y][$next_x] == 32 then # " "
        find_cube as $cube
        | to_t($cube) as [$t, [$next_cube, $orientation]]
        | from_t(.cube[$next_cube]; $orientation; $t)
      else
        {
          next_y: $next_y,
          next_x: $next_x,
          next_orientation_y: .orientation_y,
          next_orientation_x: .orientation_x,
        }
      end
    ;
  def step:
    if .steps == 0 then
      .state
    else
      (.state | next_position) as {
        $next_x,
        $next_y,
        $next_orientation_y,
        $next_orientation_x
      }
      | if .state.lines[$next_y][$next_x] == 46 then # "."
          .state.x = $next_x
          | .state.y = $next_y
          | .state.orientation_x = $next_orientation_x
          | .state.orientation_y = $next_orientation_y
          | .steps -= 1
          | step
        else # "#"
          .state
        end
    end
    ;
  {state: ., steps: $steps}
  | step
  ;

def rotate($rotation):
  . as {$orientation_x, $orientation_y}
  | if $rotation == "L" then
      .orientation_x = $orientation_y
      | .orientation_y = -$orientation_x
    else
      .orientation_x = -$orientation_y
      | .orientation_y = $orientation_x
    end
  ;

def handle_instruction($instruction):
  (try ($instruction | tonumber) catch $instruction) as $parsed_instruction
  | if $parsed_instruction | type == "string" then
      rotate($parsed_instruction)
    else
      move($parsed_instruction)
    end
  ;

def password:
  1000 * (.y + 1) + 4 * (.x + 1) + if .orientation_x == 1 then
    0
  elif .orientation_y == 1 then
    1
  elif .orientation_x == -1 then
    2
  else
    3
  end
  ;

def debug_position:
  ("(\(.x + 1), \(.y + 1)) orientation \(.orientation_x)x\(.orientation_y)" | debug) as $_
  | .
  ;

split("\n\n")
| reduce (.[1] | parse_instructions[]) as $instruction (
    .[0] | parse_state | debug_position;
    handle_instruction($instruction) | debug_position
  )
| password
