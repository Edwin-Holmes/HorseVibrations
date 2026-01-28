# Horse Vibrations

A Witcher 3 script mod that adds immersive controller vibration feedback while riding Roach, simulating realistic hoofbeat patterns and horse movements.

## Features

### 🐴 Realistic Hoofbeat Vibrations
- **Gait-specific patterns**: Different vibration rhythms for walk, trot, canter, and gallop
- **Dynamic double-pulse system**: Simulates the natural two-beat pattern of horse gaits
- **Speed-responsive**: Vibration intensity and timing adjust based on horse speed

### 🎮 Enhanced Riding Feedback
- **Mount/Dismount feedback**: Light vibration when mounting, stronger pulse when dismounting
- **Acceleration/Deceleration cues**: Distinct vibration patterns when speeding up or slowing down
- **Rearing detection**: Special vibration when the horse rears

## Installation

1. Download the latest release
2. Extract the `mods` folder to your Witcher 3 installation directory:
   ```
   The Witcher 3 Wild Hunt/Mods/modHorseVibrations/
   ```
3. Launch the game and enjoy enhanced horse riding!

## Technical Details

### Gait Vibration Settings

| Gait | Short Gap | Long Gap | First Intensity | Second Intensity |
|------|-----------|----------|-----------------|------------------|
| Walk | 0.49s | 0.49s | Medium | Medium |
| Trot | 0.30s | 0.41s | Medium | Light |
| Canter | 0.12s | 0.46s | Very Light | None |
| Gallop | 0.11s | 0.57s | Light | Very Light |

### How It Works

The mod uses `@wrapMethod` annotations to extend the vanilla `W3HorseComponent` and `CR4Player` classes without modifying the base game files. A custom `CHorseVibrationManager` class handles all vibration logic:

- Monitors horse state every tick
- Calculates appropriate vibration patterns based on gait
- Manages timing with a pulse timer system
- Handles state transitions (mounting, dismounting, speed changes)

### Speed Conventions Note

The vanilla scripts label canter as the fastest gait and gallop as one slower.  My mod refers (correctly) to gallop as the fastest and canter as one slower.

## Requirements

- The Witcher 3: Wild Hunt (Game Version 4.04)
- A controller with vibration support

## Credits

Created by Edwin-Holmes

## Changelog

### Version 1.0.0
- Initial release
- Gait-specific vibration patterns
- Mount/dismount feedback
- Speed transition effects
- Context-aware activation/deactivation
