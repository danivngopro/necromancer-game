extends Node

signal player_registered(player: Node2D)
signal enemy_registered(enemy: Node2D)
signal enemy_unregistered(enemy: Node2D)
signal corpse_registered(corpse: Node2D)
signal corpse_spawned(corpse: Node2D)
signal skeleton_registered(skeleton: Node2D)
signal skeleton_unregistered(skeleton: Node2D)
signal skeleton_spawned(skeleton: Node2D)
signal skeleton_cap_changed(current_count: int, max_count: int)
signal essence_changed(essence: int)
signal enemy_killed(enemy: Node2D, source: Node)
signal progression_reward_applied(message: String)

const SKELETON_SCENE: PackedScene = preload("res://scenes/skeletons/skeleton.tscn")
const CORPSE_SCENE: PackedScene = preload("res://scenes/world/corpse.tscn")

var player: Node2D
var enemies: Array[Node2D] = []
var corpses: Array[Node2D] = []
var skeletons: Array[Node2D] = []
var skeleton_cap: int = 5
var essence: int = 0
var kills_since_reward: int = 0

@export var essence_per_kill: int = 1
@export var kills_per_reward: int = 3

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
		skeleton_cap_changed.emit(get_skeleton_count(), skeleton_cap)


func unregister_skeleton(skeleton: Node2D) -> void:
	if skeleton in skeletons:
		skeletons.erase(skeleton)
		skeleton_unregistered.emit(skeleton)
		skeleton_cap_changed.emit(get_skeleton_count(), skeleton_cap)


func get_skeleton_count() -> int:
	_prune_invalid_units(skeletons)
	return skeletons.size()


func can_spawn_skeleton() -> bool:
	return get_skeleton_count() < skeleton_cap


func spawn_skeleton(spawn_position: Vector2) -> Node2D:
	if not can_spawn_skeleton():
		print("Skeleton cap reached: %d/%d" % [get_skeleton_count(), skeleton_cap])
		return null

	var skeleton := SKELETON_SCENE.instantiate() as Node2D
	skeleton.global_position = spawn_position
	get_tree().current_scene.add_child(skeleton)
	register_skeleton(skeleton)
	skeleton_spawned.emit(skeleton)
	print("Resurrected skeleton at %s" % skeleton.global_position)
	return skeleton


func spawn_corpse(spawn_position: Vector2) -> Node2D:
	var corpse := CORPSE_SCENE.instantiate() as Node2D
	corpse.global_position = spawn_position
	get_tree().current_scene.add_child(corpse)
	corpse_spawned.emit(corpse)
	print("Spawned corpse at %s" % corpse.global_position)
	return corpse


func record_enemy_kill(enemy: Node2D, source: Node) -> void:
	essence += essence_per_kill
	kills_since_reward += 1
	enemy_killed.emit(enemy, source)
	essence_changed.emit(essence)
	print("Enemy killed. Essence: %d. Reward progress: %d/%d" % [essence, kills_since_reward, kills_per_reward])

	if kills_since_reward >= kills_per_reward:
		kills_since_reward = 0
		_apply_progression_reward()


func _apply_progression_reward() -> void:
	skeleton_cap += 1
	skeleton_cap_changed.emit(get_skeleton_count(), skeleton_cap)
	var message := "Skeleton cap increased to %d" % skeleton_cap
	print(message)
	progression_reward_applied.emit(message)


func get_health_component(unit: Node) -> HealthComponent:
	if unit == null or not is_instance_valid(unit):
		return null

	return unit.get_node_or_null("HealthComponent") as HealthComponent


func _prune_invalid_units(units: Array[Node2D]) -> void:
	for index in range(units.size() - 1, -1, -1):
		if not is_instance_valid(units[index]):
			units.remove_at(index)


func get_nearest_enemy(from_position: Vector2, max_distance: float) -> Node2D:
	var nearest_enemy: Node2D
	var nearest_distance := max_distance

	for enemy in enemies:
		if not is_instance_valid(enemy):
			continue
		var health := get_health_component(enemy)
		if health == null or health.is_dead:
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
