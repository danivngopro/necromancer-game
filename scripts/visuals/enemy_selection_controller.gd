class_name EnemySelectionController
extends Node

@export var hover_radius: float = 34.0

var hovered_enemy: Node2D

func _process(_delta: float) -> void:
	var viewport := get_viewport()
	if viewport == null:
		return

	var mouse_position := viewport.get_camera_2d().get_global_mouse_position() if viewport.get_camera_2d() != null else Vector2.ZERO
	var enemy := GameManager.get_nearest_enemy(mouse_position, hover_radius)
	if enemy == hovered_enemy:
		return

	if hovered_enemy != null and is_instance_valid(hovered_enemy) and hovered_enemy.has_method("set_hovered"):
		hovered_enemy.set_hovered(false)
	hovered_enemy = enemy
	if hovered_enemy != null and is_instance_valid(hovered_enemy) and hovered_enemy.has_method("set_hovered"):
		hovered_enemy.set_hovered(true)
