class_name UnitNameplateOverlay
extends Control

var entries: Dictionary = {}

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	GameManager.player_registered.connect(_register_player)
	GameManager.enemy_registered.connect(_register_enemy)
	GameManager.enemy_unregistered.connect(_unregister_unit)
	if GameManager.player != null:
		_register_player(GameManager.player)
	for enemy in GameManager.enemies:
		if is_instance_valid(enemy):
			_register_enemy(enemy)


func _process(_delta: float) -> void:
	var dead_ids: Array[int] = []
	for id in entries.keys():
		var entry: Dictionary = entries[id]
		var unit := entry["unit"] as Node2D
		if unit == null or not is_instance_valid(unit):
			dead_ids.append(id)
			continue
		_update_entry(entry)
	for id in dead_ids:
		_remove_entry(id)


func _register_player(unit: Node2D) -> void:
	_register_unit(unit, true)


func _register_enemy(unit: Node2D) -> void:
	_register_unit(unit, false)


func _register_unit(unit: Node2D, show_mana: bool) -> void:
	if unit == null or not is_instance_valid(unit):
		return
	var id := unit.get_instance_id()
	if entries.has(id):
		return

	var root := VBoxContainer.new()
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.custom_minimum_size = Vector2(86, 34)
	root.add_theme_constant_override("separation", 1)
	add_child(root)

	var name_label := _make_label("")
	root.add_child(name_label)
	var hp_bar := _make_bar(Color(0.82, 0.12, 0.1, 1.0), Vector2(72, 7))
	root.add_child(hp_bar)
	var hp_label := _make_label("")
	root.add_child(hp_label)
	var mana_bar: ProgressBar = null
	var mana_label: Label = null
	if show_mana:
		mana_bar = _make_bar(Color(0.22, 0.45, 1.0, 1.0), Vector2(72, 6))
		root.add_child(mana_bar)
		mana_label = _make_label("")
		root.add_child(mana_label)

	entries[id] = {
		"unit": unit,
		"root": root,
		"name_label": name_label,
		"hp_bar": hp_bar,
		"hp_label": hp_label,
		"mana_bar": mana_bar,
		"mana_label": mana_label,
		"show_mana": show_mana
	}

	var feedback := unit.get_node_or_null("UnitFeedback") as UnitFeedback
	if feedback != null:
		feedback.set_world_resource_labels_visible(false)
	_update_entry(entries[id])


func _unregister_unit(unit: Node2D) -> void:
	if unit == null:
		return
	_remove_entry(unit.get_instance_id())


func _remove_entry(id: int) -> void:
	if not entries.has(id):
		return
	var root := entries[id]["root"] as Control
	if root != null:
		root.queue_free()
	entries.erase(id)


func _update_entry(entry: Dictionary) -> void:
	var unit := entry["unit"] as Node2D
	var root := entry["root"] as Control
	if unit == null or root == null:
		return

	var screen_position := get_viewport().get_canvas_transform() * unit.global_position
	root.position = screen_position + Vector2(-43.0, -64.0)

	var health := GameManager.get_health_component(unit)
	if health != null:
		var hp_bar := entry["hp_bar"] as ProgressBar
		hp_bar.max_value = health.max_health
		hp_bar.value = health.current_health
		var hp_label := entry["hp_label"] as Label
		hp_label.text = "%s/%d HP" % [_format_amount(health.current_health), health.max_health]

	var name_label := entry["name_label"] as Label
	if "enemy_level" in unit:
		name_label.text = "Lv %d %s" % [int(unit.enemy_level), unit.name]
	else:
		name_label.text = unit.name

	if bool(entry["show_mana"]) and GameManager.player_stats != null:
		var mana_bar := entry["mana_bar"] as ProgressBar
		var mana_label := entry["mana_label"] as Label
		mana_bar.max_value = GameManager.player_stats.black_mana
		mana_bar.value = GameManager.player_stats.current_black_mana
		mana_label.text = "%.1f/%d Dark" % [GameManager.player_stats.current_black_mana, GameManager.player_stats.black_mana]


func _make_label(text: String) -> Label:
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_override("font", _make_ui_font())
	label.add_theme_font_size_override("font_size", 12)
	label.add_theme_color_override("font_color", Color(0.96, 0.96, 0.9, 1.0))
	label.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0, 1.0))
	label.add_theme_constant_override("outline_size", 2)
	return label


func _make_bar(fill_color: Color, min_size: Vector2) -> ProgressBar:
	var bar := ProgressBar.new()
	bar.custom_minimum_size = min_size
	bar.show_percentage = false
	var fill := StyleBoxFlat.new()
	fill.bg_color = fill_color
	var background := StyleBoxFlat.new()
	background.bg_color = Color(0.03, 0.035, 0.04, 0.85)
	bar.add_theme_stylebox_override("fill", fill)
	bar.add_theme_stylebox_override("background", background)
	return bar


func _make_ui_font() -> SystemFont:
	var font := SystemFont.new()
	font.font_names = ["Segoe UI Semibold", "Segoe UI", "Arial"]
	font.antialiasing = TextServer.FONT_ANTIALIASING_LCD
	font.subpixel_positioning = TextServer.SUBPIXEL_POSITIONING_AUTO
	return font


func _format_amount(value: float) -> String:
	if is_equal_approx(value, roundf(value)):
		return "%d" % int(roundf(value))
	return "%.1f" % value
