#!/usr/bin/env -S jq -R -f

def parse_query:
  {
    y: (.[("Q y=" | length):] | tonumber),
    ranges: []
  };

def parse_sensor:
  split(":")
  | map(
    split(" at ")[1]
    | split(", ")
    | map(.[2:] | tonumber)
    )
  | {sensor: .[0], beacon: .[1]};

def handle_sensor($p):
  $p.sensor[0] as $x_sensor
  | $p.sensor[1] as $y_sensor
  | (($x_sensor - $p.beacon[0]) | fabs) as $x_diff_beacon
  | (($y_sensor - $p.beacon[1]) | fabs) as $y_diff_beacon
  | (($y_sensor - .y) | fabs) as $y_diff_target
  | ($x_diff_beacon + $y_diff_beacon - $y_diff_target) as $xs
  | if $xs > 0 then
      .ranges += [[($x_sensor - $xs), $x_sensor + $xs]]
    else
      .
    end;

def merge_ranges:
  sort_by(.[0])
  | [
    foreach [.[1:][], [infinite]][] as $range (
      [.[0], null];
      if $range[0] > (.[0][1] + 1) then
        [$range, .[0]]
      else
        [[.[0][0], ([.[0][1], $range[1]] | max)]]
      end;
      .[1] // empty
    )
  ];

def total_size:
  map(.[1] - .[0]) | add;

reduce inputs as $line (
  parse_query;
  handle_sensor($line | parse_sensor)
)
| .ranges
| merge_ranges
| total_size
