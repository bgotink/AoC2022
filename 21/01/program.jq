#!/usr/bin/env -S jq -R -f

def parse_line:
  split(": ")
  | {
      (.[0]): (.[1] | capture("(?:(?<left>[a-z]{4}) (?<operator>[*+/-]) (?<right>[a-z]{4}))|(?<number>[0-9]+)"))
    }
  ;

def get_value($name):
  .[$name] as $val
  | if $val.number != null then
      $val.number | tonumber
    elif $val.operator == "+" then
      get_value($val.left) + get_value($val.right)
    elif $val.operator == "-" then
      get_value($val.left) - get_value($val.right)
    elif $val.operator == "*" then
      get_value($val.left) * get_value($val.right)
    elif $val.operator == "/" then
      get_value($val.left) / get_value($val.right)
    else
      "unknown operator: \($val.operator)" | error
    end
  ;

[., inputs]
| map(parse_line)
| add
| get_value("root")
