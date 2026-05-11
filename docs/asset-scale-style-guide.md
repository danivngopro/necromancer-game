# Asset Scale And Style Guide

This project is still in placeholder-art mode. Use this guide before importing better character art or models.

## Scale

- Player footprint: 20 px wide, 28 px tall.
- Skeleton footprint: 16 px wide, 22 px tall.
- Basic enemy footprint: 18 px wide, 22 px tall.
- Corpse footprint: about 24 px wide.
- Keep readable combat silhouettes inside a 32 px circle unless the unit is intentionally large.

## Camera And Readability

- Main gameplay camera uses `zoom = Vector2(3, 3)`, so tiny sprite details will not matter.
- Prefer strong silhouettes and distinct team colors over detailed textures.
- Keep attack, command, and revive effects brighter than unit bodies.

## Collision

- Match visuals to the existing collision radius first, then tune collision only if gameplay demands it.
- Do not let decorative art extend far beyond the collision body; it will make hit ranges feel wrong.
- Obstacles need visible boundaries that match their `StaticBody2D` collision.

## Import Order

1. Replace player, skeleton, enemy, and corpse silhouettes with simple 2D sprites or animated placeholders.
2. Verify scale in the real camera.
3. Add final models or polished sprites only after movement, targeting, and collision still read clearly.
