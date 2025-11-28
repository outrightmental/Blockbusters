class_name Test
extends Node

# Store any failures that occur during testing
var failures: Array[String] = []


# Run all tests in this test scene
# Return a signal that completes when all tests are done.
func run_all_tests() -> Signal:
	return Util.delay(0)


# Goto a scene, guarding against the condition that the tree has been unloaded since the calling thread arrived here
func _goto_scene(path: String) -> void:
	if get_tree():
		get_tree().change_scene_to_file(path)
