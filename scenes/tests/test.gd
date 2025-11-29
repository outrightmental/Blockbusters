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
		_fail(message)


# Assert that a condition is false, otherwise record a failure message
func assert_false(condition: bool, message: String) -> void:
	if condition:
		_fail(message)


# Assert that two values are equal, otherwise record a failure message		
func assert_eq(actual, expected, message: String) -> void:
	if actual != expected:
		_fail("Expected %s to be %s, but found %s" % [message, str(expected), str(actual)])


# Assert that two values are approximately equal within a tolerance, otherwise record a failure message	
func assert_near(actual: float, expected: float, tolerance: float, message: String) -> void:
	if abs(actual - expected) > tolerance:
		_fail("Expected %s to be near %f (+/-%f), but found %f." % [message, expected, tolerance, actual])


# Assert that a value is greater than or equal to an expected value, otherwise record a failure message
func assert_ge(actual: float, expected: float, message: String) -> void:
	if actual < expected:
		_fail("Expected at least %f (%s), but found only %f." % [expected, message, actual])


# Assert that a value is less than or equal to an expected value, otherwise record a failure message
func assert_le(actual: float, expected: float, message: String) -> void:
	if actual > expected:
		_fail("Expected at most %f (%s), but found %f." % [expected, message, actual])


# Record a failure message
func _fail(message: String) -> void:
	print_debug(message)
	failures.append(message)