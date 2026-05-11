class_name CommandHUD
extends HBoxContainer

var labels: Dictionary = {}

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_add_mode_label("follow", "Follow")
	_add_mode_label("hold", "Hold")
	_add_mode_label("attack", "Attack")
	GameManager.skeleton_command_changed.connect(_on_command_changed)
	_on_command_changed(GameManager.skeleton_command_mode)


func _add_mode_label(mode: String, display_text: String) -> void:
	var label := Label.new()
	label.text = display_text
	label.custom_minimum_size = Vector2(64, 22)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 12)
	add_child(label)
	labels[mode] = label


func _on_command_changed(mode: String) -> void:
	for key in labels.keys():
		var label := labels[key] as Label
		var is_active: bool = key == mode
		label.modulate = Color(1.0, 0.92, 0.45, 1.0) if is_active else Color(0.65, 0.7, 0.68, 0.82)
