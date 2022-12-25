#!/usr/bin/env -S jq -s -f

def pairwise:
  foreach .[] as $item (
    {emit: null, previous: null};
    if .previous == null then
      {
        emit: null,
        previous: $item
      }
    else
      {
        emit: [.previous, $item],
        previous: null
      }
    end;
    if .emit != null then .emit else empty end
  );

def order:
  def order_at($i):
    .[0][$i] as $left
    | .[1][$i] as $right
    | if $left == null then
        if $right == null then null else -1 end
      elif $right == null then
        1
      elif $left | type == "array" then
        if $right | type == "array" then
          [$left, $right] | order
        else
          [$left, [$right]] | order
        end
      else
        if $right | type == "array" then
          [[$left], $right] | order
        else
          $left - $right
        end
      end;
  def loop($i):
    order_at($i) as $order
    | if $order == null then
        0
      elif $order == 0 then
        loop($i + 1)
      else
        $order
      end;
  loop(0);

def bubblesort:
  reduce range(length) as $j (
    .;
    reduce range(1; length - $j) as $i (
      .;
      if [.[$i - 1], .[$i]] | order > 0 then
        .[$i] as $tmp
        | .[$i] = .[$i - 1]
        | .[$i - 1] = $tmp
      else
        .
      end
    )
  );

def key:
  index([[[2]]]) as $one
  | index([[[6]]]) as $two
  | ($one + 1) * ($two + 1);

. + [[[2]], [[6]]]
| bubblesort
| key