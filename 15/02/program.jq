#!/usr/bin/env -S jq -R -f

# Every sensor leads to a square region that our distress beacon cannot be 
# inside of.
#              x
# --+---#------>
#   |  ###
#   | #####
#   |###S###
#   | #####
#   |  B##
#   |   #
# y v
#   
# We'll instead say that every beacon cuts the plane into four overlapping
# areas the distress beacon might be inside:
#
#       h     ix    # k     j      x
# --+---/-----/>    # \-+---\------>
#   |H /     /      #  \|    \
#   | /     /       #   \     \  J
#   |/  S  /        #   |\  S  \
#   /     /  I      #   | \     \
#   |  B /          #   |  B     \
#   |   /           #   | K \     \
# y v  /            # y v
#
# Call these areas H, I, J, and K.
#
# Areas H and I are bounded by the a line `y = -x + c`, while areas J and K are
# bounded by a line `y = x + c`.
#
# We can describe the four demiplanes as follows:
#  H  :=  y < -x + h  where h = x_sensor - size + y_sensor
#  I  :=  y > -x + i        i = x_sensor + size + y_sensor
#  J  :=  y < x - j         j = x_sensor + size - y_sensor
#  K  :=  y > x - k         k = x_sensor - size - y_sensor
#                       and size = | x_sensor - x_beacon | + | y_sensor - y_beacon |
#
# Every sensor is described by these four planes, and our distress beacon must
# lie within one of the four planes of every beacon.
# The possible area the distress beacon can be inside can be described by these
# same four bounds.
#
# Initially the beacon must lie within 0 <= x <= 4000000 and 0 <= y <= 4000000.
# That area is bounded by the following equations:
#    y < -x + 8000000
#    y > -x + 0
#    y < x - -4000000
#    y > x - 4000000
# For every beacon, we can apply the knowledge that the beacon itself defines
# four demiplanes and split our search area into four smaller search areas:
#   replace y < -x + 8000000  with y < -x + min(8000000, h)
#   replace y > -x + 0        with y > -x + max(0, i)
#   replace y < x - -4000000  with y < x - max(-4000000, j)
#   replace y > x - 4000000   with y > x - min(4000000, k)
#
# We have to narrow this down to limits that allow for exactly one value,
#   y < -x + (u + 1)
#   y > -x + (u - 1)
#   y < x - (v - 1)
#   y > x - (v + 1)
#
# We know our beacon is at x and y so that these equations hold:
#   y = -x + u
#   y = x - v
# Substiting y using the second equation into the first yields
#   x - v = -x + u  =>  x = (u + v) / 2
# which yields
#   y = (u - v) / 2


def parse_sensor:
  split(":")
  | map(
    split(" at ")[1]
    | split(", ")
    | map(.[2:] | tonumber)
    )
  | {sensor: .[0], beacon: .[1]};

def sensor_to_exclusion:
  .sensor[0] as $x_sensor
  | .sensor[1] as $y_sensor
  | (($x_sensor - .beacon[0]) | fabs) as $x_diff_beacon
  | (($y_sensor - .beacon[1]) | fabs) as $y_diff_beacon
  | ($x_diff_beacon + $y_diff_beacon) as $size
  | {
      h: ($x_sensor - $size + $y_sensor),
      i: ($x_sensor + $size + $y_sensor),
      j: ($x_sensor + $size - $y_sensor),
      k: ($x_sensor - $size - $y_sensor),
    };

def apply_exlusion($exclusion; $key):
  if $key == "h" or $key == "k" then
    .[$key] = ([.[$key], $exclusion[$key]] | min)
  else
    .[$key] = ([.[$key], $exclusion[$key]] | max)
  end;

def apply_exlusions($exclusion):
  . as $state
  | $exclusion | keys_unsorted
  | map(. as $key | $state | apply_exlusion($exclusion; $key))
  | unique;

def is_useful_exclusion:
  .h > 0 and
  .i < 8000000 and
  .j < 4000000 and
  .k > -4000000 and
  .h > .i and
  .k > .j;

def total_size:
  map(.[1] - .[0]) | add;

reduce inputs as $line (
  [{
    h: 8000000,
    i: 0,
    j: -4000000,
    k: 4000000,
  }];
  map(apply_exlusions($line | parse_sensor | sensor_to_exclusion)[] | select(is_useful_exclusion)) | unique
)
| map(
    select(.h - .i == 2)
    | select(.k - .j == 2)
    | {u: (.h - 1), v: (.k - 1)}
    | {x: ((.u + .v) / 2), y: ((.u - .v) / 2)}
  )
| map(.x * 4000000 + .y)
