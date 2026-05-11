class_name UnitFeedback
extends Node2D

@export var body_path: NodePath = NodePath("../Body")
@export var health_path: NodePath = NodePath("../HealthComponent")
@export var player_stats_path: NodePath = NodePath("../PlayerStats")
@export var health_bar_path: NodePath = NodePath("HealthBar")
@export var hp_label_path: NodePath = NodePath("HpLabel")
@export var name_label_path: NodePath = NodePath("NameLabel")
@export var mana_bar_path: NodePath = NodePath("ManaBar")
@export var mana_label_path: NodePath = NodePath("ManaLabel")
@export var animation_frame_count: int = 3
@export var idle_frame_seconds: float = 0.36
@export var action_frame_seconds: float = 0.18
@export var popup_offset: Vector2 = Vector2(-12, -30)
@export var knockback_distance: float = 10.0
@export var hit_flash_seconds: float = 0.08

@onready var body: CanvasItem = get_node_or_null(body_path) as CanvasItem
@onready var health: HealthComponent = get_node_or_null(health_path) as HealthComponent
@onready var player_stats: PlayerStats = get_node_or_null(player_stats_path) as PlayerStats
@onready var health_bar: ProgressBar = get_node_or_null(health_bar_path) as ProgressBar
@onready var hp_label: Label = get_node_or_null(hp_label_path) as Label
@onready var name_label: Label = get_node_or_null(name_label_path) as Label
@onready var mana_bar: ProgressBar = get_node_or_null(mana_bar_path) as ProgressBar
@onready var mana_label: Label = get_node_or_null(mana_label_path) as Label

var _base_modulate: Color = Color.WHITE
var _sprite_body: Sprite2D
var _frame_size: Vector2 = Vector2.ZERO
var _animation_timer: float = 0.0
var _action_timer: float = 0.0
var _action_frame: int = -1

func _ready() -> void:
	if body != null:
		_base_modulate = body.modulate
		_sprite_body = body as Sprite2D
		_setup_frame_sheet()

	set_process(_sprite_body != null)

	_apply_label_quality(hp_label, 10)
	_apply_label_quality(mana_label, 10)
	_apply_label_quality(name_label, 10)

	if health == null:
		return

	health.health_changed.connect(_on_health_changed)
	health.damaged.connect(_on_damaged)
	health.died.connect(_on_died)
	_on_health_changed(health.current_health, health.max_health)

	if player_stats != null:
		player_stats.black_mana_changed.connect(_on_black_mana_changed)
		_on_black_mana_changed(player_stats.current_black_mana, player_stats.black_mana)


func set_name_text(label_text: String) -> void:
	if name_label == null:
		name_label = get_node_or_null(name_label_path) as Label
	if name_label != null:
		name_label.text = label_text
		_apply_label_quality(name_label, 10)


func play_attack_animation() -> void:
	_play_action_frame(2)


func _process(delta: float) -> void:
	if _sprite_body == null or _frame_size == Vector2.ZERO:
		return

	if _action_timer > 0.0:
		_action_timer = maxf(_action_timer - delta, 0.0)
		_set_animation_frame(_action_frame)
		return

	_animation_timer += delta
	var idle_frame := int(floor(_animation_timer / idle_frame_seconds)) % 2
	_set_animation_frame(idle_frame)


func _on_health_changed(current_health: int, max_health: int) -> void:
	if health_bar != null:
		health_bar.max_value = max_health
		health_bar.value = current_health

	if hp_label != null:
		hp_label.text = "%d/%d" % [current_health, max_health]


func _on_black_mana_changed(current_black_mana: float, max_black_mana: int) -> void:
	if mana_bar != null:
		mana_bar.max_value = max_black_mana
		mana_bar.value = current_black_mana

	if mana_label != null:
		mana_label.text = "%.1f/%d" % [current_black_mana, max_black_mana]


func _on_damaged(amount: int, source: Node) -> void:
	print("%s took %d damage from %s" % [_unit_name(), amount, _source_name(source)])
	_spawn_damage_popup(amount)
	_hit_flash()
	_play_action_frame(1)
	_apply_knockback(source)


func _on_died(source: Node) -> void:
	print("%s died after damage from %s" % [_unit_name(), _source_name(source)])


func _spawn_damage_popup(amount: int) -> void:
	var popup := Label.new()
	popup.name = "DamagePopup"
	popup.text = "-%d" % amount
	popup.position = popup_offset
	popup.z_index = 50
	popup.add_theme_color_override("font_color", Color(1.0, 0.2, 0.08, 1.0))
	popup.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0, 1.0))
	popup.add_theme_constant_override("outline_size", 2)
	popup.add_theme_font_override("font", _make_ui_font())
	popup.add_theme_font_size_override("font_size", 12)
	add_child(popup)

	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(popup, "position", popup_offset + Vector2(0, -18), 0.45)
	tween.tween_property(popup, "modulate:a", 0.0, 0.45)
	tween.set_parallel(false)
	tween.tween_callback(popup.queue_free)


func _hit_flash() -> void:
	if body == null:
		return

	body.modulate = Color(1.0, 0.25, 0.18, 1.0)
	var tween := create_tween()
	tween.tween_property(body, "modulate", _base_modulate, hit_flash_seconds)


func _play_action_frame(frame_index: int) -> void:
	_action_frame = clampi(frame_index, 0, animation_frame_count - 1)
	_action_timer = action_frame_seconds
	_set_animation_frame(_action_frame)


func _setup_frame_sheet() -> void:
	if _sprite_body == null or _sprite_body.texture == null:
		return

	var texture_size := _sprite_body.texture.get_size()
	if animation_frame_count <= 1 or texture_size.x <= 0.0:
		return

	_frame_size = Vector2(texture_size.x / float(animation_frame_count), texture_size.y)
	_sprite_body.region_enabled = true
	_set_animation_frame(0)


func _set_animation_frame(frame_index: int) -> void:
	if _sprite_body == null or _frame_size == Vector2.ZERO:
		return

	var frame := clampi(frame_index, 0, animation_frame_count - 1)
	_sprite_body.region_rect = Rect2(Vector2(_frame_size.x * float(frame), 0.0), _frame_size)


func _apply_knockback(source: Node) -> void:
	var target_node := _feedback_owner()
	if source == null or target_node == null or not (source is Node2D):
		return

	var source_node := source as Node2D
	var direction := target_node.global_position - source_node.global_position
	if direction.length_squared() == 0.0:
		return

	target_node.global_position += direction.normalized() * knockback_distance


func _feedback_owner() -> Node2D:
	if owner is Node2D:
		return owner as Node2D
	return get_parent() as Node2D


func _unit_name() -> String:
	var target_node := _feedback_owner()
	if target_node != null:
		return target_node.name
	return name


func _source_name(source: Node) -> String:
	if source == null:
		return "unknown"
	return source.name


func _apply_label_quality(label: Label, font_size: int) -> void:
	if label == null:
		return
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_font_override("font", _make_ui_font())
	label.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0, 1.0))
	label.add_theme_constant_override("outline_size", 2)


func _make_ui_font() -> SystemFont:
	var font := SystemFont.new()
	font.font_names = ["Segoe UI Semibold", "Segoe UI", "Arial"]
	font.antialiasing = TextServer.FONT_ANTIALIASING_LCD
	font.subpixel_positioning = TextServer.SUBPIXEL_POSITIONING_AUTO
	return font
