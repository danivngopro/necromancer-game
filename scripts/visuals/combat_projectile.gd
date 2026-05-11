class_name CombatProjectile
extends Node2D

signal impact(target: Node2D)

@export var travel_speed: float = 420.0
@export var impact_radius: float = 5.0

var target: Node2D
var target_position: Vector2
var damage: float = 0.0
var source: Node
var projectile_color: Color = Color(0.65, 0.35, 1.0, 1.0)

func launch(start_position: Vector2, new_target: Node2D, new_damage: float, new_source: Node, color: Color = Color(0.65, 0.35, 1.0, 1.0)) -> void:
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
	_spawn_impact_effect()
	if target != null and is_instance_valid(target):
		var health := GameManager.get_health_component(target)
		if health != null and damage > 0.0:
			var valid_source: Node = source if source != null and is_instance_valid(source) else null
			health.apply_damage(damage, valid_source)
			GameManager.log_combat("%s takes %s projectile damage" % [target.name, _format_amount(damage)])
		impact.emit(target)
	queue_free()


func _spawn_impact_effect() -> void:
	var effect := Polygon2D.new()
	effect.name = "ProjectileImpactEffect"
	effect.z_index = 70
	effect.color = Color(projectile_color.r, projectile_color.g, projectile_color.b, 0.48)
	effect.polygon = PackedVector2Array(
		[
			Vector2(0, -12),
			Vector2(5, -5),
			Vector2(13, 0),
			Vector2(5, 5),
			Vector2(0, 13),
			Vector2(-5, 5),
			Vector2(-12, 0),
			Vector2(-5, -5)
		]
	)

	var parent := get_tree().current_scene if get_tree().current_scene != null else self
	parent.add_child(effect)
	if parent is Node2D:
		effect.global_position = target_position
	else:
		effect.position = target_position

	var tween := effect.create_tween()
	tween.set_parallel(true)
	tween.tween_property(effect, "scale", Vector2(2.1, 2.1), 0.9)
	tween.tween_property(effect, "modulate:a", 0.0, 0.9)
	tween.set_parallel(false)
	tween.tween_callback(effect.queue_free)


func _format_amount(value: float) -> String:
	if is_equal_approx(value, roundf(value)):
		return "%d" % int(roundf(value))
	return "%.1f" % value
