extends Node2D

@export var basic_enemy_scene: PackedScene
@export var map_min: Vector2 = Vector2(-700, -260)
@export var map_max: Vector2 = Vector2(700, 980)
@export var enemy_spawn_points: Array[Vector2] = [
	Vector2(-280, 30),
	Vector2(260, 90),
	Vector2(-420, 320),
	Vector2(360, 430),
	Vector2(120, 700),
	Vector2(-180, 860)
]
@export var enemy_spawn_levels: Array[int] = [1, 1, 2, 2, 3, 4]
@export var starting_skeleton_count: int = 0
@export var starting_skeleton_radius: float = 46.0

@onready var enemies_root: Node2D = $Enemies
@onready var player: Node2D = $Player

func _ready() -> void:
	spawn_starting_skeletons()
	spawn_world_enemies()


func _process(_delta: float) -> void:
	_clamp_player_to_map()


func _clamp_player_to_map() -> void:
	if player == null:
		return

	player.global_position = Vector2(
		clampf(player.global_position.x, map_min.x, map_max.x),
		clampf(player.global_position.y, map_min.y, map_max.y)
	)


func spawn_starting_skeletons() -> void:
	if player == null or starting_skeleton_count <= 0:
		return

	for index in starting_skeleton_count:
		var angle := TAU * float(index) / float(starting_skeleton_count)
		var offset := Vector2(cos(angle), sin(angle)) * starting_skeleton_radius
		GameManager.spawn_skeleton(player.global_position + offset)


func spawn_world_enemies() -> void:
	if enemies_root == null or basic_enemy_scene == null:
		return

	for index in enemy_spawn_points.size():
		var spawn_point := enemy_spawn_points[index]
		var enemy := basic_enemy_scene.instantiate() as Node2D
		enemy.global_position = spawn_point
		if enemy.has_method("configure_level"):
			var level := enemy_spawn_levels[index] if index < enemy_spawn_levels.size() else 1
			enemy.configure_level(level)
		enemies_root.add_child(enemy)
		print("Spawned world enemy %s at %s" % [enemy.name, enemy.global_position])
