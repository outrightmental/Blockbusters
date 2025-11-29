extends Test

# Padding time to ensure state changes have taken effect
const pad_seconds: float = 0.2
# of actual laser beams (in the laser_beam_cluster) raycast from p1 to p2 simultaneously doing damage
const number_of_laser_beams: int = Constant.PLAYER_SHIP_LASER_CLUSTER_COUNT
# Time required to fully disable a ship by laser heating
const disable_ship_seconds: float = Constant.PLAYER_SHIP_HEATED_DISABLED_THRESHOLD_SEC / number_of_laser_beams + pad_seconds
# Time required to fully re-enable a disabled ship (double the disable time, it turns out) plus padding
const reenable_ship_seconds: float = Constant.PLAYER_SHIP_DISABLED_SEC * 2 + pad_seconds


# Functional test to validate laser behaviors
func run_all_tests() -> Signal:
	var viewport_size: Vector2 = get_viewport().get_visible_rect().size
	var p1: Ship               = _spawn_player_ship(1, Vector2(viewport_size.x * 0.3, viewport_size.y / 2), 0)
	var p2: Ship               = _spawn_player_ship(2, Vector2(viewport_size.x * 0.7, viewport_size.y / 2), PI)
	await Util.delay(0.1)
	await _test_fully_cooked(p1, p2)
	await _test_half_baked(p1, p2)
	await _test_grazed(p1, p2)
	return Util.delay(0)


# Player 1 fires the entire laser charge directly at Player 2 -- disabled (no heat)
func _test_fully_cooked(_p1: Ship, p2: Ship) -> Signal:
	InputManager.action_pressed.emit(1, InputManager.INPUT_ACTION_A)
	await Util.delay(disable_ship_seconds)
	InputManager.action_released.emit(1, InputManager.INPUT_ACTION_A)
	assert_true(p2.is_disabled, "Player 2 ship should be disabled after being fully cooked by Player 1 laser")
	assert_eq(p2.get_heated_ratio(), 0.0, "Player 2 has no heat after being disabled")
	await Util.delay(p2.disabled_for_sec + pad_seconds)
	assert_false(p2.is_disabled, "Player 2 ship should be re-enabled after disabled duration has passed")
	return Util.delay(0)


# Player 2 fires a partial laser charge directly at Player 1 -- heated about 50%, not disabled
func _test_half_baked(p1: Ship, _p2: Ship) -> Signal:
	InputManager.action_pressed.emit(2, InputManager.INPUT_ACTION_A)
	await Util.delay(disable_ship_seconds / 2)
	InputManager.action_released.emit(2, InputManager.INPUT_ACTION_A)
	assert_near(p1.get_heated_ratio(), 0.5, 0.05, "Player 1 heated ratio after a 50% laser hit from Player 2")
	assert_false(p1.is_disabled, "Player 1 ship should not be disabled")
	var passed_seconds: float   = 0.0
	var cooldown_seconds: float = p1.heat + pad_seconds
	while p1.get_heated_ratio() > 0.0:
		# print("Player 1 cooldown, current heat ratio %f after %f seconds" % [p1.get_heated_ratio(), passed_seconds])
		await Util.delay(pad_seconds / 2)
		passed_seconds += pad_seconds / 2
	assert_le(passed_seconds, cooldown_seconds, "Player 1 should have fully cooled down within the re-enable duration")
	return Util.delay(0)


# Player 1 fires a small laser charge directly at Player 2 followed by a pause -- no heat
func _test_grazed(_p1: Ship, p2: Ship) -> Signal:
	InputManager.action_pressed.emit(1, InputManager.INPUT_ACTION_A)
	await Util.delay(disable_ship_seconds / 5)
	InputManager.action_released.emit(1, InputManager.INPUT_ACTION_A)
	assert_near(p2.get_heated_ratio(), 0.2, 0.02, "Player 2 heated ratio after a 20% laser hit from Player 1")
	assert_false(p2.is_disabled, "Player 2 ship should not be disabled")
	var cooldown_seconds: float = p2.heat + pad_seconds
	await Util.delay(cooldown_seconds)
	assert_eq(p2.get_heated_ratio(), 0.0, "Player 2 heated ratio after re-enabling from disabled state")
	return Util.delay(0)


# Spawn a player ship at the given position and rotation
func _spawn_player_ship(num: int, start_position: Vector2, start_rotation: float) -> Ship:
	var ship: Ship = ScenePreloader.ship_scene.instantiate()
	ship.position = start_position
	ship.player_num = num
	ship.rotation = start_rotation
	self.add_child(ship)
	return ship
