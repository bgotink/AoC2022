#!/usr/bin/env -S jq -R -f

def tick:
  .pc += 1 |
  .cycles += [{ pc: .pc, value: .registers.x }];

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

def is_relevant_cycle:
  (.pc - 20) % 40 == 0;

def signal_strength:
  .pc * .value;

[., inputs]
  | [execute]
  | map(select(is_relevant_cycle) | signal_strength)
  | add