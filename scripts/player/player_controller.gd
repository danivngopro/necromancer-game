class_name PlayerController
extends CharacterBody2D

@export var move_speed: float = 180.0
@export var attack_damage: int = 3
@export var attack_range: float = 44.0
@export var attack_cooldown: float = 0.35
@export var click_enemy_radius: float = 18.0
@export var move_arrival_distance: float = 8.0

@onready var health: HealthComponent = $HealthComponent
@onready var resurrection_controller: ResurrectionController = $ResurrectionController
@onready var stats: Node = $PlayerStats

var _attack_timer: float = 0.0
var _move_target: Vector2
var _has_move_target: bool = false
var _attack_target: Node2D

func _ready() -> void:
	GameManager.register_player(self)
	health.died.connect(_on_died)
	stats.stats_changed.connect(_apply_stats)
	_apply_stats()


func _physics_process(delta: float) -> void:
	_attack_timer = maxf(_attack_timer - delta, 0.0)
	_handle_movement()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_RIGHT:
		_handle_right_click(get_global_mouse_position())
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
	if _attack_target != null and is_instance_valid(_attack_target):
		_move_target = _attack_target.global_position
		if global_position.distance_to(_attack_target.global_position) <= attack_range:
			velocity = Vector2.ZERO
			move_and_slide()
			_attack_commanded_enemy()
			return

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
		_attack_target = clicked_enemy
		_move_target = clicked_enemy.global_position
		_has_move_target = true
		GameManager.set_skeleton_command_mode("attack")
		GameManager.command_attack_target(clicked_enemy)
		if clicked_enemy.has_method("force_aggro"):
			clicked_enemy.force_aggro(self)
		return

	_attack_target = null
	GameManager.clear_attack_command()
	_move_target = click_position
	_has_move_target = true


func _attack_commanded_enemy() -> void:
	if _attack_timer > 0.0:
		return

	var enemy := _attack_target
	if enemy == null:
		return

	var enemy_health := GameManager.get_health_component(enemy)
	if enemy_health == null:
		return

	var damage: int = attack_damage + stats.get_skeleton_damage_bonus()
	print("%s attacks %s for %d" % [name, enemy.name, damage])
	enemy_health.apply_damage(damage, self)
	_attack_timer = attack_cooldown


func _apply_stats() -> void:
	move_speed = stats.get_move_speed()
	health.max_health = stats.get_max_health()
	health.current_health = mini(health.current_health, health.max_health)
	health.health_changed.emit(health.current_health, health.max_health)


func _on_died(_source: Node) -> void:
	print("%s died" % name)
	set_physics_process(false)
	set_process_unhandled_input(false)
