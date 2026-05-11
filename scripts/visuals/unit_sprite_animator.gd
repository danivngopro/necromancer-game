class_name UnitSpriteAnimator
extends AnimatedSprite2D

@export_enum("player", "enemy", "skeleton") var sprite_kind: String = "enemy"
@export var frame_scale: Vector2 = Vector2.ONE

var _locked_animation: bool = false
var _last_direction: Vector2 = Vector2.DOWN

func _ready() -> void:
	centered = true
	scale = frame_scale
	sprite_frames = _build_frames()
	if not animation_finished.is_connected(_on_animation_finished):
		animation_finished.connect(_on_animation_finished)
	if sprite_frames.has_animation("idle"):
		play("idle")


func _process(_delta: float) -> void:
	if _locked_animation:
		return

	var body := get_parent() as CharacterBody2D
	if body != null:
		_update_facing(body.velocity)
	if body != null and body.velocity.length_squared() > 4.0:
		_play_directional("walk")
	else:
		_play_directional("idle")


func play_attack_once() -> void:
	_locked_animation = true
	_play_directional("attack")


func play_death_once() -> void:
	_locked_animation = true
	_play_if_changed("death")


func _on_animation_finished() -> void:
	if animation == "death":
		return
	_locked_animation = false


func _play_if_changed(animation_name: String) -> void:
	if sprite_frames == null or not sprite_frames.has_animation(animation_name):
		return
	if animation != animation_name:
		play(animation_name)


func face_toward(world_position: Vector2) -> void:
	var delta := world_position - global_position
	_update_facing(delta)


func _update_facing(direction: Vector2) -> void:
	if direction.length_squared() > 0.25:
		_last_direction = direction
	if absf(direction.x) <= 0.5:
		return
	flip_h = direction.x < 0.0


func _play_directional(base_animation: String) -> void:
	var animation_name := _directional_animation_name(base_animation)
	if sprite_frames != null and sprite_frames.has_animation(animation_name):
		_play_if_changed(animation_name)
		return
	_play_if_changed(base_animation)


func _directional_animation_name(base_animation: String) -> String:
	if absf(_last_direction.x) > absf(_last_direction.y):
		return "%s_left" % base_animation if _last_direction.x < 0.0 else "%s_right" % base_animation
	return "%s_up" % base_animation if _last_direction.y < 0.0 else "%s_down" % base_animation


func _build_frames() -> SpriteFrames:
	var frames := SpriteFrames.new()
	frames.remove_animation("default")
	match sprite_kind:
		"player":
			_build_atlas_frames(frames, "res://assets/sprites/opengameart/necromancer_64.png", Vector2i(64, 64), {
				"idle": [Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0), Vector2i(3, 0)],
				"walk": [Vector2i(0, 1), Vector2i(1, 1), Vector2i(2, 1), Vector2i(3, 1)],
				"attack": [Vector2i(4, 2), Vector2i(5, 2), Vector2i(6, 2), Vector2i(7, 2)],
				"death": [Vector2i(8, 3), Vector2i(9, 3), Vector2i(10, 3), Vector2i(11, 3)]
			}, 7.0)
		"enemy":
			var goblin_root := "res://assets/sprites/opengameart/goblin_free"
			_build_file_sequence(frames, "idle_right", goblin_root + "/idle_right/idle_right_%02d.png", 0, 7, 8.0, true)
			_build_file_sequence(frames, "idle_left", goblin_root + "/idle_left/idle_left_%02d.png", 0, 7, 8.0, true)
			_build_file_sequence(frames, "idle_down", goblin_root + "/idle_front/idle_front_%02d.png", 0, 7, 8.0, true)
			_clone_animation(frames, "idle_up", "idle_down", true)
			_build_file_sequence(frames, "walk_right", goblin_root + "/run_right/run_right_%02d.png", 0, 5, 10.0, true)
			_build_file_sequence(frames, "walk_left", goblin_root + "/run_left/run_left_%02d.png", 0, 5, 10.0, true)
			_clone_animation(frames, "walk_up", "idle_down", true)
			_clone_animation(frames, "walk_down", "idle_down", true)
			_build_file_sequence(frames, "attack_right", goblin_root + "/attack_right/attack_right_%02d.png", 0, 2, 10.0, false)
			_build_file_sequence(frames, "attack_left", goblin_root + "/attack_left/attack_left_%02d.png", 0, 2, 10.0, false)
			_clone_animation(frames, "attack_up", "attack_right", false)
			_clone_animation(frames, "attack_down", "attack_right", false)
			_build_file_sequence(frames, "death", goblin_root + "/death/death_%02d.png", 0, 7, 8.0, false)
			_clone_animation(frames, "idle", "idle_down", true)
			_clone_animation(frames, "walk", "walk_right", true)
			_clone_animation(frames, "attack", "attack_right", false)
		"skeleton":
			_build_file_sequence(frames, "idle", "res://assets/sprites/opengameart/skeleton/skeleton/idle/right/idle_right%04d.png", 0, 10, 8.0, true)
			_build_file_sequence(frames, "walk", "res://assets/sprites/opengameart/skeleton/skeleton/walk/right/walk_right%04d.png", 0, 7, 9.0, true)
			_build_file_sequence(frames, "attack", "res://assets/sprites/opengameart/skeleton/skeleton/throw/right/throw_right%04d.png", 0, 8, 11.0, false)
			_build_file_sequence(frames, "death", "res://assets/sprites/opengameart/skeleton/skeleton/die/right/die_right%04d.png", 0, 6, 9.0, false)
	return frames


func _build_atlas_frames(frames: SpriteFrames, path: String, frame_size: Vector2i, animation_map: Dictionary, speed: float) -> void:
	var atlas := _load_texture(path)
	if atlas == null:
		return

	for animation_name in animation_map.keys():
		frames.add_animation(animation_name)
		frames.set_animation_loop(animation_name, animation_name != "attack" and animation_name != "death")
		frames.set_animation_speed(animation_name, speed)
		for coords in animation_map[animation_name]:
			var texture := AtlasTexture.new()
			texture.atlas = atlas
			texture.region = Rect2(Vector2(coords.x * frame_size.x, coords.y * frame_size.y), frame_size)
			frames.add_frame(animation_name, texture)


func _build_file_sequence(frames: SpriteFrames, animation_name: String, pattern: String, first: int, last: int, speed: float, loops: bool) -> void:
	frames.add_animation(animation_name)
	frames.set_animation_loop(animation_name, loops)
	frames.set_animation_speed(animation_name, speed)
	for index in range(first, last + 1):
		var texture := _load_texture(pattern % index)
		if texture != null:
			frames.add_frame(animation_name, texture)


func _clone_animation(frames: SpriteFrames, new_name: String, source_name: String, loops: bool) -> void:
	if not frames.has_animation(source_name):
		return
	if frames.has_animation(new_name):
		frames.remove_animation(new_name)
	frames.add_animation(new_name)
	frames.set_animation_loop(new_name, loops)
	frames.set_animation_speed(new_name, frames.get_animation_speed(source_name))
	for index in frames.get_frame_count(source_name):
		frames.add_frame(new_name, frames.get_frame_texture(source_name, index), frames.get_frame_duration(source_name, index))


func _load_texture(path: String) -> Texture2D:
	var image := Image.new()
	var global_path := ProjectSettings.globalize_path(path)
	if FileAccess.file_exists(global_path) and image.load(global_path) == OK:
		return ImageTexture.create_from_image(image)

	if ResourceLoader.exists(path):
		return load(path) as Texture2D
	return null
