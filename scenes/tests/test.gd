class_name Test
extends Node

# Run all tests in this test scene
# Return a signal that completes when all tests are done.
func run_all_tests() -> Signal:
	return Util.delay(0)