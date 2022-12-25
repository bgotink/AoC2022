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

def solve($name; $value):
  if $name == "humn" then
    $value
  else
    .[$name] as $current
    | if $current.number != null then
        "expected operator at \($name), but got \($current.number)" | error
      else
        get_value($current.left) as $left
        | get_value($current.right) as $right
        | if $current.operator == "+" then
            if $left | isnan then
              solve($current.left; ($value - $right))
            else
              solve($current.right; ($value - $left))
            end
          elif $current.operator == "-" then
            if $left | isnan then
              solve($current.left; ($value + $right))
            else
              solve($current.right; ($left - $value))
            end
          elif $current.operator == "*" then
            if $left | isnan then
              solve($current.left; ($value / $right))
            else
              solve($current.right; ($value / $left))
            end
          elif $current.operator == "/" then
            if $left | isnan then
              solve($current.left; ($value * $right))
            else
              solve($current.right; ($left / $value))
            end
          else
            "unknown operator: \($current.operator)" | error
          end
      end
  end
  ;

[., inputs]
| map(parse_line)
| add
| .humn.number = nan
| get_value(.root.left) as $left
| get_value(.root.right) as $right
| if $left | isnan then
    solve(.root.left; $right)
  else
    solve(.root.right; $left)
  end
