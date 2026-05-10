extends Node

signal player_registered(player: Node2D)
signal enemy_registered(enemy: Node2D)
signal enemy_unregistered(enemy: Node2D)
signal corpse_registered(corpse: Node2D)
signal corpse_spawned(corpse: Node2D)
signal skeleton_registered(skeleton: Node2D)
signal skeleton_spawned(skeleton: Node2D)

const SKELETON_SCENE: PackedScene = preload("res://scenes/skeletons/skeleton.tscn")
const CORPSE_SCENE: PackedScene = preload("res://scenes/world/corpse.tscn")

var player: Node2D
var enemies: Array[Node2D] = []
var corpses: Array[Node2D] = []
var skeletons: Array[Node2D] = []

func register_player(new_player: Node2D) -> void:
	player = new_player
	player_registered.emit(player)


func register_enemy(enemy: Node2D) -> void:
	if enemy not in enemies:
		enemies.append(enemy)
		enemy_registered.emit(enemy)


func unregister_enemy(enemy: Node2D) -> void:
	if enemy in enemies:
		enemies.erase(enemy)
		enemy_unregistered.emit(enemy)


func register_corpse(corpse: Node2D) -> void:
	if corpse not in corpses:
		corpses.append(corpse)
		corpse_registered.emit(corpse)


func unregister_corpse(corpse: Node2D) -> void:
	corpses.erase(corpse)


func register_skeleton(skeleton: Node2D) -> void:
	if skeleton not in skeletons:
		skeletons.append(skeleton)
		skeleton_registered.emit(skeleton)


func unregister_skeleton(skeleton: Node2D) -> void:
	skeletons.erase(skeleton)


func spawn_skeleton(spawn_position: Vector2) -> Node2D:
	var skeleton := SKELETON_SCENE.instantiate() as Node2D
	get_tree().current_scene.add_child(skeleton)
	skeleton.global_position = spawn_position
	register_skeleton(skeleton)
	skeleton_spawned.emit(skeleton)
	return skeleton


func spawn_corpse(spawn_position: Vector2) -> Node2D:
	var corpse := CORPSE_SCENE.instantiate() as Node2D
	get_tree().current_scene.add_child(corpse)
	corpse.global_position = spawn_position
	corpse_spawned.emit(corpse)
	return corpse


func get_health_component(unit: Node) -> HealthComponent:
	if unit == null or not is_instance_valid(unit):
		return null

	return unit.get_node_or_null("HealthComponent") as HealthComponent


func get_nearest_enemy(from_position: Vector2, max_distance: float) -> Node2D:
	var nearest_enemy: Node2D
	var nearest_distance := max_distance

	for enemy in enemies:
		if not is_instance_valid(enemy):
			continue

		var distance := from_position.distance_to(enemy.global_position)
		if distance < nearest_distance:
			nearest_enemy = enemy
			nearest_distance = distance

	return nearest_enemy


func get_nearest_hostile_target(from_position: Vector2, max_distance: float) -> Node2D:
	var nearest_target: Node2D
	var nearest_distance := max_distance
	var candidates: Array[Node2D] = []

	if player != null and is_instance_valid(player):
		candidates.append(player)

	for skeleton in skeletons:
		if is_instance_valid(skeleton):
			candidates.append(skeleton)

	for candidate in candidates:
		var health := get_health_component(candidate)
		if health == null or health.is_dead:
			continue

		var distance := from_position.distance_to(candidate.global_position)
		if distance < nearest_distance:
			nearest_target = candidate
			nearest_distance = distance

	return nearest_target
