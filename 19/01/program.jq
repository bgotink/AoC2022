#!/usr/bin/env -S jq -R -f

#
# This attempt was aborted because jq appears to be the wrong tool for the job.
# Even implementing this in JavaScript (node) is excruciatingly slow, whereas
# in Rust the response takes mere seconds.
#
# The fact that these languages have no tuple type with proper set support (at
# time of writing, JavaScript is working on tuples) is likely to help cause this
# major difference: dynamically creating millions of strings can be an issue.
#

def parse_cost:
  capture(
    "Each [a-z]+ robot costs (?<ore>[0-9]+) ore(?: and (?<clay>[0-9]+) clay)?(?: and (?<obsidian>[0-9]+) obsidian)?"
  )
  | [
      (.ore | tonumber),
      (.clay // "0" | tonumber),
      (.obsidian // "0" | tonumber)
    ]
  ;

def parse_blueprint:
  split(": ")
  | {
      id: (.[0] | split(" ")[1] | tonumber),
      build_costs: (.[1] | split(". ") | map(parse_cost))
    }
  | .build_costs as $build_costs
  | .max_build_costs = [
      range(3) as $i
      | $build_costs
      | map(.[$i])
      | max
    ]
  ;

def has_supply($cost):
  .[1] as $supply
  | $cost
  | to_entries
  | all($supply[.key] >= .value)
  ;

# like with_entries except for arrays and it doesn't support modifying the key
def with_items(mod):
  . as $arr
  | [range(length) | {key: ., value: $arr[.]} | mod.value]
  ;

def add_to_supply($add):
  .[1] |= with_items(.value += ($add[.key] // 0))
  ;

def take_from_supply($remove):
  .[1] |= with_items(.value -= ($remove[.key] // 0))
  ;

def tick($blueprint):
  . as $state
  | .[0] as $existing_robots
  | $blueprint.build_costs
  | to_entries
  | map(select(.value as $cost | $state | has_supply($cost)))
  | map(
      . as $robot_to_build
      | $state
      | take_from_supply($robot_to_build.value)
      | .[0][$robot_to_build.key] += 1
    )
  | if length < 4 then
      ($state, .[])
    else
      .[]
    end
  | add_to_supply($existing_robots)
  ;

def simplify_state($blueprint; $t):
  # if we have more robots for a certain ore than is useful, ignore this state
  if .[0][0] > $blueprint.max_build_costs[0] or .[0][1] > $blueprint.max_build_costs[1] or .[0][2] > $blueprint.max_build_costs[2] then
    empty
  else
    .
  end
  # if we have more ore / clay / obsidian than we could ever need, cut it off
  | if .[1][0] > ($t - 1) * $blueprint.max_build_costs[0] - ($t - 2) * .[0][0] then
      .[1][0] = ($t - 1) * $blueprint.max_build_costs[0] - ($t - 2) * .[0][0]
    else . end
  | if .[1][1] > ($t - 1) * $blueprint.max_build_costs[1] - ($t - 2) * .[0][1] then
      .[1][1] = ($t - 1) * $blueprint.max_build_costs[1] - ($t - 2) * .[0][1]
    else . end
  | if .[1][2] > ($t - 1) * $blueprint.max_build_costs[2] - ($t - 2) * .[0][2] then
      .[1][2] = ($t - 1) * $blueprint.max_build_costs[2] - ($t - 2) * .[0][2]
    else . end
  ;

def deduped_tick($blueprint; $t):
  reduce (.[1][] | tick($blueprint) | simplify_state($blueprint; $t)) as $new_state (
    [.[0], []];
    ([($new_state[0] | join("x")), ($new_state[1] | join("x"))] | join("|")) as $key
    | if .[0][$key] == true then
        .[0].hits += 1
      else
        .[0][$key] = true
        | .[1] += [$new_state]
      end
  )
  ;

def run($blueprint; $i):
  def helper:
    ([.[0], (.[1] | map(length)[]), .[1][0].hits] | debug) as $_ |
    .[0] as $t
    | if $t <= 0 then
        .[1][1]
      else
        [($t - 1), (.[1] | deduped_tick($blueprint; $t))]
        | helper
      end
    ;
  [$i, [{hits: 0}, [[[1, 0, 0, 0], [0, 0, 0, 0]]]]]
  | helper
  ;

[., inputs]
| map(
    parse_blueprint
    | . as $blueprint
    | run($blueprint ; 24)
    | map(.[1][-1])
    | max
    | debug
  )
| to_entries
| map(.key * .value)
| add