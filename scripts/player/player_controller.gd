class_name PlayerController
extends CharacterBody2D

@export var move_speed: float = 180.0
@export var attack_damage: int = 3
@export var attack_range: float = 44.0
@export var attack_cooldown: float = 0.35

@onready var health: HealthComponent = $HealthComponent
@onready var resurrection_controller: ResurrectionController = $ResurrectionController

var _attack_timer: float = 0.0

func _ready() -> void:
	GameManager.register_player(self)
	health.died.connect(_on_died)


func _physics_process(delta: float) -> void:
	_attack_timer = maxf(_attack_timer - delta, 0.0)
	_handle_movement()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("attack"):
		_attack_nearest_enemy()
	elif event.is_action_pressed("resurrect"):
		resurrection_controller.request_resurrection()


func _handle_movement() -> void:
	var input_vector := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	velocity = input_vector * move_speed
	move_and_slide()


func _attack_nearest_enemy() -> void:
	if _attack_timer > 0.0:
		return

	var enemy := GameManager.get_nearest_enemy(global_position, attack_range)
	if enemy == null:
		return

	var enemy_health := GameManager.get_health_component(enemy)
	if enemy_health == null:
		return

	print("%s attacks %s for %d" % [name, enemy.name, attack_damage])
	enemy_health.apply_damage(attack_damage, self)
	_attack_timer = attack_cooldown


func _on_died(_source: Node) -> void:
	print("%s died" % name)
	set_physics_process(false)
	set_process_unhandled_input(false)
