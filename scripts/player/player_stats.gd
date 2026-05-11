class_name PlayerStats
extends Node

signal level_changed(level: int)
signal experience_changed(experience: int, experience_to_next_level: int)
signal stats_changed
signal stat_points_changed(stat_points: int)
signal black_mana_changed(current_black_mana: float, max_black_mana: int)

@export var level: int = 1
@export var experience: int = 0
@export var stat_points: int = 0
@export var hp: int = 4
@export var black_mana: int = 1
@export var current_black_mana: float = 1.0
@export var army_size: int = 1
@export var movement_speed: int = 80
@export var mana_regen: int = 0
@export var base_mana_regen_per_second: float = 0.1

func _ready() -> void:
	GameManager.register_player_stats(self)
	_emit_all()
	GameManager.log_combat("Mana regen: +%.2f/sec" % get_mana_regen_rate())


func _process(delta: float) -> void:
	restore_black_mana(get_mana_regen_rate() * delta)


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
	return hp


func get_move_speed() -> float:
	return float(movement_speed)


func get_skeleton_cap() -> int:
	return army_size


func get_skeleton_health_bonus() -> int:
	return maxi(black_mana - 1, 0) * 2


func get_skeleton_damage_bonus() -> int:
	return maxi(black_mana - 1, 0)


func get_skeleton_attack_speed_bonus() -> float:
	return float(maxi(black_mana - 1, 0)) * 0.05


func get_mana_regen_rate() -> float:
	return base_mana_regen_per_second + (float(mana_regen) * 0.01)


func spend_black_mana(amount: int) -> bool:
	if amount <= 0:
		return true
	if current_black_mana < amount:
		return false

	current_black_mana -= amount
	black_mana_changed.emit(current_black_mana, black_mana)
	return true


func restore_black_mana(amount: float) -> void:
	if amount <= 0.0:
		return

	var next_black_mana := minf(current_black_mana + amount, float(black_mana))
	if is_equal_approx(next_black_mana, current_black_mana):
		return

	current_black_mana = next_black_mana
	black_mana_changed.emit(current_black_mana, black_mana)


func increase_stat(stat_name: String) -> bool:
	if stat_points <= 0:
		return false

	match stat_name:
		"hp":
			hp += 2
		"black_mana":
			black_mana += 1
			current_black_mana = black_mana
			black_mana_changed.emit(current_black_mana, black_mana)
		"army_size":
			army_size += 1
		"movement_speed":
			movement_speed += 10
		"mana_regen":
			mana_regen += 1
		_:
			return false

	stat_points -= 1
	stat_points_changed.emit(stat_points)
	stats_changed.emit()
	if stat_name == "mana_regen":
		GameManager.log_combat("Mana regen: +%.2f/sec" % get_mana_regen_rate())
	print("Increased %s. Remaining stat points: %d" % [stat_name, stat_points])
	return true


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
	black_mana_changed.emit(current_black_mana, black_mana)
	stats_changed.emit()
