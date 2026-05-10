class_name SkeletonAI
extends CharacterBody2D

enum State { IDLE, CHASE, ATTACK, DEAD }

@export var move_speed: float = 135.0
@export var follow_distance: float = 54.0
@export var acquire_range: float = 180.0
@export var attack_range: float = 30.0
@export var attack_damage: int = 2
@export var attack_cooldown: float = 0.55

@onready var health: HealthComponent = $HealthComponent

var state: State = State.IDLE
var target_enemy: Node2D
var _attack_timer: float = 0.0

func _ready() -> void:
	GameManager.register_skeleton(self)
	health.died.connect(_on_died)


func _exit_tree() -> void:
	GameManager.unregister_skeleton(self)


func _physics_process(delta: float) -> void:
	if state == State.DEAD:
		return

	_attack_timer = maxf(_attack_timer - delta, 0.0)
	_update_target()
	_update_state()

	match state:
		State.IDLE:
			_follow_player()
		State.CHASE:
			_chase_target()
		State.ATTACK:
			_attack_target()


func _update_target() -> void:
	if target_enemy != null and is_instance_valid(target_enemy):
		var target_health := GameManager.get_health_component(target_enemy)
		var distance := global_position.distance_to(target_enemy.global_position)
		if target_health != null and not target_health.is_dead and distance <= acquire_range:
			return

	target_enemy = GameManager.get_nearest_enemy(global_position, acquire_range)


func _update_state() -> void:
	if target_enemy == null:
		state = State.IDLE
		return

	var distance := global_position.distance_to(target_enemy.global_position)
	if distance <= attack_range:
		state = State.ATTACK
	else:
		state = State.CHASE


func _chase_target() -> void:
	var to_target := target_enemy.global_position - global_position
	velocity = to_target.normalized() * move_speed
	move_and_slide()


func _follow_player() -> void:
	var player := GameManager.player
	if player == null or not is_instance_valid(player):
		velocity = Vector2.ZERO
		move_and_slide()
		return

	var to_player := player.global_position - global_position
	if to_player.length() > follow_distance:
		velocity = to_player.normalized() * move_speed
	else:
		velocity = Vector2.ZERO
	move_and_slide()


func _attack_target() -> void:
	velocity = Vector2.ZERO
	move_and_slide()

	if _attack_timer > 0.0 or target_enemy == null:
		return

	var enemy_health := GameManager.get_health_component(target_enemy)
	if enemy_health == null:
		target_enemy = null
		return

	print("%s attacks %s for %d" % [name, target_enemy.name, attack_damage])
	enemy_health.apply_damage(attack_damage, self)
	_attack_timer = attack_cooldown


func _on_died(_source: Node) -> void:
	state = State.DEAD
	print("%s died" % name)
	queue_free()
