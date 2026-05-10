class_name Corpse
extends Area2D

signal resurrected(corpse: Corpse, skeleton: Node2D)
signal expired(corpse: Corpse)

@export var skeleton_spawn_offset: Vector2 = Vector2(0, -12)
@export var lifetime_seconds: float = 12.0

@onready var body: CanvasItem = $Body
@onready var highlight: CanvasItem = get_node_or_null("Highlight") as CanvasItem
@onready var popup_anchor: Node2D = get_node_or_null("RevivePopupAnchor") as Node2D
@onready var revive_sound: AudioStreamPlayer2D = get_node_or_null("ReviveSoundPlaceholder") as AudioStreamPlayer2D

var is_consumed: bool = false
var _base_body_color: Color = Color.WHITE

func _ready() -> void:
	_base_body_color = body.modulate
	set_highlighted(false)
	GameManager.register_corpse(self)
	print("Corpse ready at %s" % global_position)
	if lifetime_seconds > 0.0:
		get_tree().create_timer(lifetime_seconds).timeout.connect(_expire)


func _exit_tree() -> void:
	GameManager.unregister_corpse(self)


func resurrect() -> Node2D:
	if is_consumed:
		return null

	if not GameManager.can_spawn_skeleton():
		print("Cannot resurrect: skeleton cap reached")
		show_revive_feedback("CAP FULL", Color(1.0, 0.45, 0.1, 1.0))
		return null

	is_consumed = true
	print("Resurrecting corpse at %s" % global_position)
	show_revive_feedback("+SKELETON", Color(0.55, 1.0, 0.75, 1.0))
	var skeleton := GameManager.spawn_skeleton(global_position + skeleton_spawn_offset)
	resurrected.emit(self, skeleton)
	queue_free()
	return skeleton


func set_highlighted(is_highlighted: bool) -> void:
	if highlight != null:
		highlight.visible = is_highlighted

	if body != null:
		body.modulate = Color(0.75, 1.0, 0.55, 1.0) if is_highlighted else _base_body_color


func show_revive_feedback(text: String, color: Color = Color(0.55, 1.0, 0.75, 1.0)) -> void:
	print("Revive feedback: %s" % text)
	print("SFX placeholder: revive")
	if revive_sound != null and revive_sound.stream != null:
		revive_sound.play()

	if body != null:
		body.modulate = color

	var popup := Label.new()
	popup.name = "RevivePopup"
	popup.text = text
	popup.z_index = 60
	popup.add_theme_color_override("font_color", color)
	popup.add_theme_font_size_override("font_size", 11)

	var parent := get_tree().current_scene if get_tree().current_scene != null else self
	parent.add_child(popup)
	var local_offset := Vector2(-24, -24)
	if parent is Node2D:
		popup.global_position = global_position + local_offset
	else:
		popup.position = local_offset

	var tween := popup.create_tween()
	tween.set_parallel(true)
	tween.tween_property(popup, "position", popup.position + Vector2(0, -18), 0.55)
	tween.tween_property(popup, "modulate:a", 0.0, 0.55)
	tween.set_parallel(false)
	tween.tween_callback(popup.queue_free)


func _expire() -> void:
	if is_consumed or not is_inside_tree():
		return

	print("Corpse expired at %s" % global_position)
	expired.emit(self)
	queue_free()
