class_name RPGDebugUI
extends Label

func _ready() -> void:
	GameManager.player_stats_registered.connect(_on_player_stats_registered)
	if GameManager.player_stats != null:
		_on_player_stats_registered(GameManager.player_stats)
	_update_text()


func _on_player_stats_registered(stats: Node) -> void:
	stats.level_changed.connect(_on_level_changed)
	stats.experience_changed.connect(_on_experience_changed)
	stats.stat_points_changed.connect(_on_stat_points_changed)
	stats.stats_changed.connect(_on_stats_updated)
	if not GameManager.skeleton_cap_changed.is_connected(_on_army_changed):
		GameManager.skeleton_cap_changed.connect(_on_army_changed)
	_update_text()


func _on_level_changed(_level: int) -> void:
	_update_text()


func _on_experience_changed(_experience: int, _experience_to_next_level: int) -> void:
	_update_text()


func _on_stat_points_changed(_stat_points: int) -> void:
	_update_text()


func _on_stats_updated() -> void:
	_update_text()


func _on_army_changed(_current_count: int, _max_count: int) -> void:
	_update_text()


func _update_text() -> void:
	var stats := GameManager.player_stats
	if stats == null:
		text = "Level: --\nEXP: --\nStat Points: --"
		return

	text = "Level: %d\nEXP: %d/%d\nStat Points: %d\nVitality: %d\nWisdom: %d\nCommand: %d (%d/%d skeletons)\nAgility: %d\nDark Arts: %d" % [
		stats.level,
		stats.experience,
		stats.get_experience_to_next_level(),
		stats.stat_points,
		stats.vitality,
		stats.wisdom,
		stats.command,
		GameManager.get_skeleton_count(),
		GameManager.skeleton_cap,
		stats.agility,
		stats.dark_arts
	]
