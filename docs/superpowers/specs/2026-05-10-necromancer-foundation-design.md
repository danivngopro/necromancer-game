# Necromancer Foundation Design

## Goal

Create the initial Godot 4 foundation for a 2D top-down necromancer game. The first slice should be playable with placeholder shapes: move the necromancer, fight simple enemies, leave corpses, resurrect corpses into skeletons, and have skeletons follow and attack.

## Scope

This foundation includes project configuration, folder structure, reusable gameplay scripts, starter scenes, and a `GameManager` autoload. It does not include final art, audio, boss logic, biome generation, inventory, save data, or human territory progression.

## Architecture

Scenes are small and reusable. `Player`, `BasicEnemy`, `Skeleton`, and `Corpse` are independent scene roots with typed GDScript. Reusable systems live in `scripts/combat`, `scripts/summoning`, `scripts/ai`, and `scripts/managers`.

Communication is signal-based. `HealthComponent` emits damage and death signals. Enemies convert themselves into corpse scenes on death. The player requests resurrection, and corpses emit when consumed. `GameManager` tracks live entities and exposes high-level events without owning every behavior.

## Gameplay Loop

The player moves using Godot input actions. Enemies chase and damage the player. When an enemy dies, it spawns a corpse. If the player is near a corpse and presses the resurrection action, the corpse is consumed and a skeleton is spawned. Skeletons follow the player when idle, acquire nearby enemies, and attack them.

## File Layout

The project follows the requested structure:

- `scenes/player`, `scenes/enemies`, `scenes/skeletons`, `scenes/world`, `scenes/ui`
- `scripts/ai`, `scripts/combat`, `scripts/summoning`, `scripts/managers`, `scripts/ui`
- `assets/sprites`, `assets/audio`, `assets/effects`

## Testing And Verification

The first validation is structural because no Godot test framework is installed. A PowerShell validation script checks required files and key project settings. If a Godot executable is available on PATH, run Godot's headless import/script check as an additional verification step.
