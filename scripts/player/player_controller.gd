class_name PlayerController
extends CharacterBody2D

const CombatProjectileScript: Script = preload("res://scripts/visuals/combat_projectile.gd")

@export var move_speed: float = 180.0
@export var attack_damage: int = 3
@export var cast_range: float = 260.0
@export var cast_cooldown: float = 2.0
@export var click_enemy_radius: float = 18.0
@export var move_arrival_distance: float = 8.0

@onready var health: HealthComponent = $HealthComponent
@onready var resurrection_controller: ResurrectionController = $ResurrectionController
@onready var stats: Node = $PlayerStats

var _cast_timer: float = 0.0
var _move_target: Vector2
var _has_move_target: bool = false

func _ready() -> void:
	GameManager.register_player(self)
	health.died.connect(_on_died)
	stats.stats_changed.connect(_apply_stats)
	_apply_stats()


func _physics_process(delta: float) -> void:
	_cast_timer = maxf(_cast_timer - delta, 0.0)
	_handle_movement()


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
		velocity = to_target.normalized() * stats.get_move_speed()
	move_and_slide()


func _handle_right_click(click_position: Vector2) -> void:
	var clicked_enemy := GameManager.get_nearest_enemy(click_position, click_enemy_radius)
	if clicked_enemy != null:
		_command_skeleton_attack(clicked_enemy)
		return

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
	if _cast_timer > 0.0:
		return

	var enemy := GameManager.get_nearest_enemy(click_position, click_enemy_radius)
	if enemy == null:
		return

	if global_position.distance_to(enemy.global_position) > cast_range:
		print("Target out of range")
		return

	var enemy_health := GameManager.get_health_component(enemy)
	if enemy_health == null:
		return

	var damage: int = attack_damage + stats.get_skeleton_damage_bonus()
	print("%s casts at %s for %d" % [name, enemy.name, damage])
	_cast_timer = cast_cooldown
	enemy_health.apply_damage(damage, self)
	var feedback: Node = _get_interaction_feedback()
	if feedback != null:
		feedback.show_cast_marker(global_position, enemy)
	var projectile: Node = CombatProjectileScript.new()
	get_tree().current_scene.add_child(projectile)
	projectile.launch(global_position, enemy, 0, self, Color(0.6, 0.35, 1.0, 1.0))


func _get_interaction_feedback() -> Node:
	if get_tree().current_scene == null:
		return null

	return get_tree().current_scene.get_node_or_null("InteractionFeedback")


func _apply_stats() -> void:
	move_speed = stats.get_move_speed()
	health.max_health = stats.get_max_health()
	health.current_health = mini(health.current_health, health.max_health)
	health.health_changed.emit(health.current_health, health.max_health)


func _on_died(_source: Node) -> void:
	print("%s died" % name)
	set_physics_process(false)
	set_process_unhandled_input(false)
