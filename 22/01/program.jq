#!/usr/bin/env -S jq -sR -f

def parse_instructions:
  gsub("(?<turn>L|R)"; "_\(.turn)_")
  | split("_")
  ;

def parse_state:
  split("\n") | map(explode)
  | {
      lines: .,
      y: 0,
      x: (.[0] | index(46)),
      max_y: length,
      max_x: (map(length) | max),
      orientation_y: 0,
      orientation_x: 1
    }
  ;

def move($steps):
  def next_position:
    def helper:
      if .lines[.next_y] == null or .lines[.next_y][.next_x] == null or .lines[.next_y][.next_x] == 32 then # " "
        .next_x = ((.next_x + .orientation_x + .max_x) % .max_x)
        | .next_y = ((.next_y + .orientation_y + .max_y) % .max_y)
        | helper
      else
        .
      end
      ;
    .next_x = (.x + .orientation_x + .max_x) % .max_x
    | .next_y = (.y + .orientation_y + .max_y) % .max_y
    | helper
    ;
  def step:
    if .steps == 0 then
      .state
    else
      (.state | next_position) as {$next_x, $next_y}
      | (.state.lines[$next_y][$next_x]) as $val
      | if $val == 46 then # "."
          .state.x = $next_x
          | .state.y = $next_y
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