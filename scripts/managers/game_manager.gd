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
signal enemy_selection_changed(enemy: Node2D)
signal combat_logged(message: String)

const SKELETON_SCENE: PackedScene = preload("res://scenes/skeletons/skeleton.tscn")
const CORPSE_SCENE: PackedScene = preload("res://scenes/world/corpse.tscn")

var player: Node2D
var player_stats: Node
var commanded_attack_target: Node2D
var selected_enemy: Node2D
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
	select_enemy(target)
	attack_commanded.emit(target)


func clear_attack_command() -> void:
	commanded_attack_target = null
	attack_command_cleared.emit()


func select_enemy(enemy: Node2D) -> void:
	if selected_enemy == enemy:
		return

	var previous_enemy := selected_enemy
	selected_enemy = enemy
	if previous_enemy != null and is_instance_valid(previous_enemy) and previous_enemy.has_method("set_selected"):
		previous_enemy.set_selected(false)
	if selected_enemy != null and is_instance_valid(selected_enemy) and selected_enemy.has_method("set_selected"):
		selected_enemy.set_selected(true)
	enemy_selection_changed.emit(selected_enemy)


func log_combat(message: String) -> void:
	print(message)
	combat_logged.emit(message)


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


func spawn_skeleton(spawn_position: Vector2, corpse_level: int = 1, source_max_health: int = 6, source_damage: int = 1, source_move_speed: float = 135.0) -> Node2D:
	if not can_spawn_skeleton():
		print("Skeleton cap reached: %d/%d" % [get_skeleton_count(), skeleton_cap])
		return null

	var skeleton := SKELETON_SCENE.instantiate() as Node2D
	skeleton.global_position = spawn_position
	var dark_mana_level: int = int(player_stats.black_mana) if player_stats != null and "black_mana" in player_stats else 1
	var inherited_factor := 0.10 + (float(maxi(dark_mana_level - 1, 0)) * 0.01)
	if "attack_damage" in skeleton:
		skeleton.attack_damage = maxi(1, roundi(float(source_damage) * inherited_factor))
	if "move_speed" in skeleton:
		skeleton.move_speed = source_move_speed * 0.8
	if "attack_cooldown" in skeleton and player_stats != null:
		skeleton.attack_cooldown = maxf(0.45, skeleton.attack_cooldown - player_stats.get_skeleton_attack_speed_bonus())
	var skeleton_health := get_health_component(skeleton)
	if skeleton_health != null:
		skeleton_health.max_health = maxi(1, roundi(float(source_max_health) * inherited_factor))
	get_tree().current_scene.add_child(skeleton)
	register_skeleton(skeleton)
	skeleton_spawned.emit(skeleton)
	print("Resurrected skeleton at %s" % skeleton.global_position)
	return skeleton


func spawn_corpse(spawn_position: Vector2, corpse_level: int = 1, source_max_health: int = 6, source_damage: int = 1, source_move_speed: float = 135.0) -> Node2D:
	var corpse := CORPSE_SCENE.instantiate() as Node2D
	corpse.global_position = spawn_position
	if "corpse_level" in corpse:
		corpse.corpse_level = corpse_level
	if "source_max_health" in corpse:
		corpse.source_max_health = source_max_health
	if "source_damage" in corpse:
		corpse.source_damage = source_damage
	if "source_move_speed" in corpse:
		corpse.source_move_speed = source_move_speed
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
	var enemy_name: String = enemy.name if enemy != null else "Enemy"
	log_combat("%s killed: +%d EXP, +%d Mana, +%d Essence" % [enemy_name, experience_reward, 1, essence_per_kill])
	if enemy != null and is_instance_valid(enemy):
		spawn_reward_popup(enemy.global_position, "+%d EXP" % experience_reward, Color(0.85, 1.0, 0.35, 1.0))
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


func spawn_reward_popup(world_position: Vector2, message: String, color: Color = Color(0.85, 1.0, 0.35, 1.0)) -> Label:
	var popup := Label.new()
	popup.name = "RewardPopup"
	popup.text = message
	popup.z_index = 80
	popup.add_theme_color_override("font_color", color)
	popup.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0, 1.0))
	popup.add_theme_constant_override("outline_size", 2)
	popup.add_theme_font_size_override("font_size", 14)

	var parent := get_tree().current_scene if get_tree().current_scene != null else self
	parent.add_child(popup)
	if parent is Node2D:
		popup.global_position = world_position + Vector2(-18, -34)
	else:
		popup.position = world_position + Vector2(-18, -34)

	var tween := popup.create_tween()
	tween.set_parallel(true)
	tween.tween_property(popup, "position", popup.position + Vector2(0, -28), 1.0)
	tween.tween_property(popup, "modulate:a", 0.0, 1.0)
	tween.set_parallel(false)
	tween.tween_callback(popup.queue_free)
	return popup


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
		"mana_regen": player_stats.mana_regen,
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
	player_stats.current_black_mana = float(data.get("current_black_mana", player_stats.current_black_mana))
	player_stats.army_size = int(data.get("army_size", player_stats.army_size))
	player_stats.movement_speed = int(data.get("movement_speed", player_stats.movement_speed))
	player_stats.mana_regen = int(data.get("mana_regen", player_stats.mana_regen))
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
