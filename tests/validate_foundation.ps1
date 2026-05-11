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
    "scripts/visuals/range_gizmo.gd",
    "scripts/world/main.gd",
    "scripts/ui/army_debug_ui.gd",
    "scripts/player/player_stats.gd",
    "scripts/ui/rpg_debug_ui.gd",
    "scripts/ui/minimap.gd",
    "scripts/ui/resource_hud.gd",
    "scripts/ui/target_frame.gd",
    "scripts/visuals/interaction_feedback.gd",
    "scripts/visuals/combat_projectile.gd",
    "scripts/visuals/enemy_selection_controller.gd",
    "scripts/ui/command_hud.gd",
    "scripts/ui/combat_log.gd",
    "docs/asset-scale-style-guide.md",
    "docs/manual-combat-playtest.md",
    "assets/sprites/player_placeholder.svg",
    "assets/sprites/enemy_placeholder.svg",
    "assets/sprites/skeleton_placeholder.svg",
    "assets/sprites/corpse_placeholder.svg",
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
        "configure_level",
        "pow(2.0",
        "health.max_health = 4 * level_multiplier",
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
        "show_range_preview"
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
        "inherited_factor",
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
        "basic_enemy_scene"
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
        "black_mana",
        "current_black_mana",
        "mana_regen",
        "base_mana_regen_per_second: float = 0.1",
        "get_mana_regen_rate",
        "spend_black_mana",
        "restore_black_mana",
        "Mana regen: +%.2f/sec",
        "army_size",
        "movement_speed",
        "movement_speed: int = 80",
        "get_skeleton_health_bonus",
        "get_skeleton_damage_bonus",
        "increase_stat",
        "add_experience"
    )
    "scripts/ui/rpg_debug_ui.gd" = @(
        "class_name RPGDebugUI",
        'const STAT_ROWS: Array[String] = ["hp", "black_mana", "mana_regen", "army_size", "movement_speed"]',
        "toggle_expanded",
        "get_tree().paused = false",
        "Button.new",
        "button.position = Vector2(238, 90",
        "return GameManager.player_stats != null and GameManager.player_stats.stat_points > 0",
        "Level:",
        "EXP:",
        "Stat Points:",
        "HP",
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
        "HP %d/%d",
        "Mana %.1f/%d",
        "Regen +%.2f/s"
    )
    "scripts/ui/target_frame.gd" = @(
        "class_name TargetFrame",
        "No Target",
        "Lv %d %s"
    )
    "tests/combat_regression_runner.gd" = @(
        "Combat regression runner passed",
        "Level 3 enemies should take 20 percent more respawn time per level",
        "Respawn timer should be visible while waiting",
        "Respawn ping ring should be visible while waiting",
        "Revived skeleton HP should inherit 12 percent",
        "Revived skeleton speed should inherit 80 percent",
        "Projectile with freed source should still apply damage safely",
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
        "RPGDebugUI",
        "Minimap",
        "CommandHUD",
        "ResourceHUD",
        "TargetFrame",
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
        "player_placeholder.svg",
        "Sprite2D",
        "UnitFeedback",
        "HealthBar",
        "HpLabel",
        "ManaBar",
        "ManaLabel",
        "zoom = Vector2(1.75, 1.75)"
    )
    "scenes/enemies/basic_enemy.tscn" = @(
        "UnitFeedback",
        "enemy_placeholder.svg",
        "Sprite2D",
        "NameLabel",
        "HealthBar",
        "HpLabel",
        "SelectionOutline",
        "HoverOutline"
    )
    "scenes/skeletons/skeleton.tscn" = @(
        "UnitFeedback",
        "skeleton_placeholder.svg",
        "Sprite2D",
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
