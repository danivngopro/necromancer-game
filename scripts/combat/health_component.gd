class_name HealthComponent
extends Node

signal health_changed(current_health: int, max_health: int)
signal damaged(amount: int, source: Node)
signal died(source: Node)

@export var max_health: int = 10

var current_health: int = 10
var is_dead: bool = false

func _ready() -> void:
	current_health = max_health
	health_changed.emit(current_health, max_health)


func apply_damage(amount: int, source: Node = null) -> void:
	if is_dead or amount <= 0:
		return

	current_health = maxi(current_health - amount, 0)
	damaged.emit(amount, source)
	health_changed.emit(current_health, max_health)

	if current_health == 0:
		is_dead = true
		died.emit(source)


func heal(amount: int) -> void:
	if is_dead or amount <= 0:
		return

	current_health = mini(current_health + amount, max_health)
	health_changed.emit(current_health, max_health)


func reset_health() -> void:
	is_dead = false
	current_health = max_health
	health_changed.emit(current_health, max_health)
