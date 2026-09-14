# Hero Quest 3D: Character Sheet, Inventory & Gameplay Systems

This document specifies the player progression, inventory mechanics, equipment management, item drop systems, and interactive world entities.

---

## 1. Character Sheet & Stats (`HeroQuestCharacterSheet`)

Pressing the **`C`** key toggles the full Character Sheet modal during gameplay.

### Core Character Attributes (`HeroStats`):
- **Health Points (HP)**: Current / Maximum health. Reaching 0 triggers defeat state.
- **Attack Dice / Value**: Base offensive rating derived from class archetype and equipped weapon.
- **Defense Dice / Value**: Damage mitigation derived from equipped armor and shield.
- **Movement (Tiles)**: Base movement allowance per turn or travel speed.
- **Gold Bounty**: Accumulated treasure for shopping and equipment upgrades.

### Equipment Slots (`HeroInventory`):
Characters have 4 dedicated equipment slots:
1. **Weapon Slot**: Primary offensive equipment (e.g. Iron Broadsword, Heavy Battleaxe, Wizard Staff).
2. **Armor Slot**: Defensive garments (e.g. Leather Doublet, Plate Mail, Archmage Robes).
3. **Shield Slot**: Off-hand protection (e.g. Wooden Buckler, Tower Shield).
4. **Relic / Accessory Slot**: Magical artifacts (e.g. Ring of Vitality, Amulet of Wisdom).

---

## 2. Item Database & Loot Dialog (`HeroQuestLootDialog`)

Items are registered in `ItemDatabase` with standardized rarity tiers, descriptions, and stat modifiers:

| Rarity Tier | Color Code | Characteristics |
| :--- | :--- | :--- |
| **Common** | Light Gray (`#CCCCCC`) | Standard mundane gear and basic supplies. |
| **Rare** | Sapphire Blue (`#4488FF`) | Enhanced equipment with defensive or offensive bonuses. |
| **Epic** | Amethyst Purple (`#AA44FF`) | Powerful enchanted artifacts and weapons. |
| **Legendary** | Sunburst Gold (`#FFAA00`) | Unique relics with passive modifiers or abilities. |

### Loot Collection Workflow:
- Interacting with chests or defeated encounters opens the `HeroQuestLootDialog`.
- Displays item name, rarity-colored title, item description, and stat comparison with currently equipped items.
- Provides options to **Equip Now**, **Stash in Bag**, or **Leave Item**.

---

## 3. 3D Dropped Floor Items (`HeroQuestFloorItem`)

When items are dropped from inventory or ejected when replacing equipment in a full backpack:

### Visual & Spatial Construction:
- **Base Position**: Centered on the target cell at `y = 0.15m`.
- **Pedestal Ring**: Dark metallic/stone ground ring (`y = 0.03m`, `height = 0.06m`) resting flush on the stone floor without clipping into tile geometry.
- **Hovering Relic**: Procedural or modeled mesh floating above the ring, animated with a vertical sine-bob between `y = 0.35m` and `y = 0.41m` with continuous slow Y-axis rotation.
- **Beacon Light**: Color-coded `OmniLight3D` elevated at `y = 0.45m` (`radius = 2.5m`, `energy = 0.6`) matching the item's rarity color.
- **Interactivity**: Attaches `HeroQuestInteractable` with `InteractType.ITEM` and prompt text `Press [E] or [SPACE] to pick up [Item Name]`.

---

## 4. Component Interaction Architecture (`HeroQuestInteractable`)

All interactive elements in the 3D castle attach the `HeroQuestInteractable` component.

### Design Principles:
- **No Hardcoded Node Checking**: Actors never inspect node names (e.g. `prop.name == "chest_01"`).
- **Uniform Invocation**: Actors invoke `interactable.interact(actor, context)`.
- **Interaction Types**:
  - `DOOR` / `PORTAL`: Opens or toggles passage.
  - `CHEST`: Opens chest, tests for traps, rewards gold/items.
  - `ITEM`: Collects floor relic into hero inventory.
  - `GRAVESTONE`: Displays inspectable cemetery epitaph.
  - `MINI_GAME`: Launches embedded arcade or puzzle mini-game.
  - `NPC` / `SIGN`: Displays dialogue or lore plaque.

---

## 5. Start Menu & Level Browser (`StartMenu`)

The game launches into an arcade start menu allowing quick entry, level browsing, and editor startup.

### Features:
- **Paginated Level List**: Displays up to 5 levels per page discovered dynamically from `res://data/levels/`, with `first_level.json` pinned to the top.
- **Pagination Controls**: `◀ Prev` and `Next ▶` buttons seamlessly navigate pages.
- **Create New Level Button**:
  - Prompts for a level name.
  - Launches directly into the **Level Editor** (`start_in_edit_mode = true`).
  - Pre-seeds a 5x5 starting stone floor canvas around `(0, 0)` so the player has safe footing.
  - Level file is saved to disk only when the user explicitly saves (`TAB` or Save Level button), preventing empty draft files on disk.
