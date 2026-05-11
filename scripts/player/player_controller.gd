class_name PlayerController
extends CharacterBody2D

const CombatProjectileScript: Script = preload("res://scripts/visuals/combat_projectile.gd")

@export var move_speed: float = 180.0
@export var attack_damage: int = 1
@export var cast_range: float = 220.0
@export var cast_cooldown: float = 3.0
@export var click_enemy_radius: float = 32.0
@export var close_cast_assist_range: float = 72.0
@export var move_arrival_distance: float = 8.0
@export var cast_standoff_distance: float = 220.0

@onready var health: HealthComponent = $HealthComponent
@onready var resurrection_controller: ResurrectionController = $ResurrectionController
@onready var stats: Node = $PlayerStats

var _cast_timer: float = 0.0
var _next_cast_time_msec: int = 0
var _cast_target: Node2D
var _move_target: Vector2
var _has_move_target: bool = false

func _ready() -> void:
	GameManager.register_player(self)
	health.died.connect(_on_died)
	stats.stats_changed.connect(_apply_stats)
	_apply_stats()
	_update_cast_hud()


func _physics_process(delta: float) -> void:
	_cast_timer = _get_cast_time_remaining()
	_update_pending_cast()
	_handle_movement()
	_update_cast_hud()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_RIGHT:
		_handle_right_click(get_global_mouse_position())
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_cast_ranged_attack(get_global_mouse_position())
	elif event.is_action_pressed("resurrect"):
		resurrection_controller.request_resurrection()
	elif event.is_action_pressed("command_follow"):
		GameManager.set_skeleton_command_mode("follow")
	elif event.is_action_pressed("command_hold"):
		GameManager.set_skeleton_command_mode("hold")
	elif event.is_action_pressed("quick_save"):
		GameManager.save_game()
	elif event.is_action_pressed("quick_load"):
		GameManager.load_game()


func _handle_movement() -> void:
	if not _has_move_target:
		velocity = Vector2.ZERO
		move_and_slide()
		return

	var to_target := _move_target - global_position
	if to_target.length() <= move_arrival_distance:
		_has_move_target = false
		velocity = Vector2.ZERO
	else:
		var next_position := _get_path_next_position(_move_target)
		var to_next := next_position - global_position
		velocity = to_next.normalized() * stats.get_move_speed()
	move_and_slide()


func _handle_right_click(click_position: Vector2) -> void:
	var clicked_enemy := GameManager.get_nearest_enemy(click_position, click_enemy_radius)
	if clicked_enemy != null:
		_clear_cast_target()
		_command_skeleton_attack(clicked_enemy)
		return

	_clear_cast_target()
	GameManager.clear_attack_command()
	_move_target = click_position
	_has_move_target = true
	var feedback: Node = _get_interaction_feedback()
	if feedback != null:
		feedback.show_move_marker(click_position)


func _command_skeleton_attack(enemy: Node2D) -> void:
	_has_move_target = false
	GameManager.set_skeleton_command_mode("attack")
	GameManager.command_attack_target(enemy)
	if enemy.has_method("force_aggro"):
		enemy.force_aggro(self)
	var feedback: Node = _get_interaction_feedback()
	if feedback != null:
		feedback.show_attack_command(global_position, enemy)


func _cast_ranged_attack(click_position: Vector2) -> void:
	var enemy := _get_cast_target(click_position)
	if enemy == null:
		var feedback: Node = _get_interaction_feedback()
		if feedback != null:
			feedback.show_cast_blocked(click_position, "NO TARGET")
		GameManager.log_combat("Cast blocked: no target")
		return

	_set_cast_target(enemy)
	if global_position.distance_to(enemy.global_position) > cast_range:
		GameManager.log_combat("Moving into cast range: %s" % enemy.name)
		var feedback: Node = _get_interaction_feedback()
		if feedback != null:
			feedback.show_range_preview(global_position, cast_range)
		return
	if not _can_cast():
		GameManager.log_combat("Cast blocked: cooldown %.1fs" % _get_cast_time_remaining())
		var feedback: Node = _get_interaction_feedback()
		if feedback != null:
			feedback.show_cast_blocked(global_position, "COOLDOWN")
		return
	_try_fire_cast()


func _update_pending_cast() -> void:
	if _cast_target == null or not is_instance_valid(_cast_target):
		_clear_cast_target()
		return

	var target_health := GameManager.get_health_component(_cast_target)
	if target_health == null or target_health.is_dead:
		_clear_cast_target()
		return

	var distance := global_position.distance_to(_cast_target.global_position)
	if distance > cast_range:
		_move_toward_cast_range(_cast_target)
		return

	_has_move_target = false
	velocity = Vector2.ZERO
	_try_fire_cast()


func _set_cast_target(enemy: Node2D) -> void:
	_cast_target = enemy
	GameManager.select_enemy(enemy)
	var feedback: Node = _get_interaction_feedback()
	if feedback != null:
		feedback.show_range_preview(global_position, cast_range)
	GameManager.log_combat("Cast target selected: %s" % enemy.name)


func _clear_cast_target() -> void:
	_cast_target = null


func _move_toward_cast_range(enemy: Node2D) -> void:
	var away_from_enemy := global_position - enemy.global_position
	var direction := away_from_enemy.normalized() if away_from_enemy.length_squared() > 0.0 else Vector2.RIGHT
	_move_target = enemy.global_position + (direction * minf(cast_standoff_distance, cast_range - 8.0))
	_has_move_target = true


func _try_fire_cast() -> void:
	if _cast_target == null or not is_instance_valid(_cast_target):
		return

	if not _can_cast():
		return

	if global_position.distance_to(_cast_target.global_position) > cast_range:
		return

	var enemy := _cast_target
	var enemy_health := GameManager.get_health_component(enemy)
	if enemy_health == null:
		return

	var damage := _get_cast_damage()
	_start_cast_cooldown()
	GameManager.log_combat("%s casts at %s for %s" % [name, enemy.name, _format_amount(damage)])
	var unit_feedback := get_node_or_null("UnitFeedback") as UnitFeedback
	var body := get_node_or_null("Body")
	if body != null and body.has_method("face_toward"):
		body.call("face_toward", enemy.global_position)
	if unit_feedback != null:
		unit_feedback.play_attack_animation()
	var feedback: Node = _get_interaction_feedback()
	if feedback != null:
		feedback.show_cast_marker(global_position, enemy)
	var projectile: Node = CombatProjectileScript.new()
	projectile.name = "CombatProjectile"
	get_tree().current_scene.add_child(projectile)
	projectile.launch(global_position, enemy, damage, self, Color(0.6, 0.35, 1.0, 1.0))


func _get_cast_damage() -> float:
	return float(attack_damage) + stats.get_player_damage_bonus()


func _get_cast_target(click_position: Vector2) -> Node2D:
	var clicked_enemy := GameManager.get_nearest_enemy(click_position, click_enemy_radius)
	if clicked_enemy != null:
		return clicked_enemy

	var nearby_enemy := GameManager.get_nearest_enemy(global_position, close_cast_assist_range)
	if nearby_enemy != null and click_position.distance_to(nearby_enemy.global_position) <= close_cast_assist_range:
		return nearby_enemy

	return null


func _can_cast() -> bool:
	return Time.get_ticks_msec() >= _next_cast_time_msec


func _start_cast_cooldown() -> void:
	_next_cast_time_msec = Time.get_ticks_msec() + int(cast_cooldown * 1000.0)
	_cast_timer = cast_cooldown
	_update_cast_hud()


func _get_cast_time_remaining() -> float:
	var remaining_msec := maxi(_next_cast_time_msec - Time.get_ticks_msec(), 0)
	return float(remaining_msec) / 1000.0


func _update_cast_hud() -> void:
	var command_hud := _get_command_hud()
	if command_hud != null:
		command_hud.update_cast_status(_get_cast_time_remaining(), cast_cooldown)


func _get_command_hud() -> Node:
	if get_tree().current_scene == null:
		return null

	return get_tree().current_scene.get_node_or_null("UI/CommandHUD")


func _get_interaction_feedback() -> Node:
	if get_tree().current_scene == null:
		return null

	return get_tree().current_scene.get_node_or_null("InteractionFeedback")


func _get_path_next_position(destination: Vector2) -> Vector2:
	var main := get_tree().current_scene
	if main != null and main.has_method("get_path_next_position"):
		return main.get_path_next_position(global_position, destination)
	return destination


func _apply_stats() -> void:
	move_speed = stats.get_move_speed()
	health.max_health = stats.get_max_health()
	health.current_health = minf(health.current_health, float(health.max_health))
	health.health_changed.emit(health.current_health, health.max_health)


func _on_died(_source: Node) -> void:
	print("%s died" % name)
	set_physics_process(false)
	set_process_unhandled_input(false)


func _format_amount(value: float) -> String:
	if is_equal_approx(value, roundf(value)):
		return "%d" % int(roundf(value))
	return "%.1f" % value
