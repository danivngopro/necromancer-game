class_name RPGDebugUI
extends PanelContainer

const STAT_ROWS: Array[String] = ["hp", "strength", "black_mana", "mana_regen", "army_size", "movement_speed"]
const STAT_LABELS: Dictionary = {
	"hp": "HP",
	"strength": "Strength",
	"black_mana": "Dark Mana",
	"army_size": "Army Size",
	"movement_speed": "Movement Speed",
	"mana_regen": "Mana Regen"
}

var stat_buttons: Dictionary = {}
var stat_value_labels: Dictionary = {}
var _root: VBoxContainer
var _level_label: Label
var _exp_label: Label
var _points_label: Label
var _command_label: Label

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	mouse_filter = Control.MOUSE_FILTER_PASS
	custom_minimum_size = Vector2(250, 228)
	_setup_style()
	_build_rows()
	GameManager.player_stats_registered.connect(_on_player_stats_registered)
	if GameManager.player_stats != null:
		_on_player_stats_registered(GameManager.player_stats)
	_update_text()


func toggle_expanded() -> void:
	visible = true


func _build_rows() -> void:
	_root = VBoxContainer.new()
	_root.name = "Rows"
	_root.add_theme_constant_override("separation", 4)
	add_child(_root)

	_level_label = _make_label("Level: --")
	_exp_label = _make_label("EXP: --")
	_points_label = _make_label("Stat Points: --")
	_root.add_child(_level_label)
	_root.add_child(_exp_label)
	_root.add_child(_points_label)

	for stat_name in STAT_ROWS:
		var row := HBoxContainer.new()
		row.name = "%sRow" % stat_name
		row.custom_minimum_size = Vector2(230, 24)
		row.mouse_filter = Control.MOUSE_FILTER_PASS
		row.add_theme_constant_override("separation", 4)
		_root.add_child(row)

		var label := _make_label("")
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(label)
		stat_value_labels[stat_name] = label

		var button := Button.new()
		button.name = "%sPlusButton" % stat_name
		button.text = "+"
		button.tooltip_text = "Increase %s" % STAT_LABELS[stat_name]
		button.custom_minimum_size = Vector2(26, 22)
		button.size_flags_horizontal = Control.SIZE_SHRINK_END
		button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		button.mouse_filter = Control.MOUSE_FILTER_STOP
		button.focus_mode = Control.FOCUS_NONE
		button.process_mode = Node.PROCESS_MODE_ALWAYS
		button.add_theme_font_override("font", _make_ui_font())
		button.add_theme_font_size_override("font_size", 13)
		button.add_theme_stylebox_override("normal", _make_button_style(Color(0.02, 0.025, 0.03, 0.92)))
		button.add_theme_stylebox_override("hover", _make_button_style(Color(0.08, 0.1, 0.12, 0.98)))
		button.add_theme_stylebox_override("pressed", _make_button_style(Color(0.13, 0.16, 0.18, 1.0)))
		button.pressed.connect(_increase_stat.bind(stat_name))
		row.add_child(button)
		stat_buttons[stat_name] = button

	_command_label = _make_label("Command: --")
	_root.add_child(_command_label)


func _increase_stat(stat_name: String) -> void:
	var stats := GameManager.player_stats
	if stats == null:
		return

	stats.increase_stat(stat_name)
	_update_text()


func _on_player_stats_registered(stats: Node) -> void:
	stats.level_changed.connect(_on_stats_signal)
	stats.experience_changed.connect(_on_experience_changed)
	stats.stat_points_changed.connect(_on_stats_signal)
	stats.black_mana_changed.connect(_on_black_mana_changed)
	stats.stats_changed.connect(_on_stats_updated)
	if not GameManager.skeleton_cap_changed.is_connected(_on_army_changed):
		GameManager.skeleton_cap_changed.connect(_on_army_changed)
	_update_text()


func _on_stats_signal(_value: int) -> void:
	_update_text()


func _on_experience_changed(_experience: int, _experience_to_next_level: int) -> void:
	_update_text()


func _on_black_mana_changed(_current_black_mana: float, _max_black_mana: int) -> void:
	_update_text()


func _on_stats_updated() -> void:
	_update_text()


func _on_army_changed(_current_count: int, _max_count: int) -> void:
	_update_text()


func _update_text() -> void:
	var stats := GameManager.player_stats
	if stats == null:
		_level_label.text = "Level: --"
		_exp_label.text = "EXP: --"
		_points_label.text = "Stat Points: --"
		return

	_level_label.text = "Level: %d" % stats.level
	_exp_label.text = "EXP: %d/%d" % [stats.experience, stats.get_experience_to_next_level()]
	_points_label.text = "Stat Points: %d" % stats.stat_points
	(stat_value_labels["hp"] as Label).text = "HP: %d" % stats.hp
	(stat_value_labels["strength"] as Label).text = "Strength: %d (+%.1f dmg)" % [stats.strength, stats.get_player_damage_bonus()]
	(stat_value_labels["black_mana"] as Label).text = "Dark Mana: %.1f/%d" % [stats.current_black_mana, stats.black_mana]
	(stat_value_labels["mana_regen"] as Label).text = "Mana Regen: %.2f/s" % stats.get_mana_regen_rate()
	(stat_value_labels["army_size"] as Label).text = "Army Size: %d (%d/%d skeletons)" % [stats.army_size, GameManager.get_skeleton_count(), GameManager.skeleton_cap]
	(stat_value_labels["movement_speed"] as Label).text = "Movement Speed: %d" % stats.movement_speed
	_command_label.text = "Command: %s" % GameManager.skeleton_command_mode

	for button in stat_buttons.values():
		button.disabled = stats.stat_points <= 0
		button.visible = _should_show_stat_buttons()


func _should_show_stat_buttons() -> bool:
	return GameManager.player_stats != null and GameManager.player_stats.stat_points > 0


func _make_label(label_text: String) -> Label:
	var label := Label.new()
	label.text = label_text
	label.add_theme_font_override("font", _make_ui_font())
	label.add_theme_font_size_override("font_size", 14)
	label.add_theme_color_override("font_color", Color(0.96, 0.96, 0.9, 1.0))
	label.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0, 1.0))
	label.add_theme_constant_override("outline_size", 2)
	return label


func _setup_style() -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.035, 0.04, 0.045, 0.76)
	style.border_color = Color(0.28, 0.34, 0.32, 0.85)
	style.set_border_width_all(1)
	style.set_content_margin_all(8.0)
	add_theme_stylebox_override("panel", style)


func _make_ui_font() -> SystemFont:
	var font := SystemFont.new()
	font.font_names = ["Segoe UI Semibold", "Segoe UI", "Arial"]
	font.antialiasing = TextServer.FONT_ANTIALIASING_LCD
	font.subpixel_positioning = TextServer.SUBPIXEL_POSITIONING_AUTO
	return font


func _make_button_style(color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.border_color = Color(0.55, 0.6, 0.66, 0.9)
	style.set_border_width_all(1)
	style.set_content_margin_all(0.0)
	return style
