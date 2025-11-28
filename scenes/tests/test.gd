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

		
# Assert that a condition is true, otherwise record a failure message
func assert_true(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
		
# Assert that a value is greater than or equal to an expected value, otherwise record a failure message
func assert_ge(actual: float, expected: float, message_prefix: String) -> void:
	if actual < expected:
		failures.append("Expected at least %f %s, but found only %f" % [message_prefix, expected, actual])