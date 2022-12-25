#!/usr/bin/env -S jq -f

[., inputs]
| index(0) as $id_zero
| to_entries
| map({id: .key, value: .value})
| length as $length
| reduce .[] as $item (
    .;
    index($item) as $index
    | remainder($index + $item.value; $length - 1) as $newindex
    | [.[0:$index][], .[($index + 1):][]]
    | [.[0:$newindex][], $item, .[$newindex:][]]
  )
| index({id: $id_zero, value: 0}) as $index_zero
| (.[remainder($index_zero + 1000; $length)].value | debug)
+ (.[remainder($index_zero + 2000; $length)].value | debug)
+ (.[remainder($index_zero + 3000; $length)].value | debug)
