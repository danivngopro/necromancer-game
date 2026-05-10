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
    "scripts/ui/army_debug_ui.gd"
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
        "DEAD",
        "GameManager.get_nearest_hostile_target"
    )
    "scripts/ai/skeleton_ai.gd" = @(
        "enum State",
        "IDLE",
        "CHASE",
        "ATTACK",
        "DEAD",
        "GameManager.get_nearest_enemy"
    )
    "scripts/managers/game_manager.gd" = @(
        "signal skeleton_registered",
        "func get_nearest_hostile_target",
        "func get_health_component",
        "skeleton_cap",
        "essence",
        "enemy_killed",
        "can_spawn_skeleton",
        "record_enemy_kill"
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
        "draw_arc"
    )
    "scripts/world/main.gd" = @(
        "startup_enemy_count",
        "starting_skeleton_count",
        "spawn_starting_skeletons",
        "spawn_starting_enemies",
        "basic_enemy_scene"
    )
    "scripts/ui/army_debug_ui.gd" = @(
        "class_name ArmyDebugUI",
        "Skeletons:",
        "Essence:"
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
        "ArmyDebugUI"
    )
    "scenes/player/player.tscn" = @(
        "UnitFeedback",
        "HealthBar",
        "HpLabel",
        "RangeGizmo"
    )
    "scenes/enemies/basic_enemy.tscn" = @(
        "UnitFeedback",
        "HealthBar",
        "HpLabel",
        "RangeGizmo"
    )
    "scenes/skeletons/skeleton.tscn" = @(
        "UnitFeedback",
        "HealthBar",
        "HpLabel",
        "RangeGizmo"
    )
    "scenes/world/corpse.tscn" = @(
        "Highlight",
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
