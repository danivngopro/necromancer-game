$ErrorActionPreference = "Stop"

$requiredFiles = @(
    "project.godot",
    "scenes/world/main.tscn",
    "scenes/player/player.tscn",
    "scenes/enemies/basic_enemy.tscn",
    "scenes/skeletons/skeleton.tscn",
    "scenes/world/corpse.tscn",
    "scripts/player/player_controller.gd",
    "scripts/ai/enemy_ai.gd",
    "scripts/ai/skeleton_ai.gd",
    "scripts/combat/health_component.gd",
    "scripts/summoning/corpse.gd",
    "scripts/summoning/resurrection_controller.gd",
    "scripts/managers/game_manager.gd",
    "scripts/visuals/unit_feedback.gd",
    "scripts/visuals/unit_sprite_animator.gd",
    "scripts/visuals/range_gizmo.gd",
    "scripts/world/main.gd",
    "scripts/world/forest_tile_map.gd",
    "scripts/ui/army_debug_ui.gd",
    "scripts/player/player_stats.gd",
    "scripts/ui/rpg_debug_ui.gd",
    "scripts/ui/minimap.gd",
    "scripts/ui/resource_hud.gd",
    "scripts/ui/target_frame.gd",
    "scripts/ui/unit_nameplate_overlay.gd",
    "scripts/visuals/interaction_feedback.gd",
    "scripts/visuals/combat_projectile.gd",
    "scripts/visuals/enemy_selection_controller.gd",
    "scripts/visuals/raw_texture_sprite.gd",
    "scripts/ui/command_hud.gd",
    "scripts/ui/combat_log.gd",
    "docs/asset-scale-style-guide.md",
    "docs/manual-combat-playtest.md",
    "assets/sprites/player_placeholder.svg",
    "assets/sprites/enemy_placeholder.svg",
    "assets/sprites/skeleton_placeholder.svg",
    "assets/sprites/player_sheet.png",
    "assets/sprites/enemy_sheet.png",
    "assets/sprites/skeleton_sheet.png",
    "assets/sprites/corpse_placeholder.svg",
    "assets/sprites/opengameart/necromancer_64.png",
    "assets/sprites/opengameart/goblin_free/Goblin_idle_right.gif",
    "assets/sprites/opengameart/goblin_free/idle_right/idle_right_00.png",
    "assets/sprites/opengameart/goblin_free/run_left/run_left_00.png",
    "assets/sprites/opengameart/goblin_free/attack_right/attack_right_00.png",
    "assets/sprites/opengameart/goblin_free/death/death_00.png",
    "assets/sprites/opengameart/skeleton_sprite.zip",
    "assets/tiles/opengameart/forest_tiles.png",
    "assets/sprites/kenney/roguelike_rpg_pack/License.txt",
    "assets/sprites/kenney/props/tree_round.png",
    "assets/sprites/kenney/props/rock_large_gray.png",
    "assets/sprites/kenney/props/ruin_wall_tan.png",
    "tests/combat_regression_runner.gd",
    "tests/combat_regression_runner.tscn"
)

$missing = @()
foreach ($path in $requiredFiles) {
    if (-not (Test-Path -LiteralPath $path)) {
        $missing += $path
    }
}

if ($missing.Count -gt 0) {
    Write-Host "Missing required foundation files:"
    foreach ($path in $missing) {
        Write-Host " - $path"
    }
    exit 1
}

$projectText = Get-Content -Raw -LiteralPath "project.godot"
$requiredProjectSnippets = @(
    'run/main_scene="res://scenes/world/main.tscn"',
    'GameManager="*res://scripts/managers/game_manager.gd"',
    'window/size/viewport_width=1920',
    'window/size/viewport_height=1080',
    'move_left',
    'move_right',
    'move_up',
    'move_down',
    'attack',
    'resurrect'
)

foreach ($snippet in $requiredProjectSnippets) {
    if (-not $projectText.Contains($snippet)) {
        Write-Host "project.godot is missing expected snippet: $snippet"
        exit 1
    }
}

$scriptExpectations = @{
    "scripts/ai/enemy_ai.gd" = @(
        "enum State",
        "IDLE",
        "CHASE",
        "ATTACK",
        "RETURN",
        "DEAD",
        "force_aggro",
        "set_selected",
        "set_hovered",
        "enemy_level",
        "leash_distance: float = 240.0",
        "configure_level",
        "pow(2.0",
        "health.max_health = 4 * level_multiplier",
        "health.health_changed.emit",
        "experience_reward = 2 * level_multiplier",
        "move_speed = base_move_speed +",
        "set_name_text",
        "spawn_position",
        "leash_distance",
        "_return_to_spawn",
        "_restore_after_leash"
    )
    "scripts/ai/skeleton_ai.gd" = @(
        "enum State",
        "IDLE",
        "CHASE",
        "ATTACK",
        "DEAD",
        "GameManager.commanded_attack_target",
        "_get_nearest_active_enemy"
    )
    "scripts/player/player_controller.gd" = @(
        "MOUSE_BUTTON_RIGHT",
        "MOUSE_BUTTON_LEFT",
        "_command_skeleton_attack",
        "_cast_ranged_attack",
        "cast_cooldown: float = 3.0",
        "cast_range: float = 220.0",
        "cast_range",
        "_cast_timer = cast_cooldown",
        "_next_cast_time_msec",
        "_can_cast",
        "_get_cast_target",
        "_set_cast_target",
        "_try_fire_cast",
        "_move_toward_cast_range",
        "attack_damage: int = 1",
        "close_cast_assist_range",
        "projectile.launch(global_position, enemy, damage, self",
        "_get_cast_damage",
        "show_range_preview",
        "_get_path_next_position"
    )
    "scripts/managers/game_manager.gd" = @(
        "signal skeleton_registered",
        "attack_commanded",
        "skeleton_command_mode",
        "set_skeleton_command_mode",
        "commanded_attack_target",
        "command_attack_target",
        "save_game",
        "load_game",
        '"strength": player_stats.strength',
        "func get_nearest_hostile_target",
        "func get_health_component",
        "skeleton_cap",
        "essence",
        "enemy_killed",
        "can_spawn_skeleton",
        "record_enemy_kill",
        "spawn_reward_popup",
        "source_max_health",
        "source_damage",
        "source_move_speed",
        "inherited_factor := 0.50",
        "skeleton.move_speed = source_move_speed * 0.8",
        "RewardPopup",
        "+%d EXP",
        "+%d Mana",
        "player_stats",
        "register_player_stats"
    )
    "scripts/summoning/corpse.gd" = @(
        "expired",
        "lifetime_seconds",
        "lifetime_seconds: float = 30.0",
        "source_max_health",
        "source_damage",
        "source_move_speed",
        "func _expire",
        "set_highlighted",
        "show_revive_feedback",
        "RevivePopup",
        "CostLabel",
        "Revive: %d Mana"
    )
    "scripts/summoning/resurrection_controller.gd" = @(
        "GameManager.can_spawn_skeleton",
        "_refresh_corpse_highlights",
        "skeleton_cap_reached"
    )
    "scripts/visuals/unit_feedback.gd" = @(
        "class_name UnitFeedback",
        "HealthBar",
        "DamagePopup",
        "NameLabel",
        "ManaBar",
        "ManaLabel",
        "outline_size",
        "set_name_text",
        "set_world_resource_labels_visible",
        "animation_frame_count",
        "region_rect",
        "play_attack_animation",
        "hit_flash",
        "knockback"
    )
    "scripts/visuals/range_gizmo.gd" = @(
        "class_name RangeGizmo",
        "detection_range",
        "attack_range",
        "enabled: bool = false",
        "draw_arc"
    )
    "scripts/world/main.gd" = @(
        "map_min",
        "map_max",
        "_clamp_player_to_map",
        "enemy_spawn_points",
        "enemy_spawn_levels",
        "base_enemy_respawn_seconds",
        "SpawnTimers",
        "SpawnTimer%d",
        "RespawnPingRing",
        "respawn_remaining_by_index",
        "_on_enemy_killed",
        "base_enemy_respawn_seconds * (1.0 +",
        "spawn_world_enemies",
        "starting_skeleton_count: int = 0",
        "spawn_starting_skeletons",
        "basic_enemy_scene",
        "register_world_blockers"
    )
    "scripts/ui/army_debug_ui.gd" = @(
        "class_name ArmyDebugUI",
        "Skeletons:",
        "Essence:"
    )
    "scripts/player/player_stats.gd" = @(
        "class_name PlayerStats",
        "level",
        "experience",
        "stat_points",
        "hp",
        "strength",
        "black_mana",
        "current_black_mana",
        "mana_regen",
        "base_mana_regen_per_second: float = 0.1",
        "get_mana_regen_rate",
        "spend_black_mana",
        "restore_black_mana",
        "Mana regen: +%.2f/sec",
        "black_mana += 1",
        "army_size",
        "movement_speed",
        "movement_speed: int = 80",
        "stat_points += 2",
        "get_skeleton_health_bonus",
        "get_skeleton_damage_bonus",
        "get_player_damage_bonus",
        "increase_stat",
        "add_experience"
    )
    "scripts/ui/rpg_debug_ui.gd" = @(
        "class_name RPGDebugUI",
        "extends PanelContainer",
        'const STAT_ROWS: Array[String] = ["hp", "strength", "black_mana", "mana_regen", "army_size", "movement_speed"]',
        "toggle_expanded",
        "HBoxContainer.new",
        "Button.new",
        'row.name = "%sRow" % stat_name',
        "button.custom_minimum_size = Vector2(26, 22)",
        "button.mouse_filter = Control.MOUSE_FILTER_STOP",
        "stat_value_labels",
        "return GameManager.player_stats != null and GameManager.player_stats.stat_points > 0",
        "Level:",
        "EXP:",
        "Stat Points:",
        "HP",
        "Strength",
        "Dark Mana",
        "Mana Regen",
        "Army Size",
        "Movement Speed"
    )
    "scripts/ui/minimap.gd" = @(
        "class_name Minimap",
        "map_min",
        "map_max",
        "draw_circle",
        "GameManager.enemies"
    )
    "scripts/visuals/interaction_feedback.gd" = @(
        "class_name InteractionFeedback",
        "show_move_marker",
        "show_attack_command",
        "show_cast_marker",
        "show_cast_blocked",
        "show_range_preview",
        "TargetRing",
        "CommandLine"
    )
    "scripts/visuals/combat_projectile.gd" = @(
        "class_name CombatProjectile",
        "launch",
        "impact",
        "valid_source",
        "ProjectileImpactEffect",
        "GameManager.log_combat",
        "target_position",
        "travel_speed"
    )
    "scripts/visuals/enemy_selection_controller.gd" = @(
        "class_name EnemySelectionController",
        "set_hovered",
        "GameManager.get_nearest_enemy"
    )
    "scripts/ui/command_hud.gd" = @(
        "class_name CommandHUD",
        "Follow",
        "Hold",
        "Attack",
        "Cast Ready",
        "update_cast_status",
        "GameManager.skeleton_command_changed"
    )
    "scripts/ui/combat_log.gd" = @(
        "class_name CombatLog",
        "GameManager.combat_logged",
        "Combat log ready"
    )
    "scripts/ui/resource_hud.gd" = @(
        "class_name ResourceHUD",
        "HP %s/%d",
        "Dark Mana %.1f/%d",
        "Regen +%.2f/s"
    )
    "scripts/ui/target_frame.gd" = @(
        "class_name TargetFrame",
        "No Target",
        "Lv %d %s"
    )
    "scripts/ui/unit_nameplate_overlay.gd" = @(
        "class_name UnitNameplateOverlay",
        "get_viewport().get_canvas_transform()",
        "set_world_resource_labels_visible(false)",
        "Lv %d %s"
    )
    "scripts/visuals/unit_sprite_animator.gd" = @(
        "class_name UnitSpriteAnimator",
        "extends AnimatedSprite2D",
        "necromancer_64.png",
        "goblin_free",
        "idle_right",
        "walk_left",
        "attack_left",
        "_play_directional",
        "skeleton/skeleton/idle/right",
        "face_toward",
        "_update_facing",
        "play_attack_once",
        "play_death_once"
    )
    "scripts/world/forest_tile_map.gd" = @(
        "class_name ForestTileMap",
        "extends TileMap",
        "forest_tiles.png",
        "TileSetAtlasSource",
        "set_cell",
        "ForestProps",
        "ForestPropCollision",
        "has_bad_ground_tree_tiles",
        "has_blue_path_tiles",
        "get_spawn_safe_position",
        "get_path_next_position",
        "get_collision_prop_count",
        "get_prop_texture_has_transparency",
        "kenney/props",
        "register_world_blockers",
        "_mark_world_rectangle_blocked",
        "_rebuild_path_grid",
        "AStarGrid2D"
    )
    "scripts/visuals/raw_texture_sprite.gd" = @(
        "class_name RawTextureSprite",
        "ImageTexture.create_from_image",
        "texture_path"
    )
    "tests/combat_regression_runner.gd" = @(
        "Combat regression runner passed",
        "Player cast range should be reduced by 20",
        "Enemy HP label should update immediately after level configuration",
        "Enemy leash should stay larger than player cast range",
        "Main scene should have screen-space unit nameplates",
        "Level 3 enemies should take 20 percent more respawn time per level",
        "Respawn timer should be visible while waiting",
        "Respawn ping ring should be visible while waiting",
        "Revived skeleton HP should inherit 50 percent",
        "Revived skeleton damage should inherit 50 percent",
        "Revived skeleton speed should inherit 80 percent",
        "Projectile with freed source should still apply damage safely",
        "Mana regen stat should not change max dark mana",
        "Strength stat should be allocatable",
        "Player should use AnimatedSprite2D idle frames",
        "Main scene should use a forest TileMap test area",
        "Player should gain two stat points per level",
        "Player sprite should face left when moving left",
        "Forest ground should not use partial tree atlas cells",
        "Forest props should have collision bodies",
        "Enemy should use directional upward walk frames",
        "Forest should not use the source image blue background as paths",
        "Old box obstacles should be replaced by object sprites",
        "World border color boxes should be hidden",
        "Stat panel should use real row containers",
        "Large blockage should use the Kenney ruins/forest prop pack",
        "AI pathing should return an intermediate path point around forest blockers",
        "AI pathing should route around scene world obstacles",
        "Player click-to-move should use shared pathing",
        "Stat plus click target should cover the visible plus",
        "Camera should stop at horizontal map borders",
        "Player cast cooldown should be 3 seconds",
        "Player auto attack should deal 1 damage",
        "Player base speed should be 30 percent slower",
        "Base mana regen should restore 0.1 mana per second",
        "Ranged cast should not deal immediate damage",
        "Projectile impact should damage enemy",
        "Enemy should enter RETURN when leash is exceeded",
        "Level 3 enemy health should be 16"
    )
}

foreach ($path in $scriptExpectations.Keys) {
    $text = Get-Content -Raw -LiteralPath $path
    foreach ($snippet in $scriptExpectations[$path]) {
        if (-not $text.Contains($snippet)) {
            Write-Host "$path is missing expected combat-loop snippet: $snippet"
            exit 1
        }
    }
}

$sceneExpectations = @{
    "scenes/world/main.tscn" = @(
        "scripts/world/main.gd",
        "ForestTileMap",
        "forest_tile_map.gd",
        "raw_texture_sprite.gd",
        "RPGDebugUI",
        "Minimap",
        "CommandHUD",
        "ResourceHUD",
        "TargetFrame",
        "UnitNameplateOverlay",
        "CombatLog",
        "InteractionFeedback",
        "EnemySelectionController",
        "WorldObstacles",
        "WorldBorder",
        "SafeArea",
        "Path"
    )
    "scenes/player/player.tscn" = @(
        "PlayerStats",
        "unit_sprite_animator.gd",
        "AnimatedSprite2D",
        "UnitFeedback",
        "HealthBar",
        "HpLabel",
        "ManaBar",
        "ManaLabel",
        "attack_range = 220.0",
        "zoom = Vector2(1.75, 1.75)",
        "limit_left = -700",
        "limit_right = 700"
    )
    "scenes/enemies/basic_enemy.tscn" = @(
        "UnitFeedback",
        "unit_sprite_animator.gd",
        "AnimatedSprite2D",
        "NameLabel",
        "HealthBar",
        "HpLabel",
        "SelectionOutline",
        "HoverOutline"
    )
    "scenes/skeletons/skeleton.tscn" = @(
        "UnitFeedback",
        "unit_sprite_animator.gd",
        "AnimatedSprite2D",
        "HealthBar",
        "HpLabel"
    )
    "scenes/world/corpse.tscn" = @(
        "Highlight",
        "corpse_placeholder.svg",
        "Sprite2D",
        "CostLabel",
        "ReviveEffectAnchor",
        "RevivePopupAnchor"
    )
}

foreach ($path in $sceneExpectations.Keys) {
    $text = Get-Content -Raw -LiteralPath $path
    foreach ($snippet in $sceneExpectations[$path]) {
        if (-not $text.Contains($snippet)) {
            Write-Host "$path is missing expected visibility snippet: $snippet"
            exit 1
        }
    }
}

Write-Host "Foundation validation passed."
