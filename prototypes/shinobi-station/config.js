// PROTOTYPE - NOT FOR PRODUCTION
// Question: How far can Aseprite-MCP pixel art and an AI build take a ninja village you can sit and watch?
// Date: 2026-11-16
// Every tuning value lives here, each with value, min, max and step. The game reads them live
// through tune.<name> (index.html); the tweak panel, an add-on, writes them back here.
window.CONFIG = {
  seed: 1, // every random call reads rng(), seeded from this (or ?seed= in the address)
  volume: { value: 0.5, min: 0, max: 1, step: 0.05 },

  // --- the day ---
  day_seconds: { value: 240, min: 60, max: 900, step: 10 },     // real seconds for one full day at x1
  start_time: { value: 0.27, min: 0, max: 1, step: 0.01 },      // time of day at start (0 = midnight, 0.5 = noon)
  wake_time: { value: 0.25, min: 0.15, max: 0.4, step: 0.01 },  // villagers leave home from here
  home_time: { value: 0.76, min: 0.6, max: 0.9, step: 0.01 },   // villagers head home from here
  night_strength: { value: 0.62, min: 0, max: 0.9, step: 0.02 },// how dark the night tint gets (0..1)
  speed_2: { value: 3, min: 2, max: 6, step: 1 },               // multiplier on key 2
  speed_3: { value: 8, min: 4, max: 20, step: 1 },              // multiplier on key 3

  // --- people ---
  residents: { value: 18, min: 4, max: 30, step: 1 },           // grown-up villagers with homes
  kids: { value: 3, min: 0, max: 6, step: 1 },                  // kids who play tag in the day
  walk_speed: { value: 1.1, min: 0.4, max: 3, step: 0.1 },      // tiles per second, walking
  run_speed: { value: 2.8, min: 1, max: 6, step: 0.1 },         // tiles per second, ninjas on errands
  kid_speed: { value: 2.3, min: 1, max: 5, step: 0.1 },         // tiles per second, kids running
  idle_min: { value: 3, min: 0, max: 20, step: 1 },             // seconds a villager lingers at a spot (min)
  idle_max: { value: 10, min: 1, max: 40, step: 1 },            // seconds a villager lingers at a spot (max)
  errand_chance: { value: 0.18, min: 0, max: 1, step: 0.02 },   // chance a ninja sprints to the next spot

  // --- the train ---
  train_interval: { value: 45, min: 15, max: 180, step: 5 },    // seconds between trains
  train_dwell: { value: 9, min: 3, max: 30, step: 1 },          // seconds stopped at the station
  train_speed: { value: 4.5, min: 1, max: 10, step: 0.5 },      // tiles per second at full speed
  train_cars: { value: 2, min: 1, max: 4, step: 1 },            // carriages behind the locomotive
  train_first: { value: 6, min: 0, max: 60, step: 1 },          // seconds before the first train
  stop_i: { value: 10.4, min: 6, max: 14, step: 0.1 },          // where the loco's front stops (tile i)

  // --- events ---
  event_gap: { value: 28, min: 5, max: 120, step: 1 },          // seconds between small events (day)
  first_event: { value: 10, min: 0, max: 60, step: 1 },         // seconds before the first event
  spar_seconds: { value: 16, min: 6, max: 40, step: 1 },        // how long a sparring match lasts
  rooftop_gap: { value: 22, min: 5, max: 90, step: 1 },         // seconds between rooftop dashes
  rooftop_speed: { value: 4, min: 1, max: 8, step: 0.5 },       // tiles per second over the roofs
  log_seconds: { value: 9, min: 3, max: 30, step: 1 },          // how long a log line stays
};
