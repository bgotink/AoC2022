#!/usr/bin/env -S jq -R -f

def from_snafu:
  explode
  | map(
      if . >= 48 and . <= 50 then
        . - 48
      elif . == 45 then
        -1
      elif . == 61 then
        -2
      else
        "unexpected character \"\([.] | implode)\"" | error
      end
    )
  | reverse
  | reduce .[] as $i (
      { v: 0, u: 1 };
      .v += .u * $i
      | .u *= 5
    )
  | .v
  ;

def to_snafu:
  def step:
    if .r == 0 then
      .v
    else
      (.r % 5) as $rest
      | .r = (.r / 5 | floor)
      | if $rest == 4 then
          .v = "-\(.v)"
          | .r += 1
        elif $rest == 3 then
          .v = "=\(.v)"
          | .r += 1
        else
          .v = "\($rest)\(.v)"
        end
      | step
    end
    ;
  { v: "", r: . }
  | step
  ;

[., inputs]
| map(from_snafu)
| add
| to_snafu