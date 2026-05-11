class_name TargetFrame
extends VBoxContainer

var title_label: Label
var health_label: Label
var health_bar: ProgressBar
var current_target: Node2D

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	title_label = _add_label("No Target", 14)
	health_label = _add_label("--/--", 12)
	health_bar = ProgressBar.new()
	health_bar.custom_minimum_size = Vector2(190, 12)
	health_bar.show_percentage = false
	add_child(health_bar)
	GameManager.enemy_selection_changed.connect(_on_enemy_selection_changed)
	_on_enemy_selection_changed(GameManager.selected_enemy)


func _process(_delta: float) -> void:
	_refresh()


func _add_label(text: String, font_size: int) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_override("font", _make_ui_font())
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_constant_override("outline_size", 2)
	label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	add_child(label)
	return label


func _make_ui_font() -> SystemFont:
	var font := SystemFont.new()
	font.font_names = ["Segoe UI Semibold", "Segoe UI", "Arial"]
	font.antialiasing = TextServer.FONT_ANTIALIASING_LCD
	font.subpixel_positioning = TextServer.SUBPIXEL_POSITIONING_AUTO
	return font


func _on_enemy_selection_changed(enemy: Node2D) -> void:
	current_target = enemy
	_refresh()


func _refresh() -> void:
	if current_target == null or not is_instance_valid(current_target):
		title_label.text = "No Target"
		health_label.text = "--/--"
		health_bar.value = 0
		return

	var health := GameManager.get_health_component(current_target)
	var level: int = int(current_target.enemy_level) if "enemy_level" in current_target else 1
	title_label.text = "Lv %d %s" % [level, current_target.name]
	if health != null:
		health_label.text = "%s/%d HP" % [_format_amount(health.current_health), health.max_health]
		health_bar.max_value = health.max_health
		health_bar.value = health.current_health


func _format_amount(value: float) -> String:
	if is_equal_approx(value, roundf(value)):
		return "%d" % int(roundf(value))
	return "%.1f" % value
