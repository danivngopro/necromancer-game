class_name RPGDebugUI
extends Label

const STAT_ROWS: Array[String] = ["hp", "black_mana", "army_size", "movement_speed"]
const STAT_LABELS: Dictionary = {
	"hp": "HP",
	"black_mana": "Black Mana",
	"army_size": "Army Size",
	"movement_speed": "Movement Speed"
}

var is_expanded: bool = false
var stat_buttons: Dictionary = {}

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	mouse_filter = Control.MOUSE_FILTER_STOP
	GameManager.player_stats_registered.connect(_on_player_stats_registered)
	if GameManager.player_stats != null:
		_on_player_stats_registered(GameManager.player_stats)
	_create_stat_buttons()
	_set_expanded(false)
	_update_text()


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		toggle_expanded()
		accept_event()


func toggle_expanded() -> void:
	_set_expanded(not is_expanded)


func _set_expanded(value: bool) -> void:
	is_expanded = value
	get_tree().paused = is_expanded
	size = Vector2(330, 210) if is_expanded else Vector2(260, 150)
	for button in stat_buttons.values():
		button.visible = is_expanded
	_update_text()


func _create_stat_buttons() -> void:
	for index in STAT_ROWS.size():
		var stat_name := STAT_ROWS[index]
		var button := Button.new()
		button.text = "+"
		button.tooltip_text = "Increase %s" % STAT_LABELS[stat_name]
		button.position = Vector2(220, 76 + (index * 18))
		button.size = Vector2(24, 18)
		button.process_mode = Node.PROCESS_MODE_ALWAYS
		button.pressed.connect(_increase_stat.bind(stat_name))
		add_child(button)
		stat_buttons[stat_name] = button


func _increase_stat(stat_name: String) -> void:
	var stats := GameManager.player_stats
	if stats == null:
		return

	stats.increase_stat(stat_name)
	_update_text()


func _on_player_stats_registered(stats: Node) -> void:
	stats.level_changed.connect(_on_level_changed)
	stats.experience_changed.connect(_on_experience_changed)
	stats.stat_points_changed.connect(_on_stat_points_changed)
	stats.black_mana_changed.connect(_on_black_mana_changed)
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


func _on_black_mana_changed(_current_black_mana: int, _max_black_mana: int) -> void:
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

	var hint := "\n\nLeft click to close and resume combat." if is_expanded else "\n\nLeft click to allocate stat points."
	text = "Level: %d\nEXP: %d/%d\nStat Points: %d\nHP: %d\nBlack Mana: %d/%d\nArmy Size: %d (%d/%d skeletons)\nMovement Speed: %d\nCommand: %s%s" % [
		stats.level,
		stats.experience,
		stats.get_experience_to_next_level(),
		stats.stat_points,
		stats.hp,
		stats.current_black_mana,
		stats.black_mana,
		stats.army_size,
		GameManager.get_skeleton_count(),
		GameManager.skeleton_cap,
		stats.movement_speed,
		GameManager.skeleton_command_mode,
		hint
	]

	for button in stat_buttons.values():
		button.disabled = stats.stat_points <= 0
