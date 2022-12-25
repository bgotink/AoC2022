#!/usr/bin/env -S jq -R -f

def empty_dir:
  {directories: {}, files: {}};

def at_path($path; action):
  if $path | length == 0 then
    action
  else
    .directories[$path[0]] |= at_path($path[1:]; action)
  end;

def add_dir($path; $name):
  at_path($path; .directories += {($name): empty_dir});

def add_file($path; $info):
  at_path($path; .files += {($info[1]): $info[0] | tonumber});

def parse_fs:
  reduce .[] as $line (
    {root: empty_dir, path: []};
    if $line[0:1] != "$" then
      .path as $path |
      .root |= if $line[0:3] == "dir" then
        add_dir($path; $line[4:])
      else
        add_file($path; $line | split(" "))
      end
    else
      ([$line | match("^\\$ cd (.*)")][0]) as $match |
      if $match == null then
        .
      else
        if $match.captures[0].string == "/" then
          .path = []
        elif $match.captures[0].string == ".." then
          .path = .path[0:-1]
        else
          .path += [$match.captures[0].string]
        end
      end
    end
  ) |
  .root;

def sum_of(size):
  to_entries | map(.value | size) | add;

def add_directory_sizes:
  .directories |= with_entries(.value |= add_directory_sizes) |
  .size = (.directories | sum_of(.size)) + (.files | sum_of(.));

def all_directories:
  [
    .,
    (.directories | to_entries | map(.value | all_directories[])[])
  ];

[., inputs]|
  parse_fs |
  add_directory_sizes |
  all_directories |
  map(select(.size < 100000) | .size) | add