#!/usr/bin/env -S jq -f

def tick($items; $length):
  reduce $items[] as $item (
    .;
    index($item) as $index
    | remainder($index + $item.value; $length - 1) as $newindex
    | [.[0:$index][], .[($index + 1):][]]
    | [.[0:$newindex][], $item, .[$newindex:][]]
  )
  ;

[., inputs]
| length as $length
| index(0) as $id_zero
| map(. * 811589153)
| to_entries
| map({id: .key, value: .value})
| . as $original_list
| reduce range(10) as $_ (.; tick($original_list; $length))
| index({id: $id_zero, value: 0}) as $index_zero
| (.[remainder($index_zero + 1000; $length)].value | debug)
+ (.[remainder($index_zero + 2000; $length)].value | debug)
+ (.[remainder($index_zero + 3000; $length)].value | debug)
