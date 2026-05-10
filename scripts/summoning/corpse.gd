class_name Corpse
extends Area2D

signal resurrected(corpse: Corpse, skeleton: Node2D)
signal expired(corpse: Corpse)

@export var skeleton_spawn_offset: Vector2 = Vector2(0, -12)
@export var lifetime_seconds: float = 12.0

var is_consumed: bool = false

func _ready() -> void:
	GameManager.register_corpse(self)
	if lifetime_seconds > 0.0:
		get_tree().create_timer(lifetime_seconds).timeout.connect(_expire)


func _exit_tree() -> void:
	GameManager.unregister_corpse(self)


func resurrect() -> Node2D:
	if is_consumed:
		return null

	is_consumed = true
	var skeleton := GameManager.spawn_skeleton(global_position + skeleton_spawn_offset)
	resurrected.emit(self, skeleton)
	queue_free()
	return skeleton


func _expire() -> void:
	if is_consumed or not is_inside_tree():
		return

	expired.emit(self)
	queue_free()
