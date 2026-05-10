class_name Minimap
extends Control

@export var map_min: Vector2 = Vector2(-700, -260)
@export var map_max: Vector2 = Vector2(700, 980)
@export var player_color: Color = Color(0.45, 0.9, 1.0, 1.0)
@export var enemy_color: Color = Color(1.0, 0.16, 0.12, 1.0)
@export var skeleton_color: Color = Color(0.75, 0.95, 0.7, 1.0)

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.02, 0.05, 0.03, 0.68), true)
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.5, 0.85, 0.5, 0.8), false, 1.0)

	if GameManager.player != null:
		draw_circle(_world_to_minimap(GameManager.player.global_position), 3.0, player_color)

	for skeleton in GameManager.skeletons:
		if is_instance_valid(skeleton):
			draw_circle(_world_to_minimap(skeleton.global_position), 2.0, skeleton_color)

	for enemy in GameManager.enemies:
		if is_instance_valid(enemy):
			draw_circle(_world_to_minimap(enemy.global_position), 2.5, enemy_color)


func _world_to_minimap(world_position: Vector2) -> Vector2:
	var normalized := Vector2(
		inverse_lerp(map_min.x, map_max.x, world_position.x),
		inverse_lerp(map_min.y, map_max.y, world_position.y)
	)
	return Vector2(normalized.x * size.x, normalized.y * size.y)
