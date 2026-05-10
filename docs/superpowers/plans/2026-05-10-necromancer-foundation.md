# Necromancer Foundation Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build the first playable Godot 4 foundation for the necromancer army loop.

**Architecture:** Use small Godot scenes with typed GDScript scripts and signal-based communication. Put shared combat and summoning behavior in reusable scripts, while `GameManager` handles broad tracking and spawn helpers.

**Tech Stack:** Godot 4.x, GDScript only, placeholder 2D shapes, PowerShell structural validation.

---

### Task 1: Foundation Files

**Files:**
- Create: `project.godot`
- Create: `tests/validate_foundation.ps1`
- Create: requested `scenes`, `scripts`, and `assets` directories

- [ ] Add a validation script that fails until the expected foundation files exist.
- [ ] Add `project.godot` with input actions and the `GameManager` autoload.
- [ ] Create placeholder `.gitkeep` files for empty asset/UI folders.

### Task 2: Core Systems

**Files:**
- Create: `scripts/combat/health_component.gd`
- Create: `scripts/managers/game_manager.gd`
- Create: `scripts/summoning/corpse.gd`
- Create: `scripts/summoning/resurrection_controller.gd`

- [ ] Implement reusable health with `health_changed`, `damaged`, and `died` signals.
- [ ] Implement corpse consumption and resurrection signals.
- [ ] Implement player-side resurrection scanning.
- [ ] Implement manager-level tracking and skeleton spawn helper.

### Task 3: Entity Scenes And AI

**Files:**
- Create: `scripts/player/player_controller.gd`
- Create: `scripts/ai/enemy_ai.gd`
- Create: `scripts/ai/skeleton_ai.gd`
- Create: `scenes/player/player.tscn`
- Create: `scenes/enemies/basic_enemy.tscn`
- Create: `scenes/skeletons/skeleton.tscn`
- Create: `scenes/world/corpse.tscn`
- Create: `scenes/world/main.tscn`

- [ ] Implement top-down player movement and local attack/resurrection input.
- [ ] Implement simple enemy chase and contact damage.
- [ ] Implement skeleton follow/acquire/attack behavior.
- [ ] Create placeholder shape scenes with collision, health components, and scripts.

### Task 4: Verify

**Files:**
- Use: `tests/validate_foundation.ps1`

- [ ] Run `pwsh -ExecutionPolicy Bypass -File tests/validate_foundation.ps1` or Windows PowerShell equivalent.
- [ ] If `godot` is available, run `godot --headless --path . --quit-after 1`.
