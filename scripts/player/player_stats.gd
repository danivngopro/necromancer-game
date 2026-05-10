class_name PlayerStats
extends Node

signal level_changed(level: int)
signal experience_changed(experience: int, experience_to_next_level: int)
signal stats_changed
signal stat_points_changed(stat_points: int)

@export var level: int = 1
@export var experience: int = 0
@export var stat_points: int = 0
@export var vitality: int = 18
@export var wisdom: int = 5
@export var command: int = 5
@export var agility: int = 180
@export var dark_arts: int = 2

func _ready() -> void:
	GameManager.register_player_stats(self)
	_emit_all()


func add_experience(amount: int) -> void:
	if amount <= 0:
		return

	experience += amount
	while experience >= get_experience_to_next_level():
		experience -= get_experience_to_next_level()
		_level_up()

	experience_changed.emit(experience, get_experience_to_next_level())


func get_experience_to_next_level() -> int:
	return 5 + ((level - 1) * 5)


func get_max_health() -> int:
	return vitality


func get_move_speed() -> float:
	return float(agility)


func get_skeleton_cap() -> int:
	return command


func get_skeleton_damage_bonus() -> int:
	return maxi(dark_arts - 2, 0)


func _level_up() -> void:
	level += 1
	stat_points += 1
	level_changed.emit(level)
	stat_points_changed.emit(stat_points)
	stats_changed.emit()
	print("Player leveled up to %d. Stat points: %d" % [level, stat_points])


func _emit_all() -> void:
	level_changed.emit(level)
	experience_changed.emit(experience, get_experience_to_next_level())
	stat_points_changed.emit(stat_points)
	stats_changed.emit()
