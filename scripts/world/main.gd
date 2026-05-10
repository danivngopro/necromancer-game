extends Node2D

@export var basic_enemy_scene: PackedScene
@export var enemy_spawn_points: Array[Vector2] = [
	Vector2(320, -90),
	Vector2(460, 120),
	Vector2(-380, 80),
	Vector2(-520, -140),
	Vector2(120, 420),
	Vector2(-160, 560)
]
@export var starting_skeleton_count: int = 2
@export var starting_skeleton_radius: float = 46.0

@onready var enemies_root: Node2D = $Enemies
@onready var player: Node2D = $Player

func _ready() -> void:
	spawn_starting_skeletons()
	spawn_world_enemies()


func spawn_starting_skeletons() -> void:
	if player == null:
		return

	for index in starting_skeleton_count:
		var angle := TAU * float(index) / float(starting_skeleton_count)
		var offset := Vector2(cos(angle), sin(angle)) * starting_skeleton_radius
		GameManager.spawn_skeleton(player.global_position + offset)


func spawn_world_enemies() -> void:
	if enemies_root == null or basic_enemy_scene == null:
		return

	for spawn_point in enemy_spawn_points:
		var enemy := basic_enemy_scene.instantiate() as Node2D
		enemy.global_position = spawn_point
		enemies_root.add_child(enemy)
		print("Spawned world enemy %s at %s" % [enemy.name, enemy.global_position])
