#!/usr/bin/env -S jq -R -f

def handle($point; $dx; $dy; $dz):
  "\($point[0] + $dx)x\($point[1] + $dy)x\($point[2] + $dz)" as $key
  | if .present_spots[$key] then
      .free_spots -= 2
    else
      .
    end
  ;

def handle($point):
  .free_spots += 6
  | handle($point; 1; 0; 0)
  | handle($point; -1; 0; 0)
  | handle($point; 0; 1; 0)
  | handle($point; 0; -1; 0)
  | handle($point; 0; 0; 1)
  | handle($point; 0; 0; -1)
  | .present_spots[$point | join("x")] = true
  ;

[., inputs]
| map(split(",") | map(tonumber))
| . as $points
| reduce .[] as $point (
    {
      free_spots: 0,
      present_spots: {}
    };
    handle($point)
  )
| .free_spots
