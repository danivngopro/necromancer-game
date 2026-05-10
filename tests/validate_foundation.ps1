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
    "scripts/managers/game_manager.gd"
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
        "func get_health_component"
    )
    "scripts/summoning/corpse.gd" = @(
        "expired",
        "lifetime_seconds",
        "func _expire"
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

Write-Host "Foundation validation passed."
