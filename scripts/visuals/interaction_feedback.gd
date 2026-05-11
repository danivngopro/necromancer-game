class_name InteractionFeedback
extends Node2D

@export var marker_lifetime: float = 0.55
@export var command_lifetime: float = 0.75

func show_move_marker(world_position: Vector2) -> void:
	_spawn_ring("MoveMarker", world_position, Color(0.45, 0.9, 1.0, 0.85), 12.0, marker_lifetime)


func show_attack_command(from_position: Vector2, target: Node2D) -> void:
	if target == null or not is_instance_valid(target):
		return

	_spawn_ring("TargetRing", target.global_position, Color(1.0, 0.25, 0.12, 0.9), 18.0, command_lifetime)
	_spawn_line("CommandLine", from_position, target.global_position, Color(1.0, 0.35, 0.1, 0.55), command_lifetime)


func show_cast_marker(from_position: Vector2, target: Node2D) -> void:
	if target == null or not is_instance_valid(target):
		return

	_spawn_ring("CastMarker", target.global_position, Color(0.55, 0.35, 1.0, 0.85), 14.0, marker_lifetime)
	_spawn_line("CastLine", from_position, target.global_position, Color(0.55, 0.35, 1.0, 0.45), marker_lifetime)


func show_cast_blocked(world_position: Vector2, reason: String) -> void:
	_spawn_ring("BlockedCastMarker", world_position, Color(0.95, 0.1, 0.08, 0.85), 10.0, 0.35)
	_spawn_popup(world_position + Vector2(-24, -28), reason, Color(1.0, 0.22, 0.12, 1.0), 0.45)


func show_range_preview(center_position: Vector2, radius: float) -> void:
	_spawn_ring("CastRangePreview", center_position, Color(0.55, 0.35, 1.0, 0.32), radius, 0.45)


func _spawn_ring(marker_name: String, world_position: Vector2, color: Color, radius: float, lifetime: float) -> void:
	var ring := Line2D.new()
	ring.name = marker_name
	ring.z_index = 65
	ring.width = 2.0
	ring.default_color = color
	ring.closed = true
	var points := PackedVector2Array()
	for index in 48:
		var angle := TAU * float(index) / 48.0
		points.append(Vector2(cos(angle), sin(angle)) * radius)
	ring.points = points
	add_child(ring)
	ring.global_position = world_position

	var tween := ring.create_tween()
	tween.set_parallel(true)
	tween.tween_property(ring, "scale", Vector2(1.8, 1.8), lifetime)
	tween.tween_property(ring, "modulate:a", 0.0, lifetime)
	tween.set_parallel(false)
	tween.tween_callback(ring.queue_free)


func _spawn_line(line_name: String, from_position: Vector2, to_position: Vector2, color: Color, lifetime: float) -> void:
	var line := Line2D.new()
	line.name = line_name
	line.z_index = 64
	line.width = 2.0
	line.default_color = color
	line.points = PackedVector2Array([from_position, to_position])
	add_child(line)

	var tween := line.create_tween()
	tween.tween_property(line, "modulate:a", 0.0, lifetime)
	tween.tween_callback(line.queue_free)


func _spawn_popup(world_position: Vector2, text: String, color: Color, lifetime: float) -> void:
	var popup := Label.new()
	popup.name = "CastFeedbackPopup"
	popup.text = text
	popup.z_index = 70
	popup.add_theme_color_override("font_color", color)
	popup.add_theme_font_size_override("font_size", 11)
	add_child(popup)
	popup.global_position = world_position

	var tween := popup.create_tween()
	tween.set_parallel(true)
	tween.tween_property(popup, "global_position", world_position + Vector2(0, -14), lifetime)
	tween.tween_property(popup, "modulate:a", 0.0, lifetime)
	tween.set_parallel(false)
	tween.tween_callback(popup.queue_free)
