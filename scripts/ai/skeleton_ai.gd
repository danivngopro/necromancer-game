class_name SkeletonAI
extends CharacterBody2D

const CombatProjectileScript: Script = preload("res://scripts/visuals/combat_projectile.gd")

enum State { IDLE, CHASE, ATTACK, DEAD }

@export var move_speed: float = 135.0
@export var follow_distance: float = 54.0
@export var acquire_range: float = 180.0
@export var attack_range: float = 30.0
@export var attack_slot_radius: float = 34.0
@export var attack_damage: int = 1
@export var attack_cooldown: float = 1.15

@onready var health: HealthComponent = $HealthComponent

var state: State = State.IDLE
var target_enemy: Node2D
var hold_position: Vector2
var _attack_timer: float = 0.0

func _ready() -> void:
	GameManager.register_skeleton(self)
	health.died.connect(_on_died)
	hold_position = global_position
	GameManager.skeleton_command_changed.connect(_on_skeleton_command_changed)


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
	var commanded_target := GameManager.commanded_attack_target
	if GameManager.skeleton_command_mode == "attack" and commanded_target != null and is_instance_valid(commanded_target):
		var commanded_health := GameManager.get_health_component(commanded_target)
		if commanded_health != null and not commanded_health.is_dead:
			target_enemy = commanded_target
			return

	if GameManager.skeleton_command_mode == "hold":
		target_enemy = _get_nearest_active_enemy()
		return

	if target_enemy != null and is_instance_valid(target_enemy):
		var target_health := GameManager.get_health_component(target_enemy)
		var distance := global_position.distance_to(target_enemy.global_position)
		if target_health != null and not target_health.is_dead and distance <= acquire_range:
			return

	target_enemy = _get_nearest_active_enemy()


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
	var attack_position := GameManager.get_skeleton_attack_position(self, target_enemy, attack_slot_radius)
	var to_target := attack_position - global_position
	velocity = to_target.normalized() * move_speed
	move_and_slide()


func _follow_player() -> void:
	if GameManager.skeleton_command_mode == "hold":
		_move_to_hold_position()
		return

	var player := GameManager.player
	if player == null or not is_instance_valid(player):
		velocity = Vector2.ZERO
		move_and_slide()
		return

	var formation_position := GameManager.get_skeleton_formation_position(self, follow_distance)
	var to_formation := formation_position - global_position
	if to_formation.length() > 8.0:
		velocity = to_formation.normalized() * move_speed
	else:
		velocity = Vector2.ZERO
	move_and_slide()


func _move_to_hold_position() -> void:
	var to_hold := hold_position - global_position
	if to_hold.length() > 8.0:
		velocity = to_hold.normalized() * move_speed
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
	var feedback := get_node_or_null("UnitFeedback") as UnitFeedback
	if feedback != null:
		feedback.play_attack_animation()
	var projectile: Node = CombatProjectileScript.new()
	projectile.name = "CombatProjectile"
	get_tree().current_scene.add_child(projectile)
	projectile.launch(global_position, target_enemy, attack_damage, self, Color(0.72, 0.95, 0.66, 1.0))
	_attack_timer = attack_cooldown


func _on_skeleton_command_changed(mode: String) -> void:
	if mode == "hold":
		hold_position = global_position


func _get_nearest_active_enemy() -> Node2D:
	var nearest_enemy: Node2D
	var nearest_distance := acquire_range

	for enemy in GameManager.enemies:
		if not is_instance_valid(enemy):
			continue
		if "is_aggroed" in enemy and not enemy.is_aggroed:
			continue

		var enemy_health := GameManager.get_health_component(enemy)
		if enemy_health == null or enemy_health.is_dead:
			continue

		var distance := global_position.distance_to(enemy.global_position)
		if distance < nearest_distance:
			nearest_enemy = enemy
			nearest_distance = distance

	return nearest_enemy


func _on_died(_source: Node) -> void:
	state = State.DEAD
	print("%s died" % name)
	queue_free()
