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


# Assert that a condition is false, otherwise record a failure message
func assert_false(condition: bool, message: String) -> void:
	if condition:
		failures.append(message)


# Assert that two values are equal, otherwise record a failure message		
func assert_eq(actual, expected, message: String) -> void:
	if actual != expected:
		failures.append("Expected %s to be %s, but found %s" % [message, str(expected), str(actual)])


# Assert that a value is greater than or equal to an expected value, otherwise record a failure message
func assert_ge(actual: float, expected: float, message: String) -> void:
	if actual < expected:
		failures.append("Expected at least %f (%s), but found only %f." % [expected, message, actual])