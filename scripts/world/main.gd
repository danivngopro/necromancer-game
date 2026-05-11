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
@export var base_enemy_respawn_seconds: float = 60.0
@export var starting_skeleton_count: int = 0
@export var starting_skeleton_radius: float = 46.0

@onready var enemies_root: Node2D = $Enemies
@onready var player: Node2D = $Player
@onready var forest_tile_map: ForestTileMap = get_node_or_null("ForestTileMap") as ForestTileMap

var respawn_remaining_by_index: Array[float] = []
var spawn_timer_labels: Array[Label] = []
var spawn_respawn_rings: Array[Line2D] = []

func _ready() -> void:
	if forest_tile_map != null:
		forest_tile_map.register_world_blockers($WorldObstacles)
	GameManager.enemy_killed.connect(_on_enemy_killed)
	_create_spawn_timer_labels()
	spawn_starting_skeletons()
	spawn_world_enemies()


func _process(delta: float) -> void:
	_clamp_player_to_map()
	_update_respawns(delta)


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
		spawn_enemy_at_index(index)


func spawn_enemy_at_index(index: int) -> Node2D:
	if enemies_root == null or basic_enemy_scene == null or index < 0 or index >= enemy_spawn_points.size():
		return null

	var requested_spawn_point := enemy_spawn_points[index]
	var spawn_point := _get_spawn_point(requested_spawn_point)
	var enemy := basic_enemy_scene.instantiate() as Node2D
	var level := enemy_spawn_levels[index] if index < enemy_spawn_levels.size() else 1
	enemy.global_position = spawn_point
	enemy.set_meta("spawn_index", index)
	enemy.set_meta("spawn_level", level)
	if enemy.has_method("configure_level"):
		enemy.configure_level(level)
	enemies_root.add_child(enemy)
	if index < respawn_remaining_by_index.size():
		respawn_remaining_by_index[index] = 0.0
	_refresh_spawn_label(index)
	print("Spawned world enemy %s at %s" % [enemy.name, enemy.global_position])
	return enemy


func _get_spawn_point(requested_spawn_point: Vector2) -> Vector2:
	if forest_tile_map != null:
		return forest_tile_map.get_spawn_safe_position(requested_spawn_point)
	return requested_spawn_point


func get_path_next_position(from_world: Vector2, to_world: Vector2) -> Vector2:
	if forest_tile_map != null:
		return forest_tile_map.get_path_next_position(from_world, to_world)
	return to_world


func _on_enemy_killed(enemy: Node2D, _source: Node) -> void:
	if enemy == null or not enemy.has_meta("spawn_index"):
		return

	var spawn_index := int(enemy.get_meta("spawn_index"))
	if spawn_index < 0 or spawn_index >= enemy_spawn_points.size():
		return

	var level := int(enemy.get_meta("spawn_level", 1))
	var respawn_seconds := base_enemy_respawn_seconds * (1.0 + (float(maxi(level - 1, 0)) * 0.2))
	respawn_remaining_by_index[spawn_index] = respawn_seconds
	_refresh_spawn_label(spawn_index)


func _create_spawn_timer_labels() -> void:
	var root := Node2D.new()
	root.name = "SpawnTimers"
	add_child(root)
	respawn_remaining_by_index.clear()
	spawn_timer_labels.clear()
	spawn_respawn_rings.clear()

	for index in enemy_spawn_points.size():
		respawn_remaining_by_index.append(0.0)
		var ring := _create_respawn_ring(index)
		root.add_child(ring)
		spawn_respawn_rings.append(ring)
		var label := Label.new()
		label.name = "SpawnTimer%d" % index
		label.visible = false
		label.z_index = 75
		label.position = enemy_spawn_points[index] + Vector2(-34.0, -32.0)
		label.add_theme_font_override("font", _make_ui_font())
		label.add_theme_font_size_override("font_size", 12)
		label.add_theme_color_override("font_color", Color(0.95, 0.95, 0.75, 1.0))
		label.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0, 1.0))
		label.add_theme_constant_override("outline_size", 2)
		root.add_child(label)
		spawn_timer_labels.append(label)


func _update_respawns(delta: float) -> void:
	for index in respawn_remaining_by_index.size():
		if respawn_remaining_by_index[index] <= 0.0:
			continue
		respawn_remaining_by_index[index] = maxf(respawn_remaining_by_index[index] - delta, 0.0)
		if respawn_remaining_by_index[index] == 0.0:
			spawn_enemy_at_index(index)
		else:
			_refresh_spawn_label(index)


func _refresh_spawn_label(index: int) -> void:
	if index < 0 or index >= spawn_timer_labels.size():
		return

	var label := spawn_timer_labels[index]
	var remaining := respawn_remaining_by_index[index]
	label.visible = remaining > 0.0
	label.text = "Respawn %ds" % ceili(remaining)
	if index < spawn_respawn_rings.size():
		var ring := spawn_respawn_rings[index]
		ring.visible = remaining > 0.0
		if remaining > 0.0:
			var pulse := 0.35 + (0.25 * sin(Time.get_ticks_msec() / 180.0))
			ring.default_color = Color(1.0, 0.86, 0.22, pulse)


func _create_respawn_ring(index: int) -> Line2D:
	var ring := Line2D.new()
	ring.name = "RespawnPingRing%d" % index
	ring.visible = false
	ring.z_index = 72
	ring.width = 2.0
	ring.closed = true
	ring.default_color = Color(1.0, 0.86, 0.22, 0.5)
	ring.position = enemy_spawn_points[index]
	var points := PackedVector2Array()
	for point_index in 40:
		var angle := TAU * float(point_index) / 40.0
		points.append(Vector2(cos(angle), sin(angle)) * 26.0)
	ring.points = points
	return ring


func _make_ui_font() -> SystemFont:
	var font := SystemFont.new()
	font.font_names = ["Segoe UI Semibold", "Segoe UI", "Arial"]
	font.antialiasing = TextServer.FONT_ANTIALIASING_LCD
	font.subpixel_positioning = TextServer.SUBPIXEL_POSITIONING_AUTO
	return font
