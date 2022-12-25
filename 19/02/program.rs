use std::collections::{HashSet, LinkedList};
use std::env;
use std::fs::File;
use std::io::{self, BufRead};
use std::num::ParseIntError;
use std::path::Path;
use std::cmp;

#[derive(PartialEq, Eq, Hash, Clone, Copy)]
struct State {
  ore: i32, clay: i32, obsidian: i32, geode: i32,
  robot_ore: i32, robot_clay: i32, robot_obsidian: i32, robot_geode: i32,
}

impl State {
  fn start() -> Self {
    Self {
      ore: 0,
      clay: 0,
      obsidian: 0,
      geode: 0,

      robot_ore: 1,
      robot_clay: 0,
      robot_obsidian: 0,
      robot_geode: 0,
    }
  }

  fn tick_no_new_robot(&self) -> Self {
    Self {
      ore: self.ore + self.robot_ore,
      clay: self.clay + self.robot_clay,
      obsidian: self.obsidian + self.robot_obsidian,
      geode: self.geode + self.robot_geode,

      robot_ore: self.robot_ore,
      robot_clay: self.robot_clay,
      robot_obsidian: self.robot_obsidian,
      robot_geode: self.robot_geode,
    }
  }

  fn tick_new_ore_robot(&self, blueprint: &BluePrint) -> Option<Self> {
    if self.ore < blueprint.ore_cost_ore {
      return None;
    }

    Some(
      Self {
        ore: self.ore + self.robot_ore - blueprint.ore_cost_ore,
        clay: self.clay + self.robot_clay,
        obsidian: self.obsidian + self.robot_obsidian,
        geode: self.geode + self.robot_geode,
  
        robot_ore: self.robot_ore + 1,
        robot_clay: self.robot_clay,
        robot_obsidian: self.robot_obsidian,
        robot_geode: self.robot_geode,
      }
    )
  }

  fn tick_new_clay_robot(&self, blueprint: &BluePrint) -> Option<Self> {
    if self.ore < blueprint.ore_cost_clay {
      return None;
    }
    
    Some(
      Self {
        ore: self.ore + self.robot_ore - blueprint.ore_cost_clay,
        clay: self.clay + self.robot_clay,
        obsidian: self.obsidian + self.robot_obsidian,
        geode: self.geode + self.robot_geode,

        robot_ore: self.robot_ore,
        robot_clay: self.robot_clay + 1,
        robot_obsidian: self.robot_obsidian,
        robot_geode: self.robot_geode,
      }
    )
  }

  fn tick_new_obsidian_robot(&self, blueprint: &BluePrint) -> Option<Self> {
    if self.ore < blueprint.ore_cost_obsidian || self.clay < blueprint.clay_cost_obsidian {
      return None;
    }

    Some(
      Self {
        ore: self.ore + self.robot_ore - blueprint.ore_cost_obsidian,
        clay: self.clay + self.robot_clay - blueprint.clay_cost_obsidian,
        obsidian: self.obsidian + self.robot_obsidian,
        geode: self.geode + self.robot_geode,
  
        robot_ore: self.robot_ore,
        robot_clay: self.robot_clay,
        robot_obsidian: self.robot_obsidian + 1,
        robot_geode: self.robot_geode,
      }
    )
  }

  fn tick_new_geode_robot(&self, blueprint: &BluePrint) -> Option<Self> {
    if self.ore < blueprint.ore_cost_geode || self.obsidian < blueprint.obsidian_cost_geode {
      return None;
    }

    Some(
      Self {
        ore: self.ore + self.robot_ore - blueprint.ore_cost_geode,
        clay: self.clay + self.robot_clay,
        obsidian: self.obsidian + self.robot_obsidian - blueprint.obsidian_cost_geode,
        geode: self.geode + self.robot_geode,
  
        robot_ore: self.robot_ore,
        robot_clay: self.robot_clay,
        robot_obsidian: self.robot_obsidian,
        robot_geode: self.robot_geode + 1,
      }
    )
  }
}

struct BluePrint {
  ore_cost_ore: i32,

  ore_cost_clay: i32,

  ore_cost_obsidian: i32,
  clay_cost_obsidian: i32,

  ore_cost_geode: i32,
  obsidian_cost_geode: i32,

  max_ore_cost: i32,
}

impl BluePrint {
  fn parse(string: String) -> Result<Self, ParseIntError> {
    let words: Vec<&str> = string.split(" ").collect();

    let ore_cost_ore = words[6].parse::<i32>()?;
    let ore_cost_clay = words[12].parse::<i32>()?;
    let ore_cost_obsidian = words[18].parse::<i32>()?;
    let clay_cost_obsidian = words[21].parse::<i32>()?;
    let ore_cost_geode = words[27].parse::<i32>()?;
    let obsidian_cost_geode = words[30].parse::<i32>()?;

    let max_ore_cost = [ore_cost_ore, ore_cost_clay, ore_cost_obsidian, ore_cost_geode].iter().max().unwrap().clone();

    Ok(
      Self {
        ore_cost_ore,
        ore_cost_clay,
        ore_cost_obsidian,
        clay_cost_obsidian,
        ore_cost_geode,
        obsidian_cost_geode,
        max_ore_cost
      }
    )
  }
}

fn maximum_geodes(total_time: i32, blueprint: BluePrint) -> i32 {
  let mut states = LinkedList::<(i32, State)>::new();
  let mut seen_states = HashSet::<State>::new();
  let mut result = i32::MIN;

  states.push_back((total_time, State::start()));

  loop {
      let wrapped_state = states.pop_front();
      if wrapped_state.is_none() {
        break;
      }

      let (time, mut state) = wrapped_state.unwrap();

      if time == 0 {
        result = cmp::max(result, state.geode);
        continue;
      }

      if seen_states.contains(&state) {
        continue;
      }
      seen_states.insert(state.clone());

      if state.robot_ore > blueprint.max_ore_cost {
          continue;
      }
      if state.robot_clay > blueprint.clay_cost_obsidian {
          continue;
      }
      if state.robot_obsidian > blueprint.obsidian_cost_geode {
          continue;
      }

      if state.ore > time * blueprint.max_ore_cost - (time - 1) * state.robot_ore {
        state.ore = time * blueprint.max_ore_cost - (time - 1) * state.robot_ore;
      }
      if state.clay > time * blueprint.clay_cost_obsidian - (time - 1) * state.robot_clay {
        state.clay = time * blueprint.clay_cost_obsidian - (time - 1) * state.robot_clay;
      }
      if state.obsidian > time * blueprint.obsidian_cost_geode - (time - 1) * state.robot_obsidian {
        state.obsidian = time * blueprint.obsidian_cost_geode - (time - 1) * state.robot_obsidian;
      }

      states.push_back((time - 1, state.tick_no_new_robot()));
      if let Some(new_state) = state.tick_new_ore_robot(&blueprint) {
        states.push_back((time - 1, new_state));
      }
      if let Some(new_state) = state.tick_new_clay_robot(&blueprint) {
        states.push_back((time - 1, new_state));
      }
      if let Some(new_state) = state.tick_new_obsidian_robot(&blueprint) {
        states.push_back((time - 1, new_state));
      }
      if let Some(new_state) = state.tick_new_geode_robot(&blueprint) {
        states.push_back((time - 1, new_state));
      }
  }

  result
}

fn main() -> Result<(), &'static str> {
  let args: Vec<String> = env::args().collect();

  if args.len() != 2 {
    panic!("Expected exactly 1 argument, got {}", args.len() - 1);
  }

  if let Ok(lines) = read_lines(&args[1]) {
    let mut result = 1;

    for (i, line) in lines.take(3).enumerate() {
      let blueprint = BluePrint::parse(line.unwrap()).unwrap();

      let geodes = maximum_geodes(32, blueprint);

      println!("{}: {}", i + 1, geodes);

      result *= geodes;
    }

    println!("{}", result);    
  } else {
    panic!("Failed to read file");
  }

  Ok(())
}

// The output is wrapped in a Result to allow matching on errors
// Returns an Iterator to the Reader of the lines of the file.
fn read_lines<P>(filename: P) -> io::Result<io::Lines<io::BufReader<File>>>
where P: AsRef<Path>, {
    let file = File::open(filename)?;
    Ok(io::BufReader::new(file).lines())
}