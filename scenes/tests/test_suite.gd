class_name TestSuite
extends Node

# Store preloaded test scenes
const banner_test: PackedScene    = preload('res://scenes/tests/banner_test.tscn')
const explosion_test: PackedScene = preload('res://scenes/tests/explosion_test.tscn')
# Store any failures that occur during testing
var failures: Array[String] = []


# Run all tests in this test suite
func _ready() -> void:
	await _run_test_scene(banner_test)
	await _run_test_scene(explosion_test)
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
	assert(test_instance.has_method("run_all_tests"))
	await test_instance.run_all_tests()
	if test_instance.failures.size() > 0:
		for failure in test_instance.failures:
			failures.append(failure)
	test_instance.queue_free()
	return Util.delay(0.1)
	
