# Advent of Code 2022

This repository contains solutions for [Advent of Code 2022](https://adventofcode.com/2022) (AoC) in [jq](https://stedolan.github.io/jq/), with a bit of [Rust](https://www.rust-lang.org/) thrown in when jq proved to be too slow.

Some context: I tried to solve the 2019 AoC in jq and gave up after 14-ish days. It's been years since I've written jq scripts, so expect very silly mistakes and workarounds—especially in the first solutions while I get my bearings.

Execution
Run a solution by compiling using the `run.sh` script:

```bash
./run.sh 01 01
./run.sh 20 02
./run.sh 25
```

Run `./run.sh` for help output.

Alternatively, run one of the `program.jq` files with a single input: the path to an input file. These files are bundled in the same folders as the program files, called `input.dat` for the real input and one (or more) `test.dat` files containing example input files given in the AoC problem statement.
