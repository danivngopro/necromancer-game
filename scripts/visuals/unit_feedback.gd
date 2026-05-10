class_name UnitFeedback
extends Node2D

@export var body_path: NodePath = NodePath("../Body")
@export var health_path: NodePath = NodePath("../HealthComponent")
@export var health_bar_path: NodePath = NodePath("HealthBar")
@export var hp_label_path: NodePath = NodePath("HpLabel")
@export var popup_offset: Vector2 = Vector2(-12, -30)
@export var knockback_distance: float = 10.0
@export var hit_flash_seconds: float = 0.08

@onready var body: CanvasItem = get_node_or_null(body_path) as CanvasItem
@onready var health: HealthComponent = get_node_or_null(health_path) as HealthComponent
@onready var health_bar: ProgressBar = get_node_or_null(health_bar_path) as ProgressBar
@onready var hp_label: Label = get_node_or_null(hp_label_path) as Label

var _base_modulate: Color = Color.WHITE

func _ready() -> void:
	if body != null:
		_base_modulate = body.modulate

	if health == null:
		return

	health.health_changed.connect(_on_health_changed)
	health.damaged.connect(_on_damaged)
	health.died.connect(_on_died)
	_on_health_changed(health.current_health, health.max_health)


func _on_health_changed(current_health: int, max_health: int) -> void:
	if health_bar != null:
		health_bar.max_value = max_health
		health_bar.value = current_health

	if hp_label != null:
		hp_label.text = "%d/%d" % [current_health, max_health]


func _on_damaged(amount: int, source: Node) -> void:
	print("%s took %d damage from %s" % [_unit_name(), amount, _source_name(source)])
	_spawn_damage_popup(amount)
	_hit_flash()
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
