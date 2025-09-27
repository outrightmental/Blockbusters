extends Node2D

const banner_scene: PackedScene = preload('res://models/hud/hud_banner.tscn')

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var viewport_size: Vector2 = get_viewport().get_visible_rect().size
	await Util.delay(1.0)
	await _spawn_banner(0, viewport_size.x / 2, viewport_size.y / 2, 0, "READY", "SET")
	await Util.delay(5.0)
	await _spawn_banner(1, viewport_size.x / 2, viewport_size.y / 2, 0, "VICTORY!")
	await Util.delay(5.0)
	await _spawn_banner(2, viewport_size.x * 0.25, viewport_size.y / 2, -90, "VICTORY!")
	await _spawn_banner(2, viewport_size.x * 0.75, viewport_size.y / 2, 90, "VICTORY!")
	await Util.delay(5.0)
	_goto_scene("res://scenes/banner_test.tscn")
	pass

# Spawn a banner at the given position
func _spawn_banner(player_num: int, x: float, y:float, rotation_degrees:float, message:String, message_2: String = "") -> Signal:
	var banner: Node        = banner_scene.instantiate()
	banner.position = Vector2(x,y)
	banner.rotation_degrees = rotation_degrees
	banner.player_num = player_num
	banner.message = message
	banner.message_2 = message_2
	self.add_child(banner)
	return Util.delay(0)
	
# Goto a scene, guarding against the condition that the tree has been unloaded since the calling thread arrived here
func _goto_scene(path: String) -> void:
	if get_tree():
		get_tree().change_scene_to_file(path)
