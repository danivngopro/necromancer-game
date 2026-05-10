class_name EnemyAI
extends CharacterBody2D

enum State { IDLE, CHASE, ATTACK, DEAD }

@export var move_speed: float = 95.0
@export var contact_damage: int = 1
@export var detection_range: float = 260.0
@export var attack_range: float = 28.0
@export var attack_cooldown: float = 0.65

@onready var health: HealthComponent = $HealthComponent

var state: State = State.IDLE
var target: Node2D
var _attack_timer: float = 0.0

func _ready() -> void:
	GameManager.register_enemy(self)
	health.died.connect(_on_died)


func _exit_tree() -> void:
	GameManager.unregister_enemy(self)


func _physics_process(delta: float) -> void:
	if state == State.DEAD:
		return

	_attack_timer = maxf(_attack_timer - delta, 0.0)
	_update_target()
	_update_state()

	match state:
		State.IDLE:
			_idle()
		State.CHASE:
			_chase_target()
		State.ATTACK:
			_attack_target()


func _update_target() -> void:
	if target != null and is_instance_valid(target):
		var target_health := GameManager.get_health_component(target)
		var distance := global_position.distance_to(target.global_position)
		if target_health != null and not target_health.is_dead and distance <= detection_range:
			return

	target = GameManager.get_nearest_hostile_target(global_position, detection_range)


func _update_state() -> void:
	if target == null:
		state = State.IDLE
		return

	var distance := global_position.distance_to(target.global_position)
	if distance <= attack_range:
		state = State.ATTACK
	else:
		state = State.CHASE


func _idle() -> void:
	velocity = Vector2.ZERO
	move_and_slide()


func _chase_target() -> void:
	var to_target := target.global_position - global_position
	velocity = to_target.normalized() * move_speed
	move_and_slide()


func _attack_target() -> void:
	velocity = Vector2.ZERO
	move_and_slide()

	if _attack_timer > 0.0:
		return

	var target_health := GameManager.get_health_component(target)
	if target_health == null:
		target = null
		return

	target_health.apply_damage(contact_damage, self)
	_attack_timer = attack_cooldown


func _on_died(_source: Node) -> void:
	state = State.DEAD
	GameManager.spawn_corpse(global_position)
	queue_free()
