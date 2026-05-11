class_name CombatProjectile
extends Node2D

signal impact(target: Node2D)

@export var travel_speed: float = 420.0
@export var impact_radius: float = 5.0

var target: Node2D
var target_position: Vector2
var damage: int = 0
var source: Node
var projectile_color: Color = Color(0.65, 0.35, 1.0, 1.0)

func launch(start_position: Vector2, new_target: Node2D, new_damage: int, new_source: Node, color: Color = Color(0.65, 0.35, 1.0, 1.0)) -> void:
	global_position = start_position
	target = new_target
	damage = new_damage
	source = new_source
	projectile_color = color
	target_position = new_target.global_position if new_target != null and is_instance_valid(new_target) else start_position
	queue_redraw()


func _physics_process(delta: float) -> void:
	if target != null and is_instance_valid(target):
		target_position = target.global_position

	var to_target := target_position - global_position
	if to_target.length() <= impact_radius:
		_apply_impact()
		return

	global_position += to_target.normalized() * minf(travel_speed * delta, to_target.length())


func _draw() -> void:
	draw_circle(Vector2.ZERO, 4.0, projectile_color)
	draw_circle(Vector2.ZERO, 8.0, Color(projectile_color.r, projectile_color.g, projectile_color.b, 0.18))


func _apply_impact() -> void:
	if target != null and is_instance_valid(target):
		var health := GameManager.get_health_component(target)
		if health != null and damage > 0:
			health.apply_damage(damage, source)
		impact.emit(target)
	queue_free()
