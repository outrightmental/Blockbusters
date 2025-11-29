extends Test

# Run all tests in this test scene
func run_all_tests() -> Signal:
	await _test_couch()
	await _test_table()
	return Util.delay(1.0)


#
func _test_couch() -> Signal:
	_begin("Spawn several banners in sequence at center screen in couch mode")
	var viewport_size: Vector2 = get_viewport().get_visible_rect().size
	await Util.delay(1.0)
	await _spawn_banner(0, viewport_size.x / 2, viewport_size.y / 2, 0, "READY", "SET")
	await Util.delay(2.0)
	await _spawn_banner(1, viewport_size.x / 2, viewport_size.y / 2, 0, "VICTORY!")
	return Util.delay(2.0)


#
func _test_table() -> Signal:
	_begin("Spawn several dual-banners in sequence at sides of screen in table mode")
	var viewport_size: Vector2 = get_viewport().get_visible_rect().size
	await _spawn_banner(2, viewport_size.x * 0.25, viewport_size.y / 2, -90, "VICTORY!")
	await _spawn_banner(2, viewport_size.x * 0.75, viewport_size.y / 2, 90, "VICTORY!")
	return Util.delay(2.0)


# Spawn a banner at the given position
func _spawn_banner(player_num: int, x: float, y: float, _rot_deg: float, message: String, message_2: String = "") -> Signal:
	var banner: Node = ScenePreloader.banner_scene.instantiate()
	banner.position = Vector2(x, y)
	banner.rotation_degrees = _rot_deg
	banner.player_num = player_num
	banner.message = message
	banner.message_2 = message_2
	self.add_child(banner)
	return Util.delay(0.1)
	