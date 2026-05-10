class_name ResurrectionController
extends Area2D

signal resurrection_requested(corpse: Corpse)
signal resurrection_completed(skeleton: Node2D)

var nearby_corpses: Array[Corpse] = []

func _ready() -> void:
	area_entered.connect(_on_area_entered)
	area_exited.connect(_on_area_exited)


func request_resurrection() -> void:
	var corpse := _get_nearest_corpse()
	if corpse == null:
		return

	resurrection_requested.emit(corpse)
	var skeleton := corpse.resurrect()
	if skeleton != null:
		resurrection_completed.emit(skeleton)


func _get_nearest_corpse() -> Corpse:
	var nearest: Corpse
	var nearest_distance := INF

	for corpse in nearby_corpses:
		if not is_instance_valid(corpse) or corpse.is_consumed:
			continue

		var distance := global_position.distance_to(corpse.global_position)
		if distance < nearest_distance:
			nearest = corpse
			nearest_distance = distance

	return nearest


func _on_area_entered(area: Area2D) -> void:
	if area is Corpse and area not in nearby_corpses:
		nearby_corpses.append(area)


func _on_area_exited(area: Area2D) -> void:
	if area is Corpse:
		nearby_corpses.erase(area)
