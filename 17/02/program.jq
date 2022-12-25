#!/usr/bin/env -S jq -R -f

def to_initial_state:
  {
    wind: {
      pattern: split(""),
      index: 0,
      length: length,
    },
    rocks: {
      pattern: [
        [[2, 3, 4, 5]],
        [[3], [2, 3, 4], [3]],
        [[2, 3, 4], [4], [4]],
        [[2], [2], [2], [2]],
        [[2, 3], [2, 3]]
      ],
      index: 0,
      length: 5
    },
    room_width: 7,
    room: [],
    room_height: 0,
    known_positions: {}
  }
  ;

def move_down:
  .current_rock.y_bottom += 1
  ;

def move_horizontal($dx):
  .current_rock.coordinates |= map(map(. + $dx))
  ;

def move_left: move_horizontal(-1);
def move_right: move_horizontal(1);

def is_free:
  .room_width as $room_width
  | if .current_rock.coordinates | flatten | any(. < 0 or . >= $room_width) then
      false # across the edge of the room
    elif .current_rock.y_bottom < 0 then
      true # above anything in the room
    elif .current_rock.y_bottom >= .room_height then
      false # through the bottom
    else
      .room as $room
      | .current_rock as $rock
      | ([-1, $rock.y_bottom - ($rock.coordinates | length)] | max) as $y_top_of_rock
      | [range($rock.y_bottom; $y_top_of_rock;  -1)]
      | all(
          $room[.] as $room_line
          | $rock.coordinates[$rock.y_bottom - .]
          | all($room_line[.] | not)
        )
    end
  ;

def apply_wind:
  . as $original
  | if .wind.pattern[.wind.index] == "<" then
      move_left
    else
      move_right
    end
  | if is_free then
      .
    else
      $original
    end
  | .wind.index = ((.wind.index + 1) % .wind.length)
  ;

def drop:
  . as $original
  | move_down
  | if is_free then
      .
    else
      # it's time to freeze this rock
      $original
      | (.current_rock.coordinates | length) as $rock_height
      | if .room_height == 0 or .current_rock.y_bottom < $rock_height - 1 then
          .room_width as $width
          | ([1, (.current_rock.coordinates | length) - .current_rock.y_bottom - 1] | max) as $lines_to_add
          | .room_height += $lines_to_add
          | .room = [
              range($lines_to_add)
              | [range($width) | false]
            ] + .room
          | .current_rock.y_bottom = $rock_height - 1
        else
          .
        end
      | reduce range(.current_rock.coordinates | length) as $rock_i (
          .;
          (.current_rock.y_bottom - $rock_i) as $room_i
          | reduce .current_rock.coordinates[$rock_i][] as $x (
              .;
              .room[$room_i][$x] = true
            )
        )
      | .current_rock = null
    end
  ;

def free_index_at($x):
  def free_index_at($y; $x):
    if (.room[$y] // [])[$x] != false then
      $y
    else
      free_index_at($y + 1; $x)
    end
    ;
  free_index_at(0; $x)
  ;

def free_spaces:
  . as $state
  | [range(.room_width)]
  | map(
      . as $x
      | $state | free_index_at($x)
    )
  | join("")
  ;

def known_position_key:
  "\(.wind.index)|\(.rocks.index)|\(free_spaces)"
  ;

def add_rock:
  def step:
    apply_wind | drop | if .current_rock == null then . else step end;
  .current_rock = {
    coordinates: .rocks.pattern[.rocks.index],
    y_bottom: -4
  }
  | .rocks.index = ((.rocks.index + 1) % .rocks.length)
  | step
  ;

def add_rocks($i; $n):
  add_rock
  | known_position_key as $kp_key
  | .known_positions[$kp_key] as $kp
  | if $kp != null then
      $kp as [$oldi, $oldroomheight]
      | ($n - $i) as $remaining_rocks
      | ($i - $oldi) as $cycle_rocks
      | ($remaining_rocks / $cycle_rocks | floor) as $no_cycles
      | (.room_height - $oldroomheight) as $cycle_height
      | ($i + $no_cycles * $cycle_rocks) as $new_i
      | .room_height += $cycle_height * $no_cycles
      | if $new_i == $n then
          .
        else
          add_rocks($new_i + 1; $n)
        end
    elif $i == $n then
      .
    else
      .known_positions[$kp_key] = [$i, .room_height]
      | add_rocks($i + 1; $n)
    end
  ;

to_initial_state
| add_rocks(1; 1000000000000)
| .room_height

