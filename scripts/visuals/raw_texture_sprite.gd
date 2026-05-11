class_name RawTextureSprite
extends Sprite2D

@export var texture_path: String = ""

func _ready() -> void:
	if texture != null or texture_path.is_empty():
		return

	var image := Image.new()
	if image.load(ProjectSettings.globalize_path(texture_path)) == OK:
		texture = ImageTexture.create_from_image(image)
