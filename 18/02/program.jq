#!/usr/bin/env -S jq -R -f

def is_out_of_bounds($x; $y; $z):
  $x > .max_x
  or $x < .min_x
  or $y > .max_y
  or $y < .min_y
  or $z > .max_z
  or $z < .min_z
  ;

def get($x; $y; $z):
  if is_out_of_bounds($x; $y; $z) then
    null
  else
    .points[$x][$y][$z]
  end
  ;
def get($point): get($point[0]; $point[1]; $point[2]);

def set($x; $y; $z; $v):
  .points[$x] //= []
  | .points[$x][$y] //= []
  | .points[$x][$y][$z] = $v
  ;
def set($point; $v): set($point[0]; $point[1]; $point[2]; $v);

def surface_area:
  .surface_area = 0
  | reduce range(.min_x; .max_x + 1) as $x (
      .;
      reduce range(.min_y; .max_y + 1) as $y (
        .;
        reduce range(.min_z; .max_z + 1) as $z (
          .;
          if get($x; $y; $z) == 1 then
            .surface_area += 6
              - (get($x + 1; $y    ; $z    ) // 0)
              - (get($x - 1; $y    ; $z    ) // 0)
              - (get($x    ; $y + 1; $z    ) // 0)
              - (get($x    ; $y - 1; $z    ) // 0)
              - (get($x    ; $y    ; $z + 1) // 0)
              - (get($x    ; $y    ; $z - 1) // 0)
          else
            .
          end
        )
      )
    )
  | .surface_area
  ;

def min($v): if . > $v then $v else . end;
def max($v): if . < $v then $v else . end;

def is_at_bounds($x; $y; $z):
  $x == .max_x
  or $x == .min_x
  or $y == .max_y
  or $y == .min_y
  or $z == .max_z
  or $z == .min_z
  ;

def mark_free_spots:
  reduce range(.min_x; .max_x + 1) as $x (
    .;
    reduce range(.min_y; .max_y + 1) as $y (
      .;
      reduce range(.min_z; .max_z + 1) as $z (
        .;
          if is_at_bounds($x; $y; $z) and get($x; $y; $z) != 1 then
            set($x; $y; $z; 0)
          else
            .
          end
      )
    )
  )
  ;

def expand_free_spots:
  def maybe_process($x; $y; $z):
    if is_out_of_bounds($x; $y; $z) then
      .
    elif get($x; $y; $z) | type == "number" then
      .
    else
      set($x; $y; $z; 0)
      | maybe_process($x - 1; $y    ; $z    )
      | maybe_process($x + 1; $y    ; $z    )
      | maybe_process($x    ; $y - 1; $z    )
      | maybe_process($x    ; $y + 1; $z    )
      | maybe_process($x    ; $y    ; $z - 1)
      | maybe_process($x    ; $y    ; $z + 1)
    end
    ;
  reduce range(.min_x; .max_x + 1) as $x (
    .;
    reduce range(.min_y; .max_y + 1) as $y (
      .;
      reduce range(.min_z; .max_z + 1) as $z (
        .;
          if get($x; $y; $z) == 0 then
            .
            | maybe_process($x - 1; $y    ; $z    )
            | maybe_process($x + 1; $y    ; $z    )
            | maybe_process($x    ; $y - 1; $z    )
            | maybe_process($x    ; $y + 1; $z    )
            | maybe_process($x    ; $y    ; $z - 1)
            | maybe_process($x    ; $y    ; $z + 1)
          else
            .
          end
      )
    )
  )
  ;

def fill_cavities:
  reduce range(.min_x; .max_x + 1) as $x (
    .;
    reduce range(.min_y; .max_y + 1) as $y (
      .;
      reduce range(.min_z; .max_z + 1) as $z (
        .;
          if get($x; $y; $z) != 0 then
            set($x; $y; $z; 1)
          else
            .
          end
      )
    )
  )
  ;

[., inputs]
| map(split(",") | map(tonumber))
| reduce .[] as $point (
    {
      points: [],
      min_x: infinite,
      max_x: -infinite,
      min_y: infinite,
      max_y: -infinite,
      min_z: infinite,
      max_z: -infinite
    };
    set($point[0]; $point[1]; $point[2]; 1)
    | .min_x |= min($point[0])
    | .max_x |= max($point[0])
    | .min_y |= min($point[1])
    | .max_y |= max($point[1])
    | .min_z |= min($point[2])
    | .max_z |= max($point[2])
  )
| mark_free_spots
| expand_free_spots
| fill_cavities
| surface_area
