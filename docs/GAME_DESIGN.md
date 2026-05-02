# Fable - Game Design Document

## Core Concept
A narrative-driven roguelike deckbuilder where story choices, character identity, and the Passion system create runs that feel personal and unique. Emphasizes the intrigue and mystery of the unknown over pure mechanical optimization.

## Genre & Inspirations
- **Primary**: Slay the Spire (combat model, deckbuilding loop, map navigation)
- **Narrative**: Visual novel segments that determine realm state before map navigation
- **Art Reference**: Skul: The Hero Slayer (pixel art characters, scroll-framed illustrated narrative scenes, warm sepia/illustrated style for story moments)

---

## Game Flow

### Run Structure
```
Character Select
  -> Act 1: Perk Selection -> Story VN -> Realm Config -> Map Navigation -> Boss
  -> Act 2: Perk Selection -> Story VN -> Realm Config -> Map Navigation -> Boss
  -> Act 3: Perk Selection -> Story VN -> Realm Config -> Map Navigation -> Boss
  -> Major Boss -> (possible Final Boss) -> Victory
```

### Act Continuity
Acts are **mainly self-contained** narratively, but with two key exceptions:
- **Realm Prestige**: Offered **post-boss**. Player can choose to replay a realm with stronger enemies in exchange for higher-tier (next act's) rewards. The prestige VN **builds off the choices of the original VN**, creating a continuation rather than a reset. This keeps permutations manageable for development.
- **Two-Act Realms**: Some realms can span two acts — the prior realm continues or strongly influences the realm ahead. Story elements set this up.

These create variety in run structure without requiring every act to be narratively entangled.

### Per-Act Flow (detailed)
1. **Perk Selection** — Player picks 1 of 3 offered perks (drawn from both universal and character-specific pools) to help define the run's direction
2. **Story (Visual Novel)** — A narrative segment with branching choices. Choices:
   - Affect Passion meter
   - Determine the configuration of the realm (map) about to be entered
   - May provide direct rewards (cards, equipment, buffs/debuffs)
3. **Realm Configuration** — The VN choices have now set variables for the realm:
   - Number of encounters
   - Buffs/debuffs active (and duration)
   - Other realm-specific settings
   - Randomized from a pool unless determined by the previous realm's story
   - Can stack across acts if story elements set it up
4. **Map Navigation** — STS-style node map, but the map layout/contents were shaped by the story
5. **Boss** — Major boss fitting the area's theme

---

## Characters (3 at launch)

Each character has:
- **Primary Personality** — Defines their natural playstyle and core card pool
- **Secondary Personality** — An alternative build direction that emerges through low Passion
- **Countenance** — Personality traits that naturally lead the player toward certain story choices
- **Unique Card Pool** — Cards exclusive to this character (primary + secondary sets)
- **Starting Deck** — ~8 cards: 3 attacks, 3 defends, 2 character-specific cards (flexible per character if needed)
- **Passion Thresholds** — Character-specific breakpoints for the Passion tiers

### Character 1: The Emo Hybrid Caster
- **Primary Personality (High Passion)**: Magic — big swingy turns, exhaust-for-power effects, intangibility, evasion (immune to X attacks, usually exhausts), DoT, multi-hit, short-lived power buffs. High risk/high reward.
- **Secondary Personality (Low Passion)**: Physical — consistent block, reliable damage, straightforward combat skills. The safe path that trades ceiling for floor.
- **Corruption Arc**: A caster with immense magical potential who, due to a troubled background, shies away from using his magic. Think Richter Belmont from Castlevania: Nocturne — someone who defaults to physical combat but unlocks their real power when inspired. Passion comes from using magic successfully / rebuking his warrior identity. Low passion = retreating into militant physicality.
- **Design Notes**: The cleanest dual-build of the three — magic and physical are distinct enough to feel like two different characters. Primary cards sacrifice resources (exhaust, self-damage) for explosive turns. Secondary cards are reliable but lack the ceiling. Some cards trade self-damage + passion damage for high damage with rider effects, creating interesting risk/reward decisions. Magic and physical cards should have minimal overlap in support cards, so committing to one path is a real choice.

### Character 2: The Hotheaded Mage
- **Primary Personality (High Passion)**: Destruction — high energy, explosive, aggressive cards
- **Secondary Personality (Low Passion)**: Survivability — defensive cards, but slightly below average quality
- **Corruption Arc**: An aggressive powerhouse forced into caution. Low Passion is explicitly punishing — they are *bad* at playing it safe. This makes them the "high risk" character who is naturally incentivized to stay high Passion.
- **Design Notes**: The asymmetry is the selling point. High Passion feels powerful and rewarding. Low Passion feels like a struggle. This creates the strongest mechanical pressure to maintain Passion, making enemy Passion-drain attacks especially threatening against this character.

### Character 3: The Pensive Ranger
- **Primary Personality (High Passion)**: Tactical Utility — card draw, cycling, combo enablers, thinking on the fly
- **Secondary Personality (Low Passion)**: Safe/Methodical — straightforward, reliable, but inflexible cards
- **Corruption Arc**: A tactical thinker who loses their edge and becomes rigid/predictable. The subtlest transformation — both modes are functional, but high Passion enables creative problem-solving while low Passion forces a more linear approach.
- **Design Notes**: This character rewards skilled players who can leverage card draw and utility into complex turns. The corruption arc doesn't make them weaker per se — just less interesting to pilot. The "safe" cards are reliable but boring, which is a different kind of punishment than Character 2's explicitly worse cards.

---

## Passion System

### Overview
The Passion meter reflects how aligned the player's choices are with what their character would want to do. It is a core identity mechanic, not a side system.

### Structure
- **Discrete tiers with breakpoints** (not a smooth 0-100 slider)
- **Persists across the entire run** (does not reset per act)
- **Enemies can target it** — some enemy moves directly affect Passion
- **Cards can interact with it** — specific cards cost or grant Passion as part of their effect (see Combat section)

### Five Tiers

| Tier | Name | Range | Card Reward Split |
|------|------|-------|-------------------|
| 5 | **Blazing** | 80-100 | 2 primary + 1 general |
| 4 | **Inspired** | 60-79 | 1 primary + 2 general |
| 3 | **Steady** | 40-59 | 3 general |
| 2 | **Wavering** | 20-39 | 1 secondary + 2 general |
| 1 | **Hollow** | 0-19 | 2 secondary + 1 primary |

Numeric range is 0-100, starting value 60 (Inspired). Hollow offers 1 primary card as a lifeline — even at the character's lowest, their original identity calls to them.

### Zone Penalty (Off-Type Damage Nerf)
At extreme tiers, cards not native to the current identity deal reduced damage (25% penalty, damage only):
- **Blazing/Inspired at extreme (Blazing)**: Secondary-personality cards deal 25% less damage
- **Wavering/Hollow at extreme (Hollow)**: Primary-personality cards deal 25% less damage
- **Inspired/Steady/Wavering**: No penalty — safe zones where all cards play at full power
- **Neutral cards**: Never penalized in any tier

This creates a meaningful tradeoff for pushing to extremes: stronger card rewards from your dominant pool, but your off-type cards weaken. The penalty is light enough that players don't need to agonize every turn, but heavy enough to reward commitment.

### Corruption Arc (End Goal)
Low Passion isn't just "bad" — it's an alternative build path. A player who leans into low Passion can end a run with a deck fully suited to the character's secondary personality. This functions as a corruption arc:
- The character loses faith in their original approach
- The secondary personality takes over
- The deck transforms to support a fundamentally different strategy

### Passion Volatility (Per Character)
`passion_volatility` is primarily a multiplier for **enemy demoralization attacks**, not player card effects. Per-character passion pacing is handled through card design — each character's cards have different passion values baked in.

- **Hotheaded Mage**: Highest volatility. Enemy passion attacks hit hardest (emotional, reactive).
- **Emo Hybrid Caster**: Moderate volatility. Middle ground.
- **Pensive Ranger**: Lowest volatility. Most resistant to enemy passion manipulation (deliberate, measured).

This adds another layer to character selection — the same enemies feel different depending on who you pick.

### Passion Card Values
Passion-shifting cards use values in the **3-8 range** (not 1-2). On a 100-point scale with 20-point-wide tiers, this means:
- A single passion card moves you ~15-40% of a tier
- It takes 3-6 dedicated card plays to cross a full tier boundary
- This creates meaningful but not instant shifts — players commit over several turns, not one card

Every passion tier should have both passion-raising and passion-lowering cards available, so the player always has agency to push in either direction regardless of current state.

### Open Questions
- What specific enemy moves target Passion (drain, lock, invert?)
- Whether Passion affects non-card systems (story options, perk availability, boss behavior)

---

## Combat System

### Model: STS-Style
- 1 player character vs 1-N enemies
- Turn-based
- **3 energy per turn** (standard, same for all characters)
- Draw pile, hand, discard pile, exhaust pile
- Status effects / buffs / debuffs
- Enemy intent system (telegraph next action)
- **Card upgrades**: Same paths as STS — rest sites, shops, events, story rewards

### Energy & Passion
Energy starts at 3 per turn for all characters. Passion-based energy influence is being considered as a **balancing lever first, feature second** — if the base 3 energy creates balance problems across characters/tiers, Passion-energy interaction is an available knob. It will not be designed as a marquee feature unless balance demands it.

### Passion as Card Mechanic
Certain cards have Passion costs or gains as part of their design:
- **Passion-spending cards**: Stronger effects, but lower your Passion (e.g., "Deal 15 damage. -5 Passion.")
- **Passion-building cards**: Weaker effects, but raise your Passion (e.g., "Gain 6 Block. +5 Passion.")
- **Most cards are Passion-neutral** — Passion interaction is a specific card property, not a universal consequence of card type
- **Passion values on cards**: Typically in the 3-8 range. At this scale, 3-6 card plays cross a tier boundary.

This creates deckbuilding tension: a -5 Passion card is great for a corruption arc player but risky for someone maintaining Blazing. Same card, different strategic value.

### Differentiators from STS
- **Passion is present in combat** — enemies can target it, specific cards cost/grant it
- **Realm modifiers active during combat** — buffs/debuffs from realm config persist
- **Character countenance may affect available options** — personality-driven combat choices

---

## Realm Configuration

### How It Works: Direct Mapping
VN choices **directly set specific realm variables** through narrative logic. Each choice has authored consequences that ripple into multiple realm settings. The realm should feel like a living world shaped by the player's story decisions.

**Example**: Angering the local nobility during the VN could:
- Increase shop prices for the realm
- Increase probability of enemy combat card rewards being upgraded or higher rarity (the nobility sends stronger forces, but defeating them yields better spoils)

**Example**: Encountering warring elementals and choosing a side could:
- Grant elemental-aligned buffs/debuffs for the realm
- Change enemy composition to favor the opposing faction
- Provide a specific reward tied to the chosen faction

### Design Philosophy
- A player entering a realm should be able to take a completely different path than another player
- Realms should feel like living worlds that grow/change between runs
- Realm prestige should also reflect changes (the world remembers what happened last time)

### Configurable Variables
VN choices can affect any combination of:
- Number and type of encounters
- Active buffs/debuffs and their duration
- Enemy composition / difficulty modifiers
- Shop pricing and inventory quality
- Card reward rarity/upgrade probability
- Available node types on the map
- Realm-specific environmental effects

### Data Flow
```
VN Choice -> Direct Realm Variable Changes -> Map Generation -> Player Navigates
```
Each VN choice node defines its realm variable outputs explicitly. Tags may supplement for secondary effects, but the primary mapping is direct and hand-authored.

---

## Map & Node Types

### Map Generation
The map is STS-style (branching paths, choose your route) but its layout and contents are influenced by the Story VN choices. The map is revealed after realm configuration is complete.

### Node Types (tentative)
- **Combat** — Standard enemy encounter
- **Elite/Mini-boss** — Harder fight, better rewards
- **Story Event** — Narrative choice with consequences
- **Rest** — Heal or upgrade cards
- **Shop** — Purchase cards, relics, equipment, card removal (at least 2 per run, frequency TBD)
- **Mystery** — Unknown until entered, could be anything. Frequency roughly on par with STS unknown nodes (the realm config already injects enough uncertainty — mystery nodes don't need to pile on)
- **Boss** — Act-ending boss fight

---

## Meta Progression

### Between Runs
- **Card unlocks** — New cards added to character pools after run milestones
- **Run history** — Record of past runs (character, choices, outcome, passion path)
- **Character unlocks** — If applicable (may start with all 3 available)

---

## Art Direction

### Style: Pixel + Illustration Hybrid (Skul-inspired)
- **In-game / combat**: Pixel art sprites and environments
- **Narrative scenes**: Scroll-framed illustrated panels (warm, sepia-toned, painterly)
- **Card art**: TBD — could be pixel, illustrated, or a mix
- **UI elements**: Ornate frames, scroll/parchment motifs
- **Source**: Art will be sourced externally (not AI-generated during development)

---

## Economy & Items

### Currency
- Gold/currency exists (details TBD)
- Shops available on the map (at least 2 per run)

### Relics
STS-style passive bonuses. Unique stacking effects that compound over a run. Found through combats, events, shops, and story rewards.

### Equipment
Separate from relics. Stable, consistent effects that can be **swapped out** if a better option appears. Provides a baseline of power that the player can adjust as their build evolves.

**4 slots**: Head, Arms, Torso, Legs

---

## Open Design Questions

These are content/tuning decisions to be made during development, not system blockers:

1. Story branching complexity — how many paths per VN segment?
2. Difficulty scaling / ascension system for replayability beyond the base run?
3. Realm Prestige scaling — how much harder? What "next act rewards" means in practice?
4. Two-Act Realm triggers — what story conditions cause a realm to span two acts?
5. Character names and detailed lore/countenance descriptions
6. Shared (non-character-specific) card pool — does one exist? How large?
7. Final boss identity and design (fixed for now, deterministic selection open for later)
8. Specific enemy Passion-targeting move types (designed alongside enemies)
9. Card pool sizes per character (designed alongside cards)
10. How realm prestige "remembers" prior run choices (what persists, what resets)

## Resolved Decisions Log

- Engine: Godot 4 with GDScript
- 3 characters at launch (Emo Hybrid Caster, Hotheaded Mage, Pensive Ranger)
- 5 Passion tiers (Blazing / Inspired / Steady / Wavering / Hollow)
- Passion volatility varies per character (Hotheaded > Hybrid > Pensive)
- Starting deck: ~8 cards (3 attack, 3 defend, 2 character-specific)
- 3 energy per turn, all characters (Passion-energy as balance lever, not feature)
- Perk selection: pick 1 of 3, drawn from universal + character-specific pools
- Card upgrades: STS model (rest sites, shops, events, story rewards)
- Realm Prestige: post-boss choice, prestige VN builds off original VN choices
- Acts mainly self-contained, with prestige and two-act realm exceptions
- Mystery node frequency: on par with STS (realm config handles uncertainty)
- Shops: at least 2 per run
- Items: both relics (stacking passives) and equipment (swappable, 4 slots: head/arms/torso/legs)
- Art: pixel + illustration hybrid (Skul-inspired), externally sourced
- Final boss: fixed for now
- Passion as card mechanic: specific cards cost/grant Passion (not all cards, just designed ones)
- Passion breakpoints: 0-100 range, tiers at 80/60/40/20 (Blazing/Inspired/Steady/Wavering/Hollow), start at 60
- Passion card values: 3-8 range (3-6 plays to cross a tier)
- Passion volatility: primarily scales enemy demoralization, not player cards
- Card reward split by tier: Blazing 2P+1G, Inspired 1P+2G, Steady 3G, Wavering 1S+2G, Hollow 2S+1P
- Zone penalty: Blazing/Hollow only, 25% damage nerf to off-type cards, neutrals exempt
- Emo Hybrid Caster: Primary=magic (swingy, exhaust, intangible, evasion), Secondary=physical (consistent block/damage)
- VN → Realm: direct mapping (hand-authored consequences per choice, not tag-based)
- Realms should feel like living worlds that change between runs/prestiges
