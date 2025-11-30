extends Test

# Padding time to ensure banner animation plays out before proceeding
const after_all_delay_sec: float = 1.0

# Run all tests in this test scene
func run_all_tests() -> Signal:
	await _test_couch()
	await _test_table()
	return Util.callback()


#
func _test_couch() -> Signal:
	_begin("Spawn several banners in sequence at center screen in couch mode")
	Game.mode = Game.Mode.COUCH
	# 
	await Game.do_show_banner(0, "READY", "SET")
	await Util.delay(after_all_delay_sec)
	#
	await Game.do_show_banner(1, "VICTORY!", "")
	await Util.delay(after_all_delay_sec)
	#
	return Util.callback()


#
func _test_table() -> Signal:
	_begin("Spawn several dual-banners in sequence at sides of screen in table mode")
	Game.mode = Game.Mode.TABLE
	#
	await Game.do_show_banner(2, "VICTORY!", "")
	await Util.delay(after_all_delay_sec)
	#
	return Util.callback()


func _before_banner() -> Signal:
	Game._do_time_slow()
	return Util.callback()


func _after_banner() -> Signal:
	await Util.delay(Constant.BANNER_SHOW_SEC * Constant.TIME_SLOW_SCALE)
	Game._do_time_norm()
	await Util.delay(Constant.TIME_TWEEN_NORM_DURATION)
	return Util.callback()
