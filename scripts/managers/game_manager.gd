extends Node

signal player_registered(player: Node2D)
signal player_stats_registered(stats: Node)
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
signal attack_commanded(target: Node2D)
signal attack_command_cleared
signal skeleton_command_changed(mode: String)

const SKELETON_SCENE: PackedScene = preload("res://scenes/skeletons/skeleton.tscn")
const CORPSE_SCENE: PackedScene = preload("res://scenes/world/corpse.tscn")

var player: Node2D
var player_stats: Node
var commanded_attack_target: Node2D
var skeleton_command_mode: String = "follow"
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


func register_player_stats(stats: Node) -> void:
	player_stats = stats
	skeleton_cap = stats.get_skeleton_cap()
	stats.stats_changed.connect(_sync_from_player_stats)
	player_stats_registered.emit(stats)
	skeleton_cap_changed.emit(get_skeleton_count(), skeleton_cap)


func _sync_from_player_stats() -> void:
	if player_stats == null:
		return

	skeleton_cap = player_stats.get_skeleton_cap()
	skeleton_cap_changed.emit(get_skeleton_count(), skeleton_cap)


func command_attack_target(target: Node2D) -> void:
	commanded_attack_target = target
	attack_commanded.emit(target)


func clear_attack_command() -> void:
	commanded_attack_target = null
	attack_command_cleared.emit()


func set_skeleton_command_mode(mode: String) -> void:
	if mode not in ["follow", "hold", "attack"]:
		return

	skeleton_command_mode = mode
	skeleton_command_changed.emit(mode)
	print("Skeleton command: %s" % mode)


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


func get_skeleton_formation_position(skeleton: Node2D, base_distance: float) -> Vector2:
	if player == null or not is_instance_valid(player):
		return skeleton.global_position

	_prune_invalid_units(skeletons)
	var index := skeletons.find(skeleton)
	if index < 0:
		return player.global_position

	var count := maxi(skeletons.size(), 1)
	var angle := TAU * float(index) / float(count)
	var ring := base_distance + (float(index / 8) * 18.0)
	return player.global_position + (Vector2(cos(angle), sin(angle)) * ring)


func get_skeleton_attack_position(skeleton: Node2D, target: Node2D, radius: float) -> Vector2:
	if target == null or not is_instance_valid(target):
		return skeleton.global_position

	_prune_invalid_units(skeletons)
	var index := skeletons.find(skeleton)
	if index < 0:
		return target.global_position

	var count := maxi(skeletons.size(), 1)
	var angle := TAU * float(index) / float(count)
	return target.global_position + (Vector2(cos(angle), sin(angle)) * radius)


func can_spawn_skeleton() -> bool:
	return get_skeleton_count() < skeleton_cap


func spawn_skeleton(spawn_position: Vector2, corpse_level: int = 1) -> Node2D:
	if not can_spawn_skeleton():
		print("Skeleton cap reached: %d/%d" % [get_skeleton_count(), skeleton_cap])
		return null

	var skeleton := SKELETON_SCENE.instantiate() as Node2D
	skeleton.global_position = spawn_position
	if player_stats != null and "attack_damage" in skeleton:
		skeleton.attack_damage += player_stats.get_skeleton_damage_bonus() + maxi(corpse_level - 1, 0)
		if "attack_cooldown" in skeleton:
			skeleton.attack_cooldown = maxf(0.45, skeleton.attack_cooldown - player_stats.get_skeleton_attack_speed_bonus())
		var skeleton_health := get_health_component(skeleton)
		if skeleton_health != null:
			skeleton_health.max_health += player_stats.get_skeleton_health_bonus() + (maxi(corpse_level - 1, 0) * 3)
	get_tree().current_scene.add_child(skeleton)
	register_skeleton(skeleton)
	skeleton_spawned.emit(skeleton)
	print("Resurrected skeleton at %s" % skeleton.global_position)
	return skeleton


func spawn_corpse(spawn_position: Vector2, corpse_level: int = 1) -> Node2D:
	var corpse := CORPSE_SCENE.instantiate() as Node2D
	corpse.global_position = spawn_position
	if "corpse_level" in corpse:
		corpse.corpse_level = corpse_level
	get_tree().current_scene.add_child(corpse)
	corpse_spawned.emit(corpse)
	print("Spawned corpse at %s" % corpse.global_position)
	return corpse


func record_enemy_kill(enemy: Node2D, source: Node, experience_reward: int = 1) -> void:
	essence += essence_per_kill
	kills_since_reward += 1
	enemy_killed.emit(enemy, source)
	essence_changed.emit(essence)
	if player_stats != null:
		player_stats.add_experience(experience_reward)
		player_stats.restore_black_mana(1)
	print("Enemy killed. Essence: %d. Reward progress: %d/%d" % [essence, kills_since_reward, kills_per_reward])

	if kills_since_reward >= kills_per_reward:
		kills_since_reward = 0
		_apply_progression_reward()


func _apply_progression_reward() -> void:
	var player_health := get_health_component(player)
	if player_health != null:
		player_health.heal(3)
	var message := "HP restored"
	print(message)
	progression_reward_applied.emit(message)


func save_game() -> void:
	if player_stats == null:
		return

	var data := {
		"player_position": [player.global_position.x, player.global_position.y] if player != null else [0, 0],
		"level": player_stats.level,
		"experience": player_stats.experience,
		"stat_points": player_stats.stat_points,
		"hp": player_stats.hp,
		"black_mana": player_stats.black_mana,
		"current_black_mana": player_stats.current_black_mana,
		"army_size": player_stats.army_size,
		"movement_speed": player_stats.movement_speed,
		"skeleton_count": get_skeleton_count()
	}
	var file := FileAccess.open("user://necromancer_save.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(data))
	print("Game saved")


func load_game() -> void:
	if not FileAccess.file_exists("user://necromancer_save.json") or player_stats == null:
		return

	var file := FileAccess.open("user://necromancer_save.json", FileAccess.READ)
	var data := JSON.parse_string(file.get_as_text()) as Dictionary
	if data.is_empty():
		return

	player_stats.level = int(data.get("level", player_stats.level))
	player_stats.experience = int(data.get("experience", player_stats.experience))
	player_stats.stat_points = int(data.get("stat_points", player_stats.stat_points))
	player_stats.hp = int(data.get("hp", player_stats.hp))
	player_stats.black_mana = int(data.get("black_mana", player_stats.black_mana))
	player_stats.current_black_mana = int(data.get("current_black_mana", player_stats.current_black_mana))
	player_stats.army_size = int(data.get("army_size", player_stats.army_size))
	player_stats.movement_speed = int(data.get("movement_speed", player_stats.movement_speed))
	player_stats._emit_all()
	if player != null:
		var pos: Array = data.get("player_position", [0, 0])
		player.global_position = Vector2(float(pos[0]), float(pos[1]))
		_restore_saved_army(int(data.get("skeleton_count", 0)))
	print("Game loaded")


func _restore_saved_army(saved_skeleton_count: int) -> void:
	var existing_skeletons := skeletons.duplicate()
	for skeleton in existing_skeletons:
		if is_instance_valid(skeleton):
			skeleton.queue_free()
	skeletons.clear()

	var restore_count := mini(saved_skeleton_count, skeleton_cap)
	for index in restore_count:
		var angle := TAU * float(index) / maxf(float(restore_count), 1.0)
		spawn_skeleton(player.global_position + (Vector2(cos(angle), sin(angle)) * 42.0))


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
