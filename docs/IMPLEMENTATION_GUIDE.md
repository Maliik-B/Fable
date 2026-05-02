# Fable - Implementation Guide

Research-backed architectural patterns and strategies for building Fable in Godot 4 with GDScript. Compiled from community best practices, open-source deckbuilder projects, and Godot documentation (April 2026).

---

## Card Data: Custom Resources (.tres)

All card definitions use custom Resources, not JSON. This is the consensus across every successful Godot 4 deckbuilder.

**Why Resources:**
- Type safety (enforced data types vs raw JSON)
- Editor integration (create/edit cards in Godot's Inspector)
- Nested Resources (a card contains an array of `CardEffect` Resources)
- Native serialization (`.tres` files load/save automatically)
- Refactoring safety (if the Resource script changes, existing `.tres` files adapt)

**Resource sharing pitfall:** Godot loads Resources once and shares references by default. If the same `.tres` is assigned to multiple card instances, modifying one modifies all. Additionally, `Resource.duplicate(true)` has a known bug where it does NOT properly duplicate sub-resources stored in Arrays or Dictionaries (Godot issue #74918).

**Solution:** Read-only template Resources are fine to share. For mutable per-instance state (upgraded cards, temporary cost mods), implement a custom `duplicate_card()` method that deep-copies nested arrays/effects manually.

---

## Composable Card Effects System

The single most important architecture decision for scaling to hundreds of cards.

**Pattern:** Create reusable `CardEffect` Resource subclasses, then compose them in arrays on each card definition. Most cards are pure data — no new scripts needed.

**Base class:**
```gdscript
class_name CardEffect
extends Resource

@export var value: int = 0

func apply(source, target, battle_state) -> void:
    pass  # Override in subclasses
```

**Concrete subclasses:**
- `DamageEffect` — deal damage to target
- `BlockEffect` — gain block on source
- `DrawEffect` — draw N cards
- `PassionEffect` — modify Passion by +/- value (Fable-specific)
- `StatusApplyEffect` — apply a status effect to target
- `HealEffect` — restore HP
- `EnergyEffect` — gain/lose energy

**Card composition examples (no new code per card):**
- Strike: `[DamageEffect(6)]`
- Defend: `[BlockEffect(5)]`
- Pommel Strike: `[DamageEffect(9), DrawEffect(1)]`
- Passionate Strike: `[DamageEffect(12), PassionEffect(-1)]`

---

## Signal Architecture: Event Bus

A single `Events` autoload with typed signals organized by domain prefix. Systems communicate through this bus instead of direct references, keeping combat engine, UI, and passion system decoupled.

**When to use what:**
| Pattern | Use When |
|---------|----------|
| Direct signals | Emitter and listener are in the same scene or parent-child |
| Event bus | Cross-system communication (combat <-> UI <-> passion) |

**Fable event flow example:**
```
Card Played -> Events.card_played(card_data, target)
  -> BattleManager resolves effects
  -> PassionSystem adjusts if card has PassionEffect
  -> UI animates card to discard

Passion Changed -> Events.passion_changed(old_tier, new_tier, value)
  -> UI updates Passion meter
  -> CardRewardSystem adjusts available pool
  -> Enemy AI may react

VN Choice -> Events.vn_choice_made(choice_data)
  -> RealmConfig updates realm variables
  -> PassionSystem adjusts Passion value
```

**Best practices:**
- Connect in code, not in the editor (easier to track)
- Disconnect in `_exit_tree()` to prevent ghost connections
- Use typed signal parameters
- Performance is not a concern (~2,300 emissions/frame costs ~1ms)

---

## State Management: Three Layers

### RunState (persists across entire run)
Gold, relics, current deck, Passion value, equipment, perks, RNG seed, floors climbed.

### CharacterStats (persists per character during run)
Health, max health, base stats, between-combat status effects.

### BattleState (transient, combat only)
Hand, draw pile, discard pile, exhaust pile, current energy, enemy states, turn counter, active status effects.

### Autoloads: Use Sparingly
**Good autoloads:** `Events` (signal bus), `RunManager` (run lifecycle), `AudioManager`, `RNG` (deterministic random).

**Anti-patterns:**
- Never access Autoloads in `_init()` — they initialize sequentially and may be null
- Never use Autoloads for pure data containers — use `static var` in a `class_name` script
- Never create circular dependencies between Autoloads
- Never store scene-specific data globally (creates God Objects)

---

## Combat State Machine

Enum-driven state machine prevents invalid plays and locks input during animations.

```gdscript
enum BattleState {
    PLAYER_TURN_START,   # Draw cards, reset energy, apply start-of-turn effects
    PLAYER_TURN,         # Player can play cards
    TARGETING,           # Player choosing a target
    ANIMATING,           # Effects resolving, input locked
    PLAYER_TURN_END,     # Discard hand, apply end-of-turn effects
    ENEMY_TURN,          # Enemies execute intents
    BATTLE_WON,
    BATTLE_LOST
}
```

### Card Resolution Flow
```
Player selects card -> Validate (enough energy? valid target?) ->
Deduct energy -> Execute effects[] in order ->
Move card to discard (or exhaust) -> Update UI ->
Check for death/victory
```

### Status Effect System
Each combatant has a `StatusHandler` that manages a dictionary of active effects. At start/end of each turn, the handler ticks durations and triggers effects. Status effects like Vulnerable/Weak modify damage calculations via interception.

**Realm modifiers reuse this system** with a `REALM` duration type (persists across combats within a realm), avoiding duplicate systems.

---

## Deterministic RNG

Critical for seeded runs, save/load correctness, and debugging.

- Use `RandomNumberGenerator` instances, not global `randf()`/`randi()`
- Separate RNG tracks per system: deck shuffle, enemy AI, loot drops, event rolls
- Save and restore RNG state in save files
- Managed via a dedicated `RNG` autoload

---

## UI Strategy

### Card Hand
**Phase 1 (prototype):** `HBoxContainer` — automatic layout, immediate results.
**Phase 2 (polish):** Custom fan layout using parabolic math for arc and rotation.

### Card Interaction
- Use Control nodes for cards (not custom `_draw()`) — preserves input handling and layout
- Tweens for all animations (draw, play, discard, hover) — lightweight, chainable, auto-cleanup
- Hover: scale up 1.3-1.5x, raise z_index, push neighbors apart
- Start with click-to-play; drag-to-play is a polish feature

### Tooltips
Emit `card_tooltip_requested(card_data, position)` signal. A dedicated `TooltipManager` listens and displays. Decoupled from card logic.

---

## Passion System Integration

Passion is a first-class citizen, not bolted on.

- **PassionState Resource**: 5 tiers, per-character volatility curves, breakpoint values
- **PassionSystem autoload**: Manages the state, emits signals on changes
- Other systems query Passion but never modify it directly (go through PassionSystem)
- Enemy Passion-targeting moves (drain, lock, invert) fit as `PassionEffect` or dedicated `StatusEffect` subtypes

---

## Build Order

Each phase plugs into the signal bus. Build bottom-up:

1. **Project scaffolding** — directory structure, `project.godot`, autoloads
2. **Core data structures** — `CardData`, `CharacterData`, `StatusEffectData`, `PassionState` Resources
3. **Combat engine** — card play loop, energy, draw/discard piles
4. **Enemy system** — enemy data, intent selection, action execution
5. **Status effects** — buff/debuff application, tick, removal
6. **Passion mechanics** — tier calculation, volatility, card pool gating
7. **Map navigation** — STS-style branching node map
8. **VN + realm config** — story segments, realm variable setting
9. **Perks, relics, equipment** — progression systems
10. **Polish** — fan hand layout, animations, audio, art integration

---

## Reference Projects

Study these for patterns (don't fork as a base):

- **guladam/deck_builder_tutorial** — Best learning resource. Clean Resource-based cards, Events bus, Run controller pattern. Covers combat, map gen, relics, shops, save/load.
- **DesirePathGames/Slay-The-Robot** — Most feature-complete. JSON-driven (for modding), action system with interceptors/validators, deterministic RNG, mod support. Godot 4.4, MIT license.
- **chun92/card-framework** — Professional card game addon. Good drag-and-drop, container transitions, card animations.
- **Dialogic 2** — VN/dialogue system for Godot 4. Potential option for Fable's story segments, or build a lightweight custom system for tighter realm-config integration.

## Common Pitfalls to Avoid

1. **Resource sharing corruption** — duplicate mutable card instances manually
2. **Over-engineering early** — start with simplest card play loop, iterate
3. **Tight coupling** — use Events bus, not direct cross-system references
4. **Custom drawing too early** — use Control nodes first, custom rendering is a polish step
5. **Non-deterministic RNG** — use separate `RandomNumberGenerator` instances per system
6. **Monolithic BattleManager** — split into BattleManager (turn flow), PileManager (deck ops), StatusHandler (per combatant), Hand (display/input)
7. **Input during animations** — lock input via `ANIMATING` state in the combat state machine
