#!/usr/bin/env -S jq -sR -f

def parse_monkey:
  def after($str): .[($str | length):];
  split("\n") | {
    items: .[1] | split(": ")[1] | split(", ") | map(tonumber),
    operation: (.[2] | after("  Operation: new = old ") | if . == "* old" then
      {op: "**", value: 2}
    else
      {op: .[0:1], value: .[2:] | tonumber}
    end),
    divisor: .[3] | after("  Test: divisible by ") | tonumber,
    next: {
      divisible: .[4] | after("    If true: throw to monkey ") | tonumber,
      not_divisible: .[5] | after("    If false: throw to monkey ") | tonumber,
    },
    evaluated_items: 0,
  };

def op($op):
  if $op.op == "+" then
    . + $op.value
  elif $op.op == "*" then
    . * $op.value
  elif $op.op == "**" and $op.value == 2 then
    . * .
  else
    "unknown operator: \($op.op)" | error
  end;

def mul:
  reduce .[] as $item (1; . * $item);

def handle_monkey($i; $modulo):
  .[$i].items as $items
  | .[$i].operation as $op
  | .[$i].divisor as $divisor
  | .[$i].next as $next
  | .[$i].items = []
  | .[$i].evaluated_items += ($items | length)
  | reduce $items[] as $item (
      .;
      ($item | op($op) % $modulo) as $new_item
      | if $new_item % $divisor == 0 then
          .[$next.divisible].items += [$new_item]
        else
          .[$next.not_divisible].items += [$new_item]
        end
    );

def calculate_modulo:
  map(.divisor) | mul;

def evaluate_round($rounds; $modulo):
  if $rounds == 0 then
    .
  else
    reduce range(length) as $i (.; handle_monkey($i; $modulo))
      | evaluate_round($rounds - 1; $modulo)
  end;

def evaluate_round($rounds):
  evaluate_round($rounds; calculate_modulo);

split("\n\n")
  | map(select(length > 0) | parse_monkey)
  | evaluate_round(10000)
  | map(.evaluated_items)
  | sort
  | .[-2:]
  | mul
