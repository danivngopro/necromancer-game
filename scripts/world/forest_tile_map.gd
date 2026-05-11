class_name ForestTileMap
extends TileMap

@export var tile_texture: Texture2D
@export var tile_texture_path: String = "res://assets/tiles/opengameart/forest_tiles.png"
@export var world_size: Vector2i = Vector2i(46, 40)
@export var tile_pixel_size: Vector2i = Vector2i(16, 16)
@export var visual_scale: Vector2 = Vector2(2.0, 2.0)
@export var prop_seed: int = 371
@export var prop_count: int = 24

const GROUND_ATLAS := Vector2i(0, 0)
const PATH_ATLAS := Vector2i(0, 0)
const BLUE_BACKGROUND_ATLAS := Vector2i(1, 0)
const FORBIDDEN_GROUND_ATLAS: Array[Vector2i] = [
	Vector2i(3, 0),
	Vector2i(4, 0),
	Vector2i(5, 0),
	Vector2i(6, 0),
	Vector2i(7, 0),
	Vector2i(8, 0),
	Vector2i(9, 0),
	Vector2i(10, 0),
	Vector2i(11, 0),
	Vector2i(12, 0)
]

var _prop_root: Node2D
var _collision_prop_count: int = 0
var _prop_textures: Array[Texture2D] = []
var _blocked_cells: Dictionary = {}
var _astar: AStarGrid2D

func _ready() -> void:
	scale = visual_scale
	if tile_texture == null:
		tile_texture = _load_texture(tile_texture_path)
		if tile_texture == null:
			return

	tile_set = _make_tile_set()
	_prop_textures = _load_prop_textures()
	_fill_ground()
	_place_props()
	_rebuild_path_grid()


func get_prop_count() -> int:
	if _prop_root == null:
		return 0
	var count := 0
	for child in _prop_root.get_children():
		if child is Sprite2D:
			count += 1
	return count


func get_collision_prop_count() -> int:
	return _collision_prop_count


func get_in_bounds_prop_count() -> int:
	if _prop_root == null:
		return 0
	var count := 0
	for child in _prop_root.get_children():
		if child is Sprite2D and Rect2(Vector2(-700, -260), Vector2(1400, 1240)).has_point((child as Sprite2D).global_position):
			count += 1
	return count


func has_bad_ground_tree_tiles() -> bool:
	for cell in get_used_cells(0):
		if get_cell_source_id(0, cell) != 0:
			continue
		if FORBIDDEN_GROUND_ATLAS.has(get_cell_atlas_coords(0, cell)):
			return true
	return false


func has_blue_path_tiles() -> bool:
	for cell in get_used_cells(0):
		if get_cell_atlas_coords(0, cell) == BLUE_BACKGROUND_ATLAS:
			return true
	return false


func get_nearest_blocking_prop_position(world_position: Vector2) -> Vector2:
	if _prop_root == null:
		return Vector2.INF
	var nearest := Vector2.INF
	var nearest_distance := INF
	for child in _prop_root.get_children():
		if not child is StaticBody2D:
			continue
		var body := child as StaticBody2D
		var distance := body.global_position.distance_to(world_position)
		if distance < nearest_distance:
			nearest = body.global_position
			nearest_distance = distance
	return nearest


func get_spawn_safe_position(requested_position: Vector2) -> Vector2:
	if not is_position_blocked(requested_position, 96.0):
		return requested_position

	for ring in range(1, 7):
		var radius := float(ring) * 56.0
		for step in 16:
			var angle := TAU * float(step) / 16.0
			var candidate := requested_position + (Vector2(cos(angle), sin(angle)) * radius)
			if not is_position_blocked(candidate, 96.0):
				return candidate
	return requested_position


func register_world_blockers(root: Node) -> void:
	if root == null:
		return

	for child in root.get_children():
		if not child is StaticBody2D:
			continue
		var body := child as StaticBody2D
		var collision_shape := body.get_node_or_null("CollisionShape2D") as CollisionShape2D
		if collision_shape == null:
			continue
		var rectangle := collision_shape.shape as RectangleShape2D
		if rectangle == null:
			continue
		_mark_world_rectangle_blocked(collision_shape.global_position, rectangle.size)
	_rebuild_path_grid()


func is_position_blocked(world_position: Vector2, minimum_distance: float = 56.0) -> bool:
	var nearest := get_nearest_blocking_prop_position(world_position)
	return nearest != Vector2.INF and nearest.distance_to(world_position) < minimum_distance


func get_prop_texture_has_transparency() -> bool:
	for texture in _prop_textures:
		if texture == null:
			continue
		var image := texture.get_image()
		for x in image.get_width():
			for y in image.get_height():
				if image.get_pixel(x, y).a < 0.5:
					return true
	return false


func get_path_next_position(from_world: Vector2, to_world: Vector2) -> Vector2:
	if _astar == null:
		return to_world

	var from_cell := local_to_map(to_local(from_world))
	var to_cell := local_to_map(to_local(to_world))
	if not _astar.region.has_point(from_cell) or not _astar.region.has_point(to_cell):
		return to_world

	if _astar.is_point_solid(from_cell):
		from_cell = _nearest_open_cell(from_cell)
	if _astar.is_point_solid(to_cell):
		to_cell = _nearest_open_cell(to_cell)

	var path := _astar.get_id_path(from_cell, to_cell, true)
	if path.size() < 2:
		return from_world.move_toward(to_world, 24.0)
	var step_index := mini(3, path.size() - 1)
	return to_global(map_to_local(path[step_index]))


func _make_tile_set() -> TileSet:
	var set := TileSet.new()
	set.tile_size = tile_pixel_size
	var source := TileSetAtlasSource.new()
	source.texture = tile_texture
	source.texture_region_size = tile_pixel_size
	var atlas_size := tile_texture.get_size() / Vector2(tile_pixel_size)
	for x in int(atlas_size.x):
		for y in int(atlas_size.y):
			source.create_tile(Vector2i(x, y))
	set.add_source(source, 0)
	return set


func _fill_ground() -> void:
	clear()
	for x in range(-world_size.x / 2, world_size.x / 2):
		for y in range(-8, world_size.y - 8):
			var cell := Vector2i(x, y)
			set_cell(0, cell, 0, _ground_atlas_for(cell))


func _ground_atlas_for(cell: Vector2i) -> Vector2i:
	if abs(cell.x) < 3 or (cell.y > 17 and cell.y < 21):
		return PATH_ATLAS
	return GROUND_ATLAS


func _place_props() -> void:
	_prop_root = Node2D.new()
	_prop_root.name = "ForestProps"
	_prop_root.z_index = 3
	add_child(_prop_root)
	_collision_prop_count = 0

	var rng := RandomNumberGenerator.new()
	rng.seed = prop_seed
	var attempts := 0
	while get_prop_count() < prop_count and attempts < prop_count * 18:
		attempts += 1
		var cell := Vector2i(
			rng.randi_range(-world_size.x / 2 + 2, world_size.x / 2 - 3),
			rng.randi_range(-6, world_size.y - 10)
		)
		if _is_reserved_cell(cell) or _is_prop_near_cell(cell, 5):
			continue
		_add_prop(cell, rng.randi_range(0, 5))


func _is_reserved_cell(cell: Vector2i) -> bool:
	if abs(cell.x) < 5 or (cell.y > 15 and cell.y < 23):
		return true
	var world_position := to_global(map_to_local(cell))
	for spawn in [Vector2(-280, 30), Vector2(260, 90), Vector2(-420, 320), Vector2(360, 430), Vector2(120, 700), Vector2(-180, 860)]:
		if world_position.distance_to(spawn) < 96.0:
			return true
	return false


func _is_prop_near_cell(cell: Vector2i, min_distance: int) -> bool:
	if _prop_root == null:
		return false
	var world_position := to_global(map_to_local(cell))
	for child in _prop_root.get_children():
		if child is Node2D and (child as Node2D).position.distance_to(world_position) < float(min_distance * tile_pixel_size.x):
			return true
	return false


func _add_prop(cell: Vector2i, variant: int) -> void:
	var sprite := Sprite2D.new()
	sprite.name = "ForestProp"
	sprite.texture = _prop_textures[variant % _prop_textures.size()] if not _prop_textures.is_empty() else null
	sprite.centered = true
	sprite.position = map_to_local(cell)
	sprite.z_index = 2
	_prop_root.add_child(sprite)

	var body := StaticBody2D.new()
	body.name = "ForestPropCollision"
	body.collision_layer = 1
	body.collision_mask = 0
	body.position = sprite.position + _prop_collision_offset(variant)
	_prop_root.add_child(body)

	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = _prop_collision_size(variant)
	shape.shape = rect
	body.add_child(shape)
	_collision_prop_count += 1
	_mark_blocked_cells(cell, variant)


func _prop_collision_offset(variant: int) -> Vector2:
	match variant:
		0, 1, 2:
			return Vector2(0, 10)
		_:
			return Vector2.ZERO


func _prop_collision_size(variant: int) -> Vector2:
	match variant:
		0, 1, 2:
			return Vector2(16, 14)
		3:
			return Vector2(26, 14)
		4:
			return Vector2(28, 18)
		_:
			return Vector2(18, 12)


func _load_prop_textures() -> Array[Texture2D]:
	var paths: Array[String] = [
		"res://assets/sprites/kenney/props/tree_round.png",
		"res://assets/sprites/kenney/props/tree_broad.png",
		"res://assets/sprites/kenney/props/tree_pine.png",
		"res://assets/sprites/kenney/props/rock_large_gray.png",
		"res://assets/sprites/kenney/props/ruin_wall_tan.png",
		"res://assets/sprites/kenney/props/bush_round.png"
	]
	var textures: Array[Texture2D] = []
	for path in paths:
		var texture := _load_texture(path)
		if texture != null:
			textures.append(texture)
	return textures


func _mark_blocked_cells(cell: Vector2i, variant: int) -> void:
	var radius := 1
	for x in range(-radius, radius + 1):
		for y in range(-radius, radius + 1):
			_blocked_cells[cell + Vector2i(x, y)] = true


func _mark_world_rectangle_blocked(world_position: Vector2, size: Vector2) -> void:
	var half_size := size * 0.5
	var min_cell := local_to_map(to_local(world_position - half_size))
	var max_cell := local_to_map(to_local(world_position + half_size))
	for x in range(min_cell.x - 1, max_cell.x + 2):
		for y in range(min_cell.y - 1, max_cell.y + 2):
			_blocked_cells[Vector2i(x, y)] = true


func _rebuild_path_grid() -> void:
	_astar = AStarGrid2D.new()
	_astar.region = Rect2i(-world_size.x / 2, -8, world_size.x, world_size.y)
	_astar.cell_size = Vector2.ONE
	_astar.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES
	_astar.update()
	for cell in _blocked_cells.keys():
		if _astar.region.has_point(cell):
			_astar.set_point_solid(cell, true)


func _nearest_open_cell(origin: Vector2i) -> Vector2i:
	if _astar != null and _astar.region.has_point(origin) and not _astar.is_point_solid(origin):
		return origin
	for ring in range(1, 8):
		for x in range(-ring, ring + 1):
			for y in range(-ring, ring + 1):
				var cell := origin + Vector2i(x, y)
				if _astar.region.has_point(cell) and not _astar.is_point_solid(cell):
					return cell
	return origin


func _load_texture(path: String) -> Texture2D:
	var image := Image.new()
	if image.load(ProjectSettings.globalize_path(path)) == OK:
		return ImageTexture.create_from_image(image)

	return load(path) as Texture2D
