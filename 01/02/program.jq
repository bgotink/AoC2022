#!/usr/bin/env -S jq -R -f

def applySum:
  if .sum > .elf1 then
    { elf1: .sum, elf2: .elf1, elf3: .elf2, sum: 0 }
  elif .sum > .elf2 then
    { elf1: .elf1, elf2: .sum, elf3: .elf2, sum: 0 }
  elif .sum > .elf3 then
    { elf1: .elf1, elf2: .elf2, elf3: .sum, sum: 0 }
  else
    { elf1: .elf1, elf2: .elf2, elf3: .elf3, sum: 0 }
  end;

reduce inputs as $item (
  { elf1: 0, elf2: 0, elf3: 0, sum: 0 } ;
  if ($item | length) > 0 then
    .sum += ($item | tonumber)
  else
    applySum
  end
) |
applySum |
.elf1 + .elf2 + .elf3
