# Solving by hand

My moves are stuck on a square grid, which means that if I have to reach one point from another, it doesn't matter if I go horizontal first, vertical first, or something in the middle. Only the [Manhattan Distance][https://en.wikipedia.org/wiki/Taxicab_geometry] counts.  
Using Manhattan distance we know that the exact path between two points doesn't really matter as long as we don't have to move backwards (i.e. to a direction away from our target). Solving this puzzle therefore comes down to finding the next letter in the alphabet where moving backwards is kept to a minimum. Occasionally backtracking is involved, because moving back for one letter might lead to a more optimal path for another.

In the input there's a single spot where the `c`s run from left to right, all other paths from left to right are blocked by islands of `a`. We also know that our starting point lies in the left-most column, because those are the only `a`s connected to `b`s.
Taken together this makes it very easy to go from solution 1 to solution 2: the shortest path would be straight from the starting point to the single path through the islands of `a`. However, that's blocked by a solitary `a`, so we have to go one up.
There is no need to reevalute the rest of the path, because we already know that's the shortest path through the single path through the islands of `a`.

## Is this cheating?

No. The goal is to solve the puzzle. While most puzzles are faster to solve by coding, sometimes a puzzle comes along that is easier to solve by reasoning through it.

Knowing when not to code is an important skill for programmers.
