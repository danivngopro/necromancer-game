class_name CombatLog
extends Label

@export var max_lines: int = 7

var lines: Array[String] = []

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_theme_font_override("font", _make_ui_font())
	add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0, 1.0))
	add_theme_constant_override("outline_size", 2)
	GameManager.combat_logged.connect(_on_combat_logged)
	_on_combat_logged("Combat log ready")


func _on_combat_logged(message: String) -> void:
	lines.append(message)
	while lines.size() > max_lines:
		lines.remove_at(0)
	text = "\n".join(lines)


func _make_ui_font() -> SystemFont:
	var font := SystemFont.new()
	font.font_names = ["Segoe UI Semibold", "Segoe UI", "Arial"]
	font.antialiasing = TextServer.FONT_ANTIALIASING_LCD
	font.subpixel_positioning = TextServer.SUBPIXEL_POSITIONING_AUTO
	return font
