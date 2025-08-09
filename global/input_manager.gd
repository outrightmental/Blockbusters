extends Node

# Signals
signal input_mode_updated
# Enum for input modes
enum Mode {
	TABLE,
	COUCH,
}
# Keep track of the input mode
@onready var mode: Mode = Mode.TABLE


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	Input.joy_connection_changed.connect(_on_joy_connection_changed)


# Detect the input mode based on the current input devices, see #126
func _on_joy_connection_changed(_device: int, _connected: bool) -> void:
	if Input.get_connected_joypads().size() >= 2:
		print ("[GAME] Activating dual gamepad input mode")
		mode = Mode.COUCH
	else:
		print ("[GAME] Activating single gamepad input mode")
		mode = Mode.TABLE
	input_mode_updated.emit()


