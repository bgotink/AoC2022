#!/usr/bin/env -S jq -R -f

def is_packet:
  (
    .[0] == .[1] or .[0] == .[2] or .[0] == .[3] or
    .[1] == .[2] or .[1] == .[3] or
    .[2] == .[3]
  ) | not;

def step($state; $i):
  [$state[-3:][], .[0]] as $next |
  if $next | is_packet then
    $i
  else
    .[1:] | step($next; $i + 1)
  end;

def find_packet_index:
  explode |
    .[0:3] as $initial |
    .[3:] | step($initial; 0);

select(length > 0) | find_packet_index + 4