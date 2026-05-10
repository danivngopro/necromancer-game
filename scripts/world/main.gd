extends Node2D

@export var basic_enemy_scene: PackedScene
@export var startup_enemy_count: int = 4
@export var startup_spawn_radius: float = 280.0
@export var starting_skeleton_count: int = 2
@export var starting_skeleton_radius: float = 46.0

@onready var enemies_root: Node2D = $Enemies
@onready var player: Node2D = $Player

func _ready() -> void:
	spawn_starting_skeletons()
	spawn_starting_enemies()


func spawn_starting_skeletons() -> void:
	if player == null:
		return

	for index in starting_skeleton_count:
		var angle := TAU * float(index) / float(starting_skeleton_count)
		var offset := Vector2(cos(angle), sin(angle)) * starting_skeleton_radius
		GameManager.spawn_skeleton(player.global_position + offset)


func spawn_starting_enemies() -> void:
	if player == null or enemies_root == null or basic_enemy_scene == null:
		return

	for index in startup_enemy_count:
		var enemy := basic_enemy_scene.instantiate() as Node2D
		var angle := TAU * float(index) / float(startup_enemy_count)
		var stagger := Vector2(cos(angle), sin(angle)) * startup_spawn_radius
		enemy.global_position = player.global_position + stagger
		enemies_root.add_child(enemy)
		print("Spawned startup enemy %s at %s" % [enemy.name, enemy.global_position])
