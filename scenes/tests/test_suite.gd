class_name TestSuite
extends Node

const banner_test: PackedScene    = preload('res://scenes/tests/banner_test.tscn')
const explosion_test: PackedScene = preload('res://scenes/tests/explosion_test.tscn')


# Run all tests in this test suite
func _ready() -> void:
	await _run_test_scene(banner_test)
	await _run_test_scene(explosion_test)
	get_tree().quit()
	pass


# Run a test scene
func _run_test_scene(test_scene: PackedScene) -> Signal:
	var test_instance: Node = test_scene.instantiate()
	add_child(test_instance)
	assert(test_instance.has_method("run_all_tests"))
	await test_instance.run_all_tests()
	test_instance.queue_free()
	return Util.delay(0.1)
	
