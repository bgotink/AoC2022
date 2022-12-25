#!/usr/bin/env -S jq -R -f

def is_message:
  unique | length == 14;

def step($state; $i):
  [$state[-13:][], .[0]] as $next |
  if $next | is_message then
    $i
  else
    .[1:] | step($next; $i + 1)
  end;

def find_message_index:
  explode |
    .[0:13] as $initial |
    .[13:] | step($initial; 0);

select(length > 0) | find_message_index + 14