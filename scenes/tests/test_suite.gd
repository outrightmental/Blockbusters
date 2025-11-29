class_name TestSuite
extends Node

# ---------------------------
# Store preloaded test scenes
#
# ----------------------------------------------------------------
# FOR TEST-DRIVEN DEVELOPMENT, disable tests that are not being worked on currently
# and make sure add a "to do" (remove the space between those two words) comment to bring them back later.
# ----------------------------------------------------------------
#
const tests: Array[PackedScene] = [
								  # todo:   preload('res://scenes/tests/gameplay/player_ship_laser_damage_test.tscn'),
								  preload('res://scenes/tests/gameplay/player_ship_explosion_damage_test.tscn'),
								  # todo:   preload('res://scenes/tests/gameplay/explosion_test.tscn'),
								  # todo:   preload('res://scenes/tests/hud/banner_test.tscn'),
								  ]
#
# Count the failures that occur during testing
var total_failures: int = false


# Run all tests in this test suite
func _ready() -> void:
	for test_scene in tests:
		await _run_test_scene(test_scene)
	await Util.delay(0.5) # Wait a moment to ensure all output is printed
	if total_failures > 0:
		print("%d TEST%s FAILED" % [total_failures, "S" if total_failures > 1 else ""])
		get_tree().quit(1) # Exit with failure code
	else:
		print("ALL TESTS PASSED")
		get_tree().quit(0) # Exit with success code
	pass


# Run a test scene
func _run_test_scene(test_scene: PackedScene) -> Signal:
	var name_parts: PackedStringArray = test_scene.get_path().split("/")
	var scene_name: String            = name_parts[name_parts.size() - 1].replace(".tscn", "")
	var test_instance: Node           = test_scene.instantiate()
	add_child(test_instance)
	#
	if test_instance.has_method("run_all_tests"):
		print("\n\n---[%s]--- will run all tests" % scene_name)
		await test_instance.run_all_tests()
		if test_instance.failures > 0:
			total_failures += test_instance.failures
			print("---[%s]--- HAD %d FAILURE%s" % [scene_name, test_instance.failures, "S" if test_instance.failures > 1 else ""])
		else:
			print("---[%s]--- completed OK" % scene_name)
	else:
		print("---[%s]--- ERROR: %s" % [str(test_scene), "does not have a run_all_tests() method."])
		total_failures += 1
		test_instance.queue_free()
	#
	test_instance.queue_free()
	print("\n\n")
	return Util.delay(0.1)
	
