class_name HealthComponent
extends Node

signal health_changed(current_health: float, max_health: int)
signal damaged(amount: float, source: Node)
signal died(source: Node)

@export var max_health: int = 10

var current_health: float = 10.0
var is_dead: bool = false

func _ready() -> void:
	current_health = float(max_health)
	health_changed.emit(current_health, max_health)


func apply_damage(amount: float, source: Node = null) -> void:
	if is_dead or amount <= 0.0:
		return

	current_health = maxf(current_health - amount, 0.0)
	damaged.emit(amount, source)
	health_changed.emit(current_health, max_health)

	if current_health <= 0.0:
		is_dead = true
		died.emit(source)


func heal(amount: float) -> void:
	if is_dead or amount <= 0.0:
		return

	current_health = minf(current_health + amount, float(max_health))
	health_changed.emit(current_health, max_health)


func reset_health() -> void:
	is_dead = false
	current_health = float(max_health)
	health_changed.emit(current_health, max_health)
