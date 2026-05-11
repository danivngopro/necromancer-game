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
	_assert(is_equal_approx(player.cast_range, 220.0), "Player cast range should be reduced by 20")
	_assert(player.attack_damage == 1, "Player auto attack should deal 1 damage")
	_assert(player_stats.get_move_speed() == 80.0, "Player base speed should be 30 percent slower")
	player_stats.add_experience(player_stats.get_experience_to_next_level())
	_assert(player_stats.stat_points == 2, "Player should gain two stat points per level")
	player_stats.stat_points = 0
	_assert(is_equal_approx(player_stats.get_player_damage_bonus(), 0.0), "Strength should start with no damage bonus")
	player_stats.strength = 3
	_assert(is_equal_approx(player_stats.get_player_damage_bonus(), 0.3), "Strength should add 0.1 damage per level")
	_assert(is_equal_approx(player._get_cast_damage(), 1.3), "Low strength should add fractional player damage")
	player_stats.strength = 10
	_assert(is_equal_approx(player._get_cast_damage(), 2.0), "Ten strength levels should add one full player damage")
	player_stats.strength = 0

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
	_assert((enemy.get_node("UnitFeedback/HpLabel") as Label).text == "16/16", "Enemy HP label should update immediately after level configuration")
	_assert(is_equal_approx(enemy_ai.leash_distance, 240.0), "Enemy leash should stay larger than player cast range")
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
	_assert(main_scene.get_node_or_null("UI/UnitNameplateOverlay") != null, "Main scene should have screen-space unit nameplates")
	_assert(enemy.get_node_or_null("UnitFeedback/NameLabel") != null, "Enemy health UI should include level/name label")

	player_stats.black_mana = 3
	var inherited_skeleton := GameManager.spawn_skeleton(Vector2(40.0, 40.0), 3, 16, 4, 102.0)
	var inherited_health := GameManager.get_health_component(inherited_skeleton)
	_assert(inherited_health.max_health == 8, "Revived skeleton HP should inherit 50 percent of slain enemy HP")
	_assert(inherited_skeleton.attack_damage == 2, "Revived skeleton damage should inherit 50 percent of slain enemy damage")
	_assert(is_equal_approx(inherited_skeleton.move_speed, 81.6), "Revived skeleton speed should inherit 80 percent of slain enemy speed")
	inherited_skeleton.queue_free()

	var mana_before := player_stats.black_mana
	player_stats.stat_points = 1
	_assert(player_stats.increase_stat("black_mana"), "Black mana stat should be allocatable")
	_assert(player_stats.black_mana == mana_before + 1, "Black mana stat should add one max mana")
	mana_before = player_stats.black_mana
	player_stats.stat_points = 1
	_assert(player_stats.increase_stat("mana_regen"), "Mana regen stat should be allocatable")
	_assert(player_stats.black_mana == mana_before, "Mana regen stat should not change max dark mana")
	var strength_before: int = player_stats.strength
	player_stats.stat_points = 1
	_assert(player_stats.increase_stat("strength"), "Strength stat should be allocatable")
	_assert(player_stats.strength == strength_before + 1, "Strength stat should increase by one level")

	var rpg_ui := main_scene.get_node("UI/RPGDebugUI") as RPGDebugUI
	_assert(rpg_ui.STAT_ROWS[0] == "hp", "Stat order should start with HP")
	_assert(rpg_ui.STAT_ROWS[1] == "strength", "Strength should be the second stat row")
	_assert(rpg_ui.STAT_ROWS[2] == "black_mana", "Dark mana should follow strength")
	_assert(rpg_ui is PanelContainer, "Stat panel should use real row containers")
	_assert(rpg_ui.stat_buttons["strength"].get_parent().name == "strengthRow", "Strength plus button should live in the strength row")
	_assert(rpg_ui.stat_buttons["black_mana"].get_parent().name == "black_manaRow", "Dark mana plus button should live in the dark mana row")
	_assert(rpg_ui.stat_buttons["strength"].global_position.y < rpg_ui.stat_buttons["black_mana"].global_position.y, "Stat plus buttons should be vertically ordered by their rows")
	_assert((rpg_ui.stat_buttons["strength"] as Button).custom_minimum_size.y >= 22.0, "Stat plus click target should cover the visible plus")

	var player_body := player.get_node_or_null("Body") as AnimatedSprite2D
	var enemy_body := enemy.get_node_or_null("Body") as AnimatedSprite2D
	var skeleton_body := inherited_skeleton.get_node_or_null("Body") as AnimatedSprite2D
	player.velocity = Vector2.LEFT
	player_body._process(0.1)
	_assert(player_body.flip_h, "Player sprite should face left when moving left")
	player.velocity = Vector2.RIGHT
	player_body._process(0.1)
	_assert(not player_body.flip_h, "Player sprite should face right when moving right")
	_assert(player_body != null and player_body.sprite_frames.has_animation("idle"), "Player should use AnimatedSprite2D idle frames")
	_assert(player_body.sprite_frames.has_animation("walk"), "Player should use AnimatedSprite2D walk frames")
	_assert(player_body.sprite_frames.has_animation("attack"), "Player should use AnimatedSprite2D attack frames")
	_assert(player_body.sprite_frames.has_animation("death"), "Player should use AnimatedSprite2D death frames")
	_assert(enemy_body != null and enemy_body.sprite_frames.has_animation("walk"), "Enemy should use AnimatedSprite2D walk frames")
	_assert(enemy_body.sprite_frames.has_animation("walk_up"), "Enemy should use directional upward walk frames")
	_assert(enemy_body.sprite_frames.has_animation("walk_down"), "Enemy should use directional downward walk frames")
	_assert(enemy_body.sprite_frames.has_animation("attack_left"), "Enemy should use directional left attack frames")
	_assert(enemy_body.sprite_frames.get_frame_count("death") >= 6, "Enemy should use the goblin death animation frames")
	_assert(skeleton_body != null and skeleton_body.sprite_frames.has_animation("death"), "Skeleton should use AnimatedSprite2D death frames")
	var forest_map := main_scene.get_node_or_null("ForestTileMap") as ForestTileMap
	_assert(forest_map != null, "Main scene should use a forest TileMap test area")
	_assert(forest_map.get_used_cells(0).size() > 100, "Forest TileMap should fill ground cells")
	_assert(not forest_map.has_bad_ground_tree_tiles(), "Forest ground should not use partial tree atlas cells")
	_assert(not forest_map.has_blue_path_tiles(), "Forest should not use the source image blue background as paths")
	_assert(forest_map.get_prop_count() >= 20, "Forest should place varied tree and rock props")
	_assert(forest_map.get_collision_prop_count() >= 20, "Forest props should have collision bodies")
	_assert(forest_map.get_spawn_safe_position(Vector2.ZERO).distance_to(forest_map.get_nearest_blocking_prop_position(Vector2.ZERO)) >= 96.0, "Enemy spawn fallback should avoid blocked tree clusters")
	_assert(forest_map.get_prop_texture_has_transparency(), "Forest prop textures should have transparent backgrounds")
	_assert(main_scene.get_node_or_null("WorldObstacles/NorthRock/Visual") is Sprite2D, "Old box obstacles should be replaced by object sprites")
	var ruin_visual := main_scene.get_node("WorldObstacles/SouthRuin/Visual") as RawTextureSprite
	_assert(ruin_visual.texture_path.contains("kenney/props/ruin_wall"), "Large blockage should use the Kenney ruins/forest prop pack")
	_assert(main_scene.get_node_or_null("WorldBorder").visible == false, "World border color boxes should be hidden")
	_assert(forest_map.get_prop_count() == forest_map.get_in_bounds_prop_count(), "Forest props should stay inside map bounds")
	_assert(main_scene.get_path_next_position(Vector2(-600, -160), Vector2(500, 700)).distance_to(Vector2(500, 700)) > 24.0, "AI pathing should return an intermediate path point around forest blockers")
	_assert(main_scene.get_path_next_position(Vector2(-360, 190), Vector2(-160, 190)).y != 190.0, "AI pathing should route around scene world obstacles")
	_assert(player.has_method("_get_path_next_position"), "Player click-to-move should use shared pathing")
	var camera := player.get_node("Camera2D") as Camera2D
	_assert(camera.limit_left == -700 and camera.limit_right == 700, "Camera should stop at horizontal map borders")
	_assert(camera.limit_top == -260 and camera.limit_bottom == 980, "Camera should stop at vertical map borders")

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
