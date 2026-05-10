class_name RangeGizmo
extends Node2D

@export var detection_range: float = 0.0
@export var attack_range: float = 0.0
@export var detection_color: Color = Color(0.1, 0.65, 1.0, 0.2)
@export var attack_color: Color = Color(1.0, 0.25, 0.1, 0.35)
@export var enabled: bool = true

func _ready() -> void:
	z_index = 20
	queue_redraw()


func _draw() -> void:
	if not enabled:
		return

	if detection_range > 0.0:
		draw_arc(Vector2.ZERO, detection_range, 0.0, TAU, 72, detection_color, 1.5)

	if attack_range > 0.0:
		draw_arc(Vector2.ZERO, attack_range, 0.0, TAU, 48, attack_color, 2.0)
