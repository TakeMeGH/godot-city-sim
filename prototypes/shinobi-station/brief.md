# Game Brief: Shinobi Station

## In your words
in general i want to make village simulation but the theme is ninja and it have train in the village also. this project i just wan to test how far ai and ai generated art using asesprite mcp can get me. so we dont need any gameplay or something i just want to have village simulation that i can see and ilde

Change before build: i prefer this ninja style like naruto.. i really like konoha envi type. and make it isometric

Change before build: i also want some npc running arround and maybe some small event to make it more life

After play: i want to give feedback and maybe you need to something about it. the prototype pixel art very ugly. there is guide to create it also [the Aseprite MCP drawing guide: palette ramps first, layers, coarse to fine, view after every pass, shade with intent, animate with the cel tools]. also try check great pixel art like in moonlighter, chef rpg, etc
After play: picked bigger, camera pans: 64x32 tiles, villagers about 32 px tall, a smaller village, a camera that drifts and pans

**Pitch:** A hand-pixelled ninja village lives out its day on one screen while you watch: a little steam train pulls into the station, villagers walk their routines, a dojo spars, and lanterns light up at dusk.

**Genre:** ambient village simulation (a living diorama you idle and watch)

**Controls:** none needed. Optional: Space pauses, 1/2/3 sets speed, drag or arrow keys look around, click a villager to see their name and what they're doing, H hides the HUD *(guessed)*

**Question:** How far can Aseprite-MCP pixel art and an AI build take a ninja village you can sit and watch?

**Hooks:** a steam train that runs through a ninja village; every sprite drawn in Aseprite by the AI

**Intent:** no goal to reach *(you said)* · soft or no failure *(you said)*

## Look and references
- Look: isometric pixel art drawn in Aseprite *(you said)*. A hidden ninja village in a forest valley in the spirit of Konoha *(you said)*: packed round-walled towers and boxy blocks with warm terracotta and red-orange roofs, rooftop water tanks, washing lines and cloth banners, a tall plain cliff behind, giant broad-canopy trees around. Ninjas drawn anime-style: spiky or long hair, plain metal-plated headbands, sandals, kunai pouch, each villager type with its own silhouette. Warm afternoon sun, cool blue shadows, lit windows and lantern glow at night. Signature detail: rooftop water tanks and washing lines catching the light. 1 px dark outline, top-left light, no anti-aliasing. Every figure drawn, no emoji, no plain circles
- References: Naruto's Konoha *(you said)*: the hidden-village-in-the-trees warmth, roof colours and shapes, anime ninja silhouettes. Moonlighter and Chef RPG *(you said)*: the pixel-art craft, hue-shifted ramps, textured materials, coloured selective outlines, contact shadows, leaf-cluster trees and street clutter
- View: 2D isometric *(you said)* · Camera: 64x32 tiles at native 480×270, scaled by whole numbers; it drifts slowly over the village and pans by drag or arrow keys *(you said: bigger, camera pans)*

## First minute
It's early morning in the forest clearing. Villagers step out of their doors into the streets, kids start a game of tag in the square, and ninjas head for the training ground. The train whistles in from the left, slows, and stops at the station; passengers step off and others board. A ninja dashes across the rooftops, and a small event starts: a sparring match draws a crowd. Within the minute you've seen the whole loop of the village, and the train pulls out again.

## Challenge
None, by design *(you said)*. What builds over time is the day: morning commute, midday training, dusk lanterns, night quiet, then morning again.

## Core loop
- The village runs a day on its own: the train arrives, villagers walk their routines, the dojo trains
- Dusk lights the lanterns, villagers head home, and the night train runs lit
- Morning returns and the cycle repeats. You watch, speed it up, or click someone to see what they're doing

## Goal & fail state
- No goal and no failure *(you said)*. A session feels complete after one full day: train, training, lanterns, sleep *(guessed)*

## Features
- [x] One-screen isometric village, every sprite from Aseprite: block houses and round towers with water tanks, a training ground, the station, giant trees, lanterns, track and ground
- [x] Steam train loops through, stops at the station, wheels animate, smoke puffs, villagers board and step off
- [x] Ninja villagers walk routines between home, the training ground, the station, the shop and the square, with walk cycles in four directions
- [x] Training ground with ninjas training (animated punch and kick poses)
- [x] A rooftop ninja who dashes across the roofs now and then
- [x] NPCs running around: kids playing tag, ninjas sprinting on errands
- [x] Small events, each with a one-line log: a sparring match draws a crowd, a messenger hawk lands at the station, a cat chases a bird down the street, the lantern-lighter walks the streets at dusk *(guessed: which events)*
- [x] Day and night cycle: lanterns glow at dusk, villagers go home at night *(guessed)*
- [x] Idle controls: pause, speed, click a villager for name and task *(guessed)*

## Your systems
- train in the village · in the slice
- village simulation (villagers' routines) · in the slice
- day and night · in the slice *(guessed)*
- npc running around · in the slice
- small events · in the slice

## Keep
-

## Avoid
- any gameplay: no goals, money, building, losing or score *(you said: "we dont need any gameplay")*
- art drawn in code instead of Aseprite (only the sky gradient and night tint are code)
- Naruto's names, characters, the leaf symbol, the carved faces on the cliff, the village gate and its named buildings; Moonlighter's and Chef RPG's own art, characters and UI: the look guides the art, the series' designs stay its owner's

## Out of scope
- several districts and a region map: grow it
- placing buildings or laying track yourself: add it as a feature
- the village in Godot: `/setup-engine godot` after you've played it

## Build order
1. The slice: one screen, Aseprite sprites, the train loop, walking villagers, the dojo, and one full day and night cycle with no end state

---
**Kill condition:** if the Aseprite sprites can't read as a ninja village at play size after one redraw pass *(guessed)*

**Who it's for / what they feel:** you, testing an AI art pipeline, with a calm screen to leave running *(inferred (strong))*

**Games you love / don't:** —
