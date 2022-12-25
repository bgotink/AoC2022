#!/usr/bin/env -S jq -sR -f

def parse_state:
  split("\n")[0:-1] |
    map([match("(?:   |\\[(.)\\])(?: |$)"; "g")] | map(.captures[0].string)) |
    transpose | map(map(select(. != null)));

def parse_step:
  capture("move (?<amount>[0-9]+) from (?<from>[0-9]+) to (?<to>[0-9]+)") |
  {
    from: (-1 + (.from | tonumber)),
    to: (-1 + (.to | tonumber)),
    amount: .amount | tonumber,
  };

def parse_steps:
  split("\n") | map(select(length > 0) | parse_step);

def parse:
  split("\n\n") | {state: (.[0] | parse_state), steps: (.[1] | parse_steps)};

def apply_step($step):
  .[$step.to] = [.[$step.from][0:$step.amount][], .[$step.to][]] |
  .[$step.from] = .[$step.from][$step.amount:];

def evaluate_steps:
  reduce .steps[] as $step (.state; apply_step($step));

def get_top:
  map(.[0]) | join("");

parse | evaluate_steps | get_top
