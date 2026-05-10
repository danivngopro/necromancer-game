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
    "scripts/ui/minimap.gd"
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
        "enemy_level",
        "configure_level",
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
        "player_stats",
        "register_player_stats"
    )
    "scripts/summoning/corpse.gd" = @(
        "expired",
        "lifetime_seconds",
        "func _expire",
        "set_highlighted",
        "show_revive_feedback",
        "RevivePopup"
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
        "spend_black_mana",
        "restore_black_mana",
        "army_size",
        "movement_speed",
        "get_skeleton_health_bonus",
        "get_skeleton_damage_bonus",
        "increase_stat",
        "add_experience"
    )
    "scripts/ui/rpg_debug_ui.gd" = @(
        "class_name RPGDebugUI",
        "toggle_expanded",
        "get_tree().paused",
        "Button.new",
        "Level:",
        "EXP:",
        "Stat Points:",
        "HP",
        "Black Mana",
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
        "WorldBorder",
        "SafeArea",
        "Path"
    )
    "scenes/player/player.tscn" = @(
        "PlayerStats",
        "UnitFeedback",
        "HealthBar",
        "HpLabel"
    )
    "scenes/enemies/basic_enemy.tscn" = @(
        "UnitFeedback",
        "HealthBar",
        "HpLabel"
    )
    "scenes/skeletons/skeleton.tscn" = @(
        "UnitFeedback",
        "HealthBar",
        "HpLabel"
    )
    "scenes/world/corpse.tscn" = @(
        "Highlight",
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
