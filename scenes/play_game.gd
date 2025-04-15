extends Node2D

# Instantiate a models/ships/ship.gd for each player, so set player_num = 1 or 2 respectively, and Player 1 is 10% in from the left, vertical center, and Player 2 is 10% in from the right, vertical center.
func _ready() -> void:
	var viewport_size: Vector2 = get_viewport().get_visible_rect().size
	_spawn_player(1, Vector2(viewport_size.x * 0.1, viewport_size.y * 0.5), 0)
	_spawn_player(2, Vector2(viewport_size.x * 0.9, viewport_size.y * 0.5), PI)
	pass


func _spawn_player(num: int, start_position: Vector2, start_rotation: float) -> void:
	var ship_scene: Node = preload('res://models/ships/ship.tscn').instantiate()
	ship_scene.position = start_position
	ship_scene.player_num = num
	ship_scene.rotation = start_rotation
	self.add_child(ship_scene)
	
