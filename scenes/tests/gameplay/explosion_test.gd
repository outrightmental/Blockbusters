extends Test

# Run all tests in this test scene
func run_all_tests() -> Signal:
	_create_board()
	_test_explosion()
	# _test_multiple_explosions()
	return Util.delay(0)


# Test explosion behavior
func _test_explosion() -> void:
	_begin("Explosion causes blocks to break into halves and quarters")
	var viewport_size: Vector2 = get_viewport().get_visible_rect().size
	await Util.delay(1.0)
	await _spawn_explosion(viewport_size.x / 2, viewport_size.y / 2)
	await Util.delay(2.0)
	assert_block_halves_at_least(50)
	assert_block_quarts_at_least(50)
	await _spawn_explosion(viewport_size.x / 2, viewport_size.y / 2)
	await Util.delay(2.0)
	assert_block_quarts_at_least(100)


# Test multiple random explosions
#func _test_multiple_explosions() -> void:
#	await Util.delay(2.0)
#	await _spawn_random_explosions(5, 1)
#	await _spawn_random_explosions(25, 0.1)


# Assert that at least the given number of block halves exist in the scene
func assert_block_halves_at_least(expected_num: int) -> void:
	var actual_num: int = get_tree().get_nodes_in_group(Game.BLOCK_HALF_GROUP).size()
	assert_ge(actual_num, expected_num, "BlockHalves")


# Assert that at least the given number of block quarters exist in the scene
func assert_block_quarts_at_least(expected_num: int) -> void:
	var actual_num: int = get_tree().get_nodes_in_group(Game.BLOCK_QUART_GROUP).size()
	assert_ge(actual_num, expected_num, "BlockQuarts")


# Create the test board
func _create_board() -> void:
	for x in range(Constant.BOARD_GRID_COLS):
		for y in range(Constant.BOARD_GRID_ROWS):
			_spawn_block(_grid_position(x, y))


# Spawn a random number of explosions at random positions on the board		
#func _spawn_random_explosions(num: int, delay: float) -> Signal:
#	var viewport_size: Vector2 = get_viewport().get_visible_rect().size
#	for i in range(num):
#		var x: float = randf() * viewport_size.x
#		var y: float = randf() * viewport_size.y
#		await _spawn_explosion(x, y)
#		await Util.delay(delay)  # Delay between explosions to avoid too many at once
#	return Util.delay(0)


# Spawn an explosion at the given position
func _spawn_explosion(x: float, y: float) -> Signal:
	var explosion: Node = ScenePreloader.explosion_scene.instantiate()
	explosion.position = Vector2(x, y)
	explosion.player_num = 1
	self.add_child(explosion)
	return Util.delay(0)


func _grid_position(x: int, y: int) -> Vector2:
	# Convert grid coordinates to world coordinates
	return Vector2( Constant.BOARD_GRID_COLS_MARGIN * Constant.BOARD_BLOCK_SIZE + Constant.BOARD_BLOCK_CENTER + x * Constant.BOARD_BLOCK_SIZE, Constant.BOARD_GRID_ROWS_MARGIN * Constant.BOARD_BLOCK_SIZE +Constant.BOARD_BLOCK_CENTER + y * Constant.BOARD_BLOCK_SIZE)


func _spawn_block(start_position: Vector2) -> Node:
	var block: Block = ScenePreloader.block_scene.instantiate()
	block.position = start_position
	self.add_child(block)
	return block
	
