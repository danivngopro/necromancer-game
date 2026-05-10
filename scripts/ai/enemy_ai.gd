class_name EnemyAI
extends CharacterBody2D

enum State { IDLE, CHASE, ATTACK, RETURN, DEAD }

@export var move_speed: float = 78.0
@export var contact_damage: int = 1
@export var experience_reward: int = 3
@export var enemy_level: int = 1
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
var is_aggroed: bool = false
var _attack_timer: float = 0.0

func _ready() -> void:
	spawn_position = global_position
	configure_level(enemy_level)
	GameManager.register_enemy(self)
	health.died.connect(_on_died)
	health.damaged.connect(_on_damaged)


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

	if not is_aggroed:
		target = null
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
	is_aggroed = false
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


func force_aggro(new_target: Node2D) -> void:
	if state == State.DEAD:
		return

	is_aggroed = true
	target = new_target
	state = State.CHASE


func configure_level(level: int) -> void:
	enemy_level = maxi(level, 1)
	contact_damage = enemy_level
	experience_reward = 2 + enemy_level
	attack_cooldown = maxf(0.35, 0.95 - (float(enemy_level - 1) * 0.08))
	if health != null:
		health.max_health = 6 + (enemy_level * 3)
		health.current_health = health.max_health

	var body := get_node_or_null("Body") as Polygon2D
	if body != null:
		body.color = _level_color(enemy_level)


func _level_color(level: int) -> Color:
	match level:
		1:
			return Color(0.9, 0.9, 0.85, 1.0)
		2:
			return Color(1.0, 0.86, 0.2, 1.0)
		3:
			return Color(1.0, 0.45, 0.12, 1.0)
		4:
			return Color(0.9, 0.08, 0.06, 1.0)
		_:
			return Color(0.55, 0.0, 0.85, 1.0)


func _on_damaged(_amount: int, source: Node) -> void:
	if source is Node2D:
		force_aggro(source as Node2D)


func _on_died(_source: Node) -> void:
	state = State.DEAD
	if GameManager.commanded_attack_target == self:
		GameManager.clear_attack_command()
	print("%s died; spawning corpse" % name)
	GameManager.record_enemy_kill(self, _source, experience_reward)
	GameManager.spawn_corpse(global_position, enemy_level)
	queue_free()
