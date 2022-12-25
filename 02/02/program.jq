#!/usr/bin/env -S jq -sR -f

def other_move:
  {A: "rock", B: "paper", C: "scissors"}[.[0:1]];

def own_move:
  {X: "lose", Y: "draw", Z: "win"}[.[-1:]];

def move_points:
  {
    rock: {lose: 3, win: 2, draw: 1},
    paper: {lose: 1, draw: 2, win: 3},
    scissors: {draw: 3, win: 1, lose: 2},
  }[other_move][own_move];

def win_points:
  {lose: 0, draw: 3, win: 6}[own_move];

def points:
  (. | win_points) + (. | move_points);

split("\n") | map(select(length > 0) | points) | add
