class_name EnemyAI
extends CharacterBody2D

enum State { IDLE, CHASE, ATTACK, RETURN, DEAD }

@export var move_speed: float = 78.0
@export var contact_damage: int = 1
@export var experience_reward: int = 3
@export var detection_range: float = 130.0
@export var attack_range: float = 28.0
@export var attack_cooldown: float = 0.85
@export var leash_distance: float = 220.0
@export var return_arrival_distance: float = 8.0
@export var patrol_radius: float = 24.0

@onready var health: HealthComponent = $HealthComponent

var state: State = State.IDLE
var target: Node2D
var spawn_position: Vector2
var _attack_timer: float = 0.0

func _ready() -> void:
	spawn_position = global_position
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
		State.RETURN:
			_return_to_spawn()


func _update_target() -> void:
	if state == State.RETURN:
		return

	if target != null and is_instance_valid(target):
		var target_health := GameManager.get_health_component(target)
		var distance := global_position.distance_to(target.global_position)
		var leash := global_position.distance_to(spawn_position)
		if leash > leash_distance:
			_disengage()
			return
		if target_health != null and not target_health.is_dead and distance <= detection_range:
			return

	target = GameManager.get_nearest_hostile_target(global_position, detection_range)


func _update_state() -> void:
	if target == null:
		state = State.IDLE
		return

	if global_position.distance_to(spawn_position) > leash_distance:
		_disengage()
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

	print("%s attacks %s for %d" % [name, target.name, contact_damage])
	target_health.apply_damage(contact_damage, self)
	_attack_timer = attack_cooldown


func _disengage() -> void:
	print("%s leash exceeded; returning to spawn" % name)
	target = null
	state = State.RETURN


func _return_to_spawn() -> void:
	var to_spawn := spawn_position - global_position
	if to_spawn.length() <= return_arrival_distance:
		global_position = spawn_position
		velocity = Vector2.ZERO
		_restore_after_leash()
		state = State.IDLE
		move_and_slide()
		return

	velocity = to_spawn.normalized() * move_speed
	move_and_slide()


func _restore_after_leash() -> void:
	health.heal(health.max_health)
	print("%s returned to spawn and restored HP" % name)


func _on_died(_source: Node) -> void:
	state = State.DEAD
	print("%s died; spawning corpse" % name)
	GameManager.record_enemy_kill(self, _source, experience_reward)
	GameManager.spawn_corpse(global_position)
	queue_free()
