extends Test

# Padding time to ensure state changes have taken effect
const pad_seconds: float = 0.2
# of actual laser beams (in the laser_beam_cluster) raycast from p1 to p2 simultaneously doing damage
const number_of_laser_beams: int = Constant.PLAYER_SHIP_LASER_CLUSTER_COUNT
# Time required to fully disable a ship by laser heating
const disable_ship_seconds: float = Constant.PLAYER_SHIP_HEATED_DISABLED_THRESHOLD_SEC / number_of_laser_beams + pad_seconds
# Time required to fully re-enable a disabled ship (double the disable time, it turns out) plus padding
const reenable_ship_seconds: float = Constant.PLAYER_SHIP_DISABLED_SEC * 2 + pad_seconds
# Offset for a "danger close" near miss
const danger_close_offset: Vector2 = Vector2(0, -Constant.EXPLOSION_RADIUS_HEATED * 0.3)
# Offset for a "half baked" miss
const half_baked_offset: Vector2 = Vector2(0, Constant.EXPLOSION_RADIUS_HEATED * 0.5)


# Run all tests in this test scene
func run_all_tests() -> Signal:
	var viewport_size: Vector2 = get_viewport().get_visible_rect().size
	var p1: Ship               = _spawn_player_ship(1, Vector2(viewport_size.x * 0.1, viewport_size.y / 2), 0)
	var p2: Ship               = _spawn_player_ship(2, Vector2(viewport_size.x * 0.5, viewport_size.y / 2), PI)
	await Util.delay(0.1)
	await _test_fully_cooked(p1, p2)
	await _test_danger_close(p1, p2)
	await _test_half_baked(p1, p2)
	return Util.delay(0)


# Player 1 fires an explosive projectile directly at Player 2 -- disabled (no heat)
func _test_fully_cooked(_p1: Ship, p2: Ship) -> Signal:
	await Util.delay(pad_seconds)
	Game.player_did_collect_item.emit(1, Game.InventoryItemType.PROJECTILE)
	await Util.delay(pad_seconds)
	InputManager.action_pressed.emit(1, InputManager.INPUT_ACTION_B)
	await Util.delay(pad_seconds)
	InputManager.action_released.emit(1, InputManager.INPUT_ACTION_B)
	await Util.delay(2.0)
	assert_true(p2.is_disabled, "Player 2 ship should be disabled after a direct hit from Player 1 projectile.")
	assert_eq(p2.get_heated_ratio(), 0.0, "Player 2 has no heat after being disabled")
	await Util.delay(p2.disabled_for_sec + pad_seconds)
	assert_false(p2.is_disabled, "Player 2 ship should be re-enabled after disabled duration has passed")
	return Util.delay(0)


# Player 2 fires an explosive projectile near Player 1 -- disabled (no heat)
func _test_danger_close(p1: Ship, p2: Ship) -> Signal:
	await Util.delay(pad_seconds)
	Game.player_did_collect_item.emit(2, Game.InventoryItemType.PROJECTILE)
	await Util.delay(pad_seconds)
	var target: Vector2 = p1.position + danger_close_offset # aim slightly to the side for a near miss
	p2.aim_at_position(target)
	await Util.delay(pad_seconds)
	InputManager.action_pressed.emit(2, InputManager.INPUT_ACTION_B)
	await Util.delay(pad_seconds)
	InputManager.action_released.emit(2, InputManager.INPUT_ACTION_B)
	await Util.delay(2.0)
	assert_true(p1.is_disabled, "Player 1 ship should be disabled after a near miss from Player 2 projectile.")
	assert_eq(p1.get_heated_ratio(), 0.0, "Player 1 has no heat after being disabled")
	await Util.delay(p1.disabled_for_sec + pad_seconds)
	assert_false(p1.is_disabled, "Player 1 ship should be re-enabled after disabled duration has passed")
	return Util.delay(0)


# Player 2 fires an explosive projectile farther from Player 1 -- heated about 50%, not disabled
func _test_half_baked(p1: Ship, p2: Ship) -> Signal:
	await Util.delay(pad_seconds)
	Game.player_did_collect_item.emit(2, Game.InventoryItemType.PROJECTILE)
	await Util.delay(pad_seconds)
	var target: Vector2 = p1.position + Vector2(0, 150) # aim for a half-distance miss
	p2.aim_at_position(target)
	await Util.delay(pad_seconds)
	InputManager.action_pressed.emit(2, InputManager.INPUT_ACTION_B)
	await Util.delay(pad_seconds)
	InputManager.action_released.emit(2, InputManager.INPUT_ACTION_B)
	await Util.delay(2.0)
	assert_near(p1.get_heated_ratio(), 0.5, 0.1, "Player 1 heated ratio after a 50% explosion hit from Player 2")
	assert_false(p1.is_disabled, "Player 1 ship should not be disabled")
	var passed_seconds: float   = 0.0
	var cooldown_seconds: float = p1.heat + pad_seconds
	while p1.get_heated_ratio() > 0.0:
		# print("Player 1 cooldown, current heat ratio %f after %f seconds" % [p1.get_heated_ratio(), passed_seconds])
		await Util.delay(pad_seconds / 2)
		passed_seconds += pad_seconds / 2
	assert_le(passed_seconds, cooldown_seconds, "Player 1 should have fully cooled down within the re-enable duration")
	return Util.delay(0)


# Spawn a player ship at the given position and rotation
func _spawn_player_ship(num: int, start_position: Vector2, start_rotation: float) -> Ship:
	var ship: Ship = ScenePreloader.ship_scene.instantiate()
	ship.position = start_position
	ship.player_num = num
	ship.rotation = start_rotation
	self.add_child(ship)
	return ship
