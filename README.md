# Fable -- Narrative Deckbuilder

A roguelike deckbuilder in Godot 4 where story choices shape gameplay. Inspired by Slay the Spire's combat loop, Fable adds a narrative layer with branching visual novel segments, a passion system that shifts combat dynamics, and dual-personality characters that evolve across acts.

![Godot 4.x](https://img.shields.io/badge/Godot-4.x-blue?logo=godotengine&logoColor=white)
![GDScript](https://img.shields.io/badge/GDScript-478CBF?logo=godotengine&logoColor=white)
![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)

## Features

- **Passion System** -- A meter influenced by story choices that shifts characters between primary and secondary personalities, changing available cards and combat strategy
- **Dual-Personality Characters** -- Each character has two distinct playstyles (e.g., magic vs. physical) that emerge based on Passion level
- **Narrative-Driven Runs** -- Visual novel segments between acts configure the realm ahead (encounter count, active buffs/debuffs, map layout)
- **Combat Engine** -- Turn-based card combat with energy, block, status effects, and a draw/discard/exhaust pile system
- **Procedural Map** -- Slay the Spire-style node maps with combat, event, rest, shop, and boss encounters
- **Perk System** -- Per-act perk selection from universal and character-specific pools
- **Card & Relic Pools** -- Categorized cards (attack, skill, power) and relics with rarity tiers

## Project Structure

```
scenes/          # Combat, map, event, shop, rest, reward scenes
scripts/
  autoloads/     # Audio, events, RNG, run management
  core/          # Card data, combat engine, enemy AI, map generator,
                   passion state, status effects, pile management
addons/          # Third-party editor plugins
docs/            # Game design doc, architecture, implementation guide
```

## Status

In development. Core systems (combat, map generation, card/relic pools, event system, passion mechanics) are implemented. Narrative content and visual polish are next.

## License

[MIT](LICENSE)
