#!/usr/bin/env -S jq -sR -f

def other_move:
  {A: "rock", B: "paper", C: "scissors"}[.[0:1]];

def own_move:
  {X: "rock", Y: "paper", Z: "scissors"}[.[-1:]];

def move_points:
  {rock: 1, paper: 2, scissors: 3}[. | own_move];

def win_points:
  {
    rock: {rock: 3, paper: 6, scissors: 0},
    paper: {rock: 0, paper: 3, scissors: 6},
    scissors: {rock: 6, paper: 0, scissors: 3},
  }[. | other_move][. | own_move];

def points:
  (. | win_points) + (. | move_points);

split("\n") | map(select(length > 0) | points) | add
