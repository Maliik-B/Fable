extends CanvasLayer
## Handles fade-in/fade-out transitions between scenes.
## Usage: SceneTransition.change_scene("res://scenes/map/map_scene.tscn")

const FADE_DURATION := 0.3

var _overlay: ColorRect


func _ready() -> void:
	layer = 100
	_overlay = ColorRect.new()
	_overlay.color = Color.BLACK
	_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_overlay.modulate.a = 0.0
	add_child(_overlay)
	# Fade in from black on first load
	_overlay.modulate.a = 1.0
	_fade_in()


func change_scene(path: String) -> void:
	_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	var tween = create_tween()
	tween.tween_property(_overlay, "modulate:a", 1.0, FADE_DURATION)
	tween.tween_callback(func():
		get_tree().change_scene_to_file(path)
		_fade_in()
	)


func _fade_in() -> void:
	# Wait one frame for the new scene to initialize
	await get_tree().process_frame
	await get_tree().process_frame
	var tween = create_tween()
	tween.tween_property(_overlay, "modulate:a", 0.0, FADE_DURATION)
	tween.tween_callback(func():
		_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	)
