# Fable - Architecture & Engine Decision

## Revised Recommendation: Godot 4 with GDScript

After researching the current landscape (April 2026), Godot 4 is the clear choice for Fable. The original consideration was web-based (TypeScript + Phaser), but several factors strongly favor Godot.

## Why Godot 4

### The Ashen Decks Problem is Solved
The core blocker with Unreal Engine was that AI assistants cannot create or edit Binary Property files (BPS) or UMG widget blueprints. Godot solves this:
- **Scene files (.tscn) are human-readable text** - can be read, written, and diffed
- **GDScript (.gd) is plain text** - Python-like, no compilation step needed
- **Resource files (.tres) are also text-based** - themes, styles, data all editable

### Genre-Proven
Slay the Spire 2 — the sequel to the game that defined the roguelike deckbuilder genre — uses Godot 4. MegaCrit switched from Unity to Godot mid-development and shipped successfully in early access (March 2026). This proves Godot handles:
- Complex card UI and hand management
- Turn-based combat systems
- Map/node navigation
- Status effect systems
- Save/load and run history

### Practical Advantages
- **Native desktop export** — Direct .exe builds for Steam, no Electron wrapper
- **Built-in UI system** — Control nodes handle card layouts, menus, HUD, passion meter
- **2D-first engine** — Unlike Unreal/Unity which are 3D-first, Godot's 2D is a first-class citizen
- **Free, MIT license** — No revenue share, no licensing fees, no runtime fees
- **Active ecosystem** — Existing deckbuilder frameworks (Slay the Robot, Card Framework) for reference
- **AI-friendly architecture** — Text-based everything, CLI-friendly, growing Claude/AI tooling

## Why NOT the Alternatives

### Web (TypeScript + Phaser 4)
- Phaser 4 released April 10, 2026 — 18 days old, too new for production reliance
- Electron wrapper adds complexity and overhead for Steam distribution
- Less proven path for commercial deckbuilders
- Would have been the top choice if Godot's text-based format didn't exist

### Unity
- Licensing concerns (the runtime fee controversy that pushed StS2 away)
- Heavier than needed for a 2D card game
- Scene files are YAML but deeply nested and harder to generate than .tscn

### Unreal Engine
- The known problem — binary formats, can't create BPS/UMG via text
- Massive overkill for 2D card game
- C++ compilation overhead

## Recommended Godot Architecture

```
fable/
  project.godot
  scenes/
    main/                  # Main menu, character select
    combat/                # Battle scene, card hand, enemy display
    story/                 # Visual novel segments (scroll-framed)
    map/                   # Node map navigation
    realm_setup/           # Realm configuration choices
    perk_select/           # Area perk selection
    ui/                    # Shared UI components (passion meter, HUD, card tooltips)
  scripts/
    core/                  # Engine-agnostic game logic
      game_state.gd        # Master state machine
      combat_engine.gd     # Card resolution, turn order, status effects
      passion_system.gd    # Passion meter: tiers, breakpoints, card pool selection
      realm_config.gd      # Realm modifier application and stacking
      run_manager.gd       # Run lifecycle, history, seed
    data/                  # Data loading and management
      card_database.gd
      character_database.gd
      story_database.gd
    enemy/
      enemy_ai.gd          # Enemy intent system, passion-targeting moves
    ui/
      card_hand.gd
      passion_display.gd
  resources/
    characters/            # .tres character definitions
    cards/                 # .tres card definitions (primary, secondary, negative pools)
    stories/               # .tres or .json story trees with branching
    enemies/               # .tres enemy definitions + move patterns
    perks/                 # .tres perk definitions
    acts/                  # .tres act structure, boss defs, realm modifier pools
  assets/
    sprites/               # Pixel art sprites
    illustrations/         # Illustrated character/scene art (Skul-style)
    ui/                    # UI elements, scroll frames, card templates
    audio/                 # SFX and music
  addons/                  # Any Godot plugins used
```

## Key Architectural Decisions

### Data-Driven Design
All game content (characters, cards, stories, perks, enemies, realm modifiers) defined as Godot Resources (.tres) or JSON. Adding content = adding data files, not rewriting systems.

### State Machine for Game Flow
```
MainMenu -> CharacterSelect -> [Act Loop:
  PerkSelection -> StoryVN -> RealmConfig -> MapNavigation -> [Node Loop:
    Combat | Event | Shop | Rest | Mystery
  ] -> Boss
] -> FinalBoss -> Victory
```

### Passion System as First-Class Citizen
Not bolted on — integrated into combat (enemies target it), rewards (card pool selection), and narrative (story choices affect it). The system needs its own dedicated manager that other systems query.

### Scene Modularity
Each major screen (combat, story, map, etc.) is its own Godot scene. Shared components (passion meter, card display) are reusable scene instances. This follows Godot's "everything is a scene" philosophy.

### Scene Modularity, continued
Each screen stays independently loadable so it can be developed and tested in isolation before wiring into the run flow.
