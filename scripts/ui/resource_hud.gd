class_name ResourceHUD
extends VBoxContainer

var hp_label: Label
var mana_label: Label
var hp_bar: ProgressBar
var mana_bar: ProgressBar
var regen_label: Label

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_add_title("Necromancer")
	hp_label = _add_label("HP --/--")
	hp_bar = _add_bar(Color(0.85, 0.12, 0.1, 1.0))
	mana_label = _add_label("Dark Mana --/--")
	mana_bar = _add_bar(Color(0.22, 0.45, 1.0, 1.0))
	regen_label = _add_label("Regen --/s")
	GameManager.player_registered.connect(_on_player_registered)
	GameManager.player_stats_registered.connect(_on_player_stats_registered)
	if GameManager.player != null:
		_on_player_registered(GameManager.player)
	if GameManager.player_stats != null:
		_on_player_stats_registered(GameManager.player_stats)


func _add_title(text: String) -> void:
	var label := _add_label(text)
	label.add_theme_font_size_override("font_size", 15)


func _add_label(text: String) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_override("font", _make_ui_font())
	label.add_theme_font_size_override("font_size", 12)
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


func _add_bar(fill_color: Color) -> ProgressBar:
	var bar := ProgressBar.new()
	bar.custom_minimum_size = Vector2(190, 12)
	bar.show_percentage = false
	var fill := StyleBoxFlat.new()
	fill.bg_color = fill_color
	var background := StyleBoxFlat.new()
	background.bg_color = Color(0.03, 0.035, 0.04, 0.85)
	bar.add_theme_stylebox_override("fill", fill)
	bar.add_theme_stylebox_override("background", background)
	add_child(bar)
	return bar


func _on_player_registered(player: Node2D) -> void:
	var health := GameManager.get_health_component(player)
	if health != null:
		health.health_changed.connect(_on_health_changed)
		_on_health_changed(health.current_health, health.max_health)


func _on_player_stats_registered(stats: Node) -> void:
	stats.black_mana_changed.connect(_on_black_mana_changed)
	stats.stats_changed.connect(_on_stats_changed.bind(stats))
	_on_black_mana_changed(stats.current_black_mana, stats.black_mana)
	_on_stats_changed(stats)


func _on_health_changed(current_health: int, max_health: int) -> void:
	hp_label.text = "HP %d/%d" % [current_health, max_health]
	hp_bar.max_value = max_health
	hp_bar.value = current_health


func _on_black_mana_changed(current_black_mana: float, max_black_mana: int) -> void:
	mana_label.text = "Dark Mana %.1f/%d" % [current_black_mana, max_black_mana]
	mana_bar.max_value = max_black_mana
	mana_bar.value = current_black_mana


func _on_stats_changed(stats: Node) -> void:
	regen_label.text = "Regen +%.2f/s" % stats.get_mana_regen_rate()
