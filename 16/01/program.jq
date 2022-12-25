#!/usr/bin/env -S jq -R -f

def parse_line:
  split("; ")
  | {
      name: (.[0][6:8]),
      flow_rate: (.[0] | split("=")[1] | tonumber),
      connections: (.[1] | (split(" valves ")[1] // split(" valve ")[1]) | split(", "))
    };

def to_state:
  reduce .[] as $valve (
    { flow_rates: {}, location: "AA", connections: {}, open_flow: 0, total_open_flow: 0 };
    .flow_rates += {($valve.name): ($valve.flow_rate)}
    | .connections += {($valve.name): $valve.connections}
  );

def activate:
  if .flow_rates[.location] > 0 then
    .open_flow += .flow_rates[.location]
    | .flow_rates[.location] = 0
    | .previous_location = null
  else
    empty
  end;

def move:
  .location as $location
  | .location = (.connections[$location] - [.previous_location])[]
  | .previous_location = $location
  ;

[., inputs]
| map(parse_line)
| reduce range(30) as $i (
    [to_state];
    map(
      .total_open_flow += .open_flow
      | [activate, move][]
    )
    | sort_by(.total_open_flow)[-100:]
  )
| .[-1].total_open_flow
