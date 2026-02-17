# Toxic Zone System - Battle Royale Area Shrinking

A creative battle royale zone shrinking mechanic for Fish Battle Royale. Toxic coral **starts at random border positions and gradually spreads inward** to adjacent tiles, creating an organic growing effect!

## Features

- **Scattered border spawn**: Toxic zones start at random 10% of border tiles
- **Probabilistic spreading**: Each adjacent tile has a 50% chance to spread (configurable!)
- **Visual feedback**: Purple pulsing toxic zones that damage players
- **Fully configurable**: Adjust timing, damage, spread speed, and probability

## Configuration

Edit these values in `Config.gd`:

```gdscript
# Battle Royale Zone Settings
var toxic_zone_enabled := true           # Enable/disable the system
var toxic_zone_first_wave := 5.0        # Seconds before border appears
var toxic_zone_wave_interval := 2.0     # Seconds between each spread
var toxic_zone_spread_chance := 0.5     # Chance per tile to spread (0.0-1.0)
var toxic_zone_damage := 1              # Damage per tick
```

## How It Works

1. **Initial Delay** (5s): Game starts, countdown begins
2. **Scattered Border Spawn**: 10% of border tiles become toxic at random positions (purple pulsing effect)
3. **Probabilistic Spreading**: Every 2 seconds, each toxic tile attempts to spread to adjacent tiles with 50% chance per tile
4. **Organic Growth**: Creates unpredictable, natural-looking spread patterns
5. **Damage**: Players in toxic zones take 1 damage per second

## Customization Options

**Spread Probability:**
- Aggressive: `toxic_zone_spread_chance := 0.8` (fast spreading)
- Balanced: `toxic_zone_spread_chance := 0.5` (default - unpredictable)
- Slow: `toxic_zone_spread_chance := 0.3` (very organic, strategic)
- Guaranteed (old behavior): `toxic_zone_spread_chance := 1.0`

**Spread Speed:**
- Fast: `toxic_zone_wave_interval := 1.0` (spreads every second)
- Medium: `toxic_zone_wave_interval := 2.0` (default)
- Slow: `toxic_zone_wave_interval := 3.0` (strategic gameplay)

**Initial Delay:**
- Quick start: `toxic_zone_first_wave := 3.0`
- Standard: `toxic_zone_first_wave := 5.0` (default)
- Late game: `toxic_zone_first_wave := 10.0`

**Damage:**
- Gentle: `toxic_zone_damage := 1` (default - 3 hits to kill)
- Moderate: `toxic_zone_damage := 2` (forces quick escapes)
- Deadly: `toxic_zone_damage := 3` (instant death on low HP)

## Signals

The system emits useful signals:

- `zone_advanced(wave_number: int)` - Triggered each time toxic spreads
- `player_in_toxic_zone()` - Triggered when player takes toxic damage

## Tips for Balance

- **Fast-paced**: Border at 3s, spread every 1s, 80% chance, damage 2
- **Standard**: Border at 5s, spread every 2s, 50% chance, damage 1 (default)
- **Slow burn**: Border at 10s, spread every 3s, 30% chance, damage 1
- **Hardcore**: Border at 5s, spread every 1.5s, 70% chance, damage 2

## Visual Customization

Edit colors in `toxic_zone_system.gd`:

```gdscript
const TOXIC_COLOR := Color(0.5, 0.0, 0.8, 0.8)  # Purple toxic
```

Try different colors for different themes:
- Green slime: `Color(0.0, 0.8, 0.2, 0.8)`
- Red lava: `Color(0.9, 0.1, 0.0, 0.8)`
- Blue ice: `Color(0.0, 0.5, 1.0, 0.8)`

---

**Created for Fish Battle Royale - Organic spreading toxic zones!** 🐟💜
