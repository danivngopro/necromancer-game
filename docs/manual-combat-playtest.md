# Manual Combat Playtest

Run this in the Godot editor after combat changes.

## Player Cast

- Left-click an enemy once.
- Confirm the enemy health bar drops immediately.
- Confirm the cast HUD changes from `Cast Ready` to a countdown.
- Click the same enemy repeatedly during the countdown.
- Confirm no extra cast projectile appears and no extra damage happens until the cooldown reaches ready.
- Stand close to an enemy and click near its body.
- Confirm close clicks still resolve to that enemy and deal damage.

## Skeleton Commands

- Right-click an enemy.
- Confirm the player does not move into melee.
- Confirm skeletons move toward the enemy and attack.
- Press `F`.
- Confirm skeletons return to follow formation.
- Press `H`.
- Confirm skeletons hold near their current positions.

## Range And Feedback

- Left-click an enemy outside cast range.
- Confirm `OUT OF RANGE` feedback appears and no cooldown starts.
- Left-click empty ground.
- Confirm `NO TARGET` feedback appears and no cooldown starts.
- Left-click while cast is cooling down.
- Confirm `COOLDOWN` feedback appears and no projectile/damage is created.
