class_name CommandHUD
extends HBoxContainer

var labels: Dictionary = {}
var cast_label: Label

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_add_mode_label("follow", "Follow")
	_add_mode_label("hold", "Hold")
	_add_mode_label("attack", "Attack")
	cast_label = Label.new()
	cast_label.text = "Cast Ready"
	cast_label.custom_minimum_size = Vector2(92, 22)
	cast_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cast_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	cast_label.add_theme_font_override("font", _make_ui_font())
	cast_label.add_theme_font_size_override("font_size", 12)
	add_child(cast_label)
	GameManager.skeleton_command_changed.connect(_on_command_changed)
	_on_command_changed(GameManager.skeleton_command_mode)


func _add_mode_label(mode: String, display_text: String) -> void:
	var label := Label.new()
	label.text = display_text
	label.custom_minimum_size = Vector2(64, 22)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_override("font", _make_ui_font())
	label.add_theme_font_size_override("font_size", 12)
	add_child(label)
	labels[mode] = label


func _on_command_changed(mode: String) -> void:
	for key in labels.keys():
		var label := labels[key] as Label
		var is_active: bool = key == mode
		label.modulate = Color(1.0, 0.92, 0.45, 1.0) if is_active else Color(0.65, 0.7, 0.68, 0.82)


func update_cast_status(remaining_seconds: float, cooldown_seconds: float) -> void:
	if cast_label == null:
		return

	if remaining_seconds <= 0.0:
		cast_label.text = "Cast Ready"
		cast_label.modulate = Color(0.72, 0.95, 1.0, 1.0)
	else:
		cast_label.text = "Cast %.1fs" % remaining_seconds
		var ratio := clampf(remaining_seconds / maxf(cooldown_seconds, 0.01), 0.0, 1.0)
		cast_label.modulate = Color(0.8 + (0.2 * ratio), 0.55, 1.0, 0.9)


func _make_ui_font() -> SystemFont:
	var font := SystemFont.new()
	font.font_names = ["Segoe UI Semibold", "Segoe UI", "Arial"]
	font.antialiasing = TextServer.FONT_ANTIALIASING_LCD
	font.subpixel_positioning = TextServer.SUBPIXEL_POSITIONING_AUTO
	return font
