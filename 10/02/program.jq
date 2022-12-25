#!/usr/bin/env -S jq -R -f

def tick:
  .cycles += [{ pc: .pc, value: .registers.x }]
  | .pc += 1;

def apply_command($command):
  .cycles = []
  | if $command == "noop" then
    tick
    elif $command | startswith("addx ") then
      tick
      | tick
      | .registers.x += ($command[5:] |  tonumber)
    else
      error
    end;

def start:
  { pc: 0, registers: { x: 1 } };

def execute:
  foreach .[] as $command (
    start;
    apply_command($command);
    .cycles[]
  );

def draw:
  reduce .[] as $sprite (
    [range(6)] | map([range(40)] | map("."));
    ($sprite.pc % 40) as $x
    | ($sprite.pc / 40 | floor) as $y
    | if ($x - $sprite.value) | fabs < 2 then
        .[$y][$x] = "#"
      else
        .
      end
  );

[., inputs]
  | [execute]
  | draw[]
  | join("")