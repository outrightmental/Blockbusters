extends Node2D

# Preloaded Scenes
const block_scene: PackedScene     = preload('res://models/block/block.tscn')
const explosion_scene: PackedScene = preload('res://models/explosive/explosion.tscn')
# Signal that never happens, in case the tree is unloaded
signal never


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	_create_board()
	await _delay(1.0)
	# Spawn an explosion at the center of the board
	var viewport_size: Vector2 = get_viewport().get_visible_rect().size
	var explosion: Node        = explosion_scene.instantiate()
	explosion.position = Vector2(viewport_size.x / 2, viewport_size.y / 2)
	explosion.player_num = 1
	self.add_child(explosion)
	await _delay(5.0)
	_goto_scene("res://scenes/explosion_test.tscn")
	pass


# Create the test board
func _create_board() -> void:
	for x in range(Config.BOARD_GRID_COLS):
		for y in range(Config.BOARD_GRID_ROWS):
			_spawn_block(_grid_position(x, y))


# Delay, guarding against the condition that the tree has been unloaded since the calling thread arrived here
func _delay(seconds: float) -> Signal:
	if get_tree():
		return get_tree().create_timer(seconds).timeout
	else:
		return never


func _grid_position(x: int, y: int) -> Vector2:
	# Convert grid coordinates to world coordinates
	return Vector2( Config.BOARD_GRID_MARGIN * Config.BOARD_BLOCK_SIZE + Config.BOARD_BLOCK_CENTER + x * Config.BOARD_BLOCK_SIZE, Config.BOARD_GRID_MARGIN * Config.BOARD_BLOCK_SIZE +Config.BOARD_BLOCK_CENTER + y * Config.BOARD_BLOCK_SIZE)


func _spawn_block(start_position: Vector2) -> Node:
	var block: Block = block_scene.instantiate()
	block.position = start_position
	self.add_child(block)
	return block


# Goto a scene, guarding against the condition that the tree has been unloaded since the calling thread arrived here
func _goto_scene(path: String) -> void:
	if get_tree():
		get_tree().change_scene_to_file(path)

		
