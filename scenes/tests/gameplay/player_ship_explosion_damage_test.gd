extends Test

# [FOR DEVELOPMENT ONLY] run this test immediately and loop
func _ready() -> void:
	# await run_all_tests()
	# await Util.delay(3.0)
	# _goto_scene("res://scenes/tests/gameplay/player_ship_explosion_damage_test.tscn")
	pass


# Run all tests in this test scene
func run_all_tests() -> Signal:
	var viewport_size: Vector2 = get_viewport().get_visible_rect().size
	_spawn_player_ship(1, Vector2(viewport_size.x * 0.3, viewport_size.y / 2), 0)
	var p2: Ship = _spawn_player_ship(2, Vector2(viewport_size.x * 0.7, viewport_size.y / 2), PI)
	await Util.delay(0.1)
	Game.player_did_collect_item.emit(1, Game.InventoryItemType.PROJECTILE)
	await Util.delay(0.1)
	InputManager.action_pressed.emit(1, InputManager.INPUT_ACTION_B)
	await Util.delay(2.0)
	if not p2.is_disabled:
		failures.append("Player 2 ship should be disabled after being hit by Player 1 projectile.")
	return Util.delay(0)


# Spawn a player ship at the given position and rotation
func _spawn_player_ship(num: int, start_position: Vector2, start_rotation: float) -> Ship:
	var ship: Ship = ScenePreloader.ship_scene.instantiate()
	ship.position = start_position
	ship.player_num = num
	ship.rotation = start_rotation
	self.add_child(ship)
	return ship
