class_name TestSuite
extends Node

# Store preloaded test scenes
const tests: Array[PackedScene] = [
								  preload('res://scenes/tests/hud/banner_test.tscn'),
								  preload('res://scenes/tests/gameplay/explosion_test.tscn'),
								  preload('res://scenes/tests/gameplay/player_ship_explosion_damage_test.tscn'),
								  ]
# Store any failures that occur during testing
var failures: Array[String] = []


# Run all tests in this test suite
func _ready() -> void:
	for test_scene in tests:
		print("\n\nRUNNING TEST: " + test_scene.get_name())
		await _run_test_scene(test_scene)
	if failures.size() > 0:
		print("TEST SUITE HAD FAILURES:")
		for failure in failures:
			print("- " + failure)
		get_tree().quit(1) # Exit with failure code
	else:
		print("ALL TESTS COMPLETED OK")
		get_tree().quit(0) # Exit with success code
	pass


# Run a test scene
func _run_test_scene(test_scene: PackedScene) -> Signal:
	var test_instance: Node = test_scene.instantiate()
	add_child(test_instance)
	if not test_instance.has_method("run_all_tests"):
		failures.append("Test scene " + str(test_scene) + " does not have a run_all_tests() method.")
		test_instance.queue_free()
		return Util.delay(0.1)
	await test_instance.run_all_tests()
	if test_instance.failures.size() > 0:
		for failure in test_instance.failures:
			failures.append(failure)
	test_instance.queue_free()
	return Util.delay(0.1)
	
