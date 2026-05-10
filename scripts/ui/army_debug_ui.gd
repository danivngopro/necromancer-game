class_name ArmyDebugUI
extends Label

func _ready() -> void:
	GameManager.skeleton_registered.connect(_refresh)
	GameManager.skeleton_unregistered.connect(_refresh)
	GameManager.skeleton_cap_changed.connect(_refresh_count)
	GameManager.essence_changed.connect(_refresh_essence)
	GameManager.progression_reward_applied.connect(_on_progression_reward)
	_refresh()


func _refresh(_unit: Node2D = null) -> void:
	_update_text()


func _refresh_count(_current_count: int, _max_count: int) -> void:
	_update_text()


func _refresh_essence(_essence: int) -> void:
	_update_text()


func _on_progression_reward(message: String) -> void:
	print("Progression reward: %s" % message)
	_update_text()


func _update_text() -> void:
	text = "Skeletons: %d/%d\nEssence: %d" % [
		GameManager.get_skeleton_count(),
		GameManager.skeleton_cap,
		GameManager.essence
	]
