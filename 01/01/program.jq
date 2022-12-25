#!/usr/bin/env -S jq -R -f

reduce inputs as $item (
  { max: 0, sum: 0 } ;
  if ($item | length) > 0 then
    .sum += ($item | tonumber)
  else
    {sum: 0, max: ([.max, .sum] | max)}
  end
) |
[.max, .sum] | max
