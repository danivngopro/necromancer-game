extends Node

func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	var packed_scene := load("res://scenes/world/main.tscn") as PackedScene
	var main_scene := packed_scene.instantiate()
	add_child(main_scene)
	await get_tree().process_frame
	await get_tree().physics_frame

	var player := main_scene.get_node("Player") as PlayerController
	var player_stats := player.get_node("PlayerStats") as PlayerStats
	var enemy := GameManager.get_nearest_enemy(player.global_position, 400.0)
	_assert(enemy != null, "Expected spawned enemy near player")
	player.global_position = enemy.global_position + Vector2(64.0, 0.0)
	_assert(is_equal_approx(player.cast_cooldown, 3.0), "Player cast cooldown should be 3 seconds")
	_assert(player.attack_damage == 1, "Player auto attack should deal 1 damage")
	_assert(player_stats.get_move_speed() == 80.0, "Player base speed should be 30 percent slower")

	player_stats.current_black_mana = 0.0
	player_stats.mana_regen = 0
	player_stats._process(1.0)
	_assert(is_equal_approx(player_stats.current_black_mana, 0.1), "Base mana regen should restore 0.1 mana per second")
	player_stats.mana_regen = 2
	_assert(is_equal_approx(player_stats.get_mana_regen_rate(), 0.12), "Mana regen stat should add 0.01 per level")

	var enemy_health := GameManager.get_health_component(enemy)
	_assert(enemy_health != null, "Expected enemy health")
	var start_health := enemy_health.current_health

	player._cast_ranged_attack(enemy.global_position)
	var health_after_fire := enemy_health.current_health
	player._cast_ranged_attack(enemy.global_position)
	var projectile_count := _count_nodes_named(get_tree().root, "CombatProjectile")
	_assert(health_after_fire == start_health, "Ranged cast should not deal immediate damage")
	_assert(projectile_count == 1, "Cooldown should block second immediate projectile")

	for index in 30:
		await get_tree().physics_frame
	_assert(enemy_health.current_health < start_health, "Projectile impact should damage enemy")
	_assert(_count_nodes_named(get_tree().root, "ProjectileImpactEffect") > 0, "Projectile impact should create a visible impact effect")

	var freed_source := Node2D.new()
	freed_source.name = "FreedProjectileSource"
	add_child(freed_source)
	var freed_source_projectile: Node = player.CombatProjectileScript.new()
	freed_source_projectile.name = "CombatProjectile"
	get_tree().current_scene.add_child(freed_source_projectile)
	freed_source_projectile.launch(enemy.global_position + Vector2(10.0, 0.0), enemy, 1, freed_source, Color(1.0, 1.0, 1.0, 1.0))
	freed_source.queue_free()
	await get_tree().process_frame
	for index in 10:
		await get_tree().physics_frame
	_assert(enemy_health.current_health < start_health, "Projectile with freed source should still apply damage safely")

	var enemy_ai := enemy as EnemyAI
	enemy_ai.global_position = enemy_ai.spawn_position + Vector2(enemy_ai.leash_distance + 80.0, 0.0)
	enemy_ai.force_aggro(player)
	await get_tree().physics_frame
	_assert(enemy_ai.state == EnemyAI.State.RETURN, "Enemy should enter RETURN when leash is exceeded")
	var far_distance := enemy_ai.global_position.distance_to(enemy_ai.spawn_position)
	for index in 20:
		await get_tree().physics_frame
	_assert(enemy_ai.global_position.distance_to(enemy_ai.spawn_position) < far_distance, "Enemy should move back toward spawn")

	enemy_ai.configure_level(1)
	_assert(enemy_ai.contact_damage == 1, "Level 1 enemy damage should be 1")
	_assert(enemy_health.max_health == 4, "Level 1 enemy health should be 4")
	_assert(enemy_ai.experience_reward == 2, "Level 1 enemy EXP should be 2")
	enemy_ai.configure_level(3)
	_assert(enemy_ai.contact_damage == 4, "Level 3 enemy damage should be 4")
	_assert(enemy_health.max_health == 16, "Level 3 enemy health should be 16")
	_assert(enemy_ai.experience_reward == 8, "Level 3 enemy EXP should be 8")
	_assert(enemy_ai.move_speed > 78.0, "Higher level enemies should move faster")
	_assert(main_scene.get_node_or_null("SpawnTimers/SpawnTimer0") != null, "Spawn locations should show respawn timer labels")

	var exp_before := player_stats.experience
	enemy_ai.set_meta("spawn_level", 3)
	GameManager.record_enemy_kill(enemy_ai, player, enemy_ai.experience_reward)
	_assert(player_stats.experience > exp_before, "Enemy kill should award EXP")
	var spawn_index := int(enemy_ai.get_meta("spawn_index", 0))
	_assert(main_scene.respawn_remaining_by_index[spawn_index] > 83.0, "Level 3 enemies should take 20 percent more respawn time per level")
	_assert((main_scene.get_node("SpawnTimers/SpawnTimer%d" % spawn_index) as Label).visible, "Respawn timer should be visible while waiting")
	_assert((main_scene.get_node("SpawnTimers/RespawnPingRing%d" % spawn_index) as Line2D).visible, "Respawn ping ring should be visible while waiting")
	_assert(_count_nodes_named(get_tree().root, "RewardPopup") > 0, "Enemy kill should spawn +EXP reward popup")
	_assert(main_scene.get_node_or_null("UI/ResourceHUD") != null, "Main scene should have a proper resource HUD")
	_assert(main_scene.get_node_or_null("UI/TargetFrame") != null, "Main scene should have a current target frame")
	_assert(enemy.get_node_or_null("UnitFeedback/NameLabel") != null, "Enemy health UI should include level/name label")

	player_stats.black_mana = 3
	var inherited_skeleton := GameManager.spawn_skeleton(Vector2(40.0, 40.0), 3, 16, 4, 102.0)
	var inherited_health := GameManager.get_health_component(inherited_skeleton)
	_assert(inherited_health.max_health == 2, "Revived skeleton HP should inherit 12 percent of level 3 enemy HP with dark mana")
	_assert(inherited_skeleton.attack_damage == 1, "Revived skeleton damage should inherit enemy damage with minimum 1")
	_assert(is_equal_approx(inherited_skeleton.move_speed, 81.6), "Revived skeleton speed should inherit 80 percent of slain enemy speed")
	inherited_skeleton.queue_free()

	var mana_before := player_stats.black_mana
	player_stats.stat_points = 1
	_assert(player_stats.increase_stat("black_mana"), "Black mana stat should be allocatable")
	_assert(player_stats.black_mana == mana_before + 1, "Black mana stat should add one max mana")

	print("Combat regression runner passed")
	get_tree().quit(0)


func _count_nodes_named(node: Node, node_name: String) -> int:
	var count := 1 if node.name == node_name else 0
	for child in node.get_children():
		count += _count_nodes_named(child, node_name)
	return count


func _assert(condition: bool, message: String) -> void:
	if condition:
		return

	push_error(message)
	get_tree().quit(1)
