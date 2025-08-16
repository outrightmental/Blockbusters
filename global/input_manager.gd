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


# --- Lifecycle -----------------------------------------------------------

func _ready() -> void:
	# hot-plug support
	Input.joy_connection_changed.connect(_on_joy_connection_changed)


# Detect the input mode based on the current input devices, see #126
func _on_joy_connection_changed(_device: int, _connected: bool) -> void:
	var joypads: Array = Input.get_connected_joypads()
	if joypads.size() >= 2:
		print ("[GAME] Activating dual gamepad input mode")
		mode = Mode.COUCH
		joypads.sort()  # lowest id first for stability
		# Optionally: dedupe "ghost" XInput mirrors by GUID/name here.
		p1_device_id = joypads[0]
		p2_device_id = joypads[1]
	else:
		print ("[GAME] Activating single gamepad input mode")
		mode = Mode.TABLE
	input_mode_updated.emit()


signal move(player: int, dir: Vector2)                 # per-frame movement vector
signal action_pressed(player: int, action: String)     # e.g., "fire", "start"
signal action_released(player: int, action: String)
# --- Config --------------------------------------------------------------

# Deadzone for sticks
const DEADZONE := 0.25
# Names of input actions that are used in the Input Map
const INPUT_LEFT: String     = "left"
const INPUT_RIGHT: String    = "right"
const INPUT_UP: String       = "up"
const INPUT_DOWN: String     = "down"
const INPUT_ACTION_A: String = "action_a"
const INPUT_ACTION_B: String = "action_b"
const INPUT_START: String    = "start"
# Formatting template for player input
const PLAYER_INPUT_MAPPING_FORMAT: Dictionary = {
													INPUT_LEFT: "p%d_left",
													INPUT_RIGHT: "p%d_right",
													INPUT_UP: "p%d_up",
													INPUT_DOWN: "p%d_down",
													INPUT_ACTION_A: "p%d_action_a",
													INPUT_ACTION_B: "p%d_action_b",
													INPUT_START: "p%d_start",
												}
# Map joypad buttons → abstract actions (adjust to your liking)
# 0=A 1=B 2=X 3=Y 6=BACK 7=START on XInput; tweak for your target
const JOY_TO_ACTION := {
						   0: INPUT_ACTION_A,
						   1: INPUT_ACTION_B,
						   6: INPUT_START
					   }
# Keyboard action names that already exist in your Input Map
var P1_KEYS := _compute_player_input_map(1)
var P2_KEYS := _compute_player_input_map(2)
# --- State ---------------------------------------------------------------

var p1_device_id: int = -1   # -1 = no gamepad (uses keyboard)
var p2_device_id: int = -1


func _compute_player_input_map(player: int) -> Dictionary:
	var input_mapping: Dictionary = {}
	# Set up input mapping for player
	for key in PLAYER_INPUT_MAPPING_FORMAT.keys():
		var action_name: String = PLAYER_INPUT_MAPPING_FORMAT[key] % player
		if InputMap.has_action(action_name):
			input_mapping[key] = action_name
		else:
			push_error("Input action not found: ", action_name)
	return input_mapping


func _physics_process(_delta: float) -> void:
	for p in [1, 2]:
		move.emit( p, _get_dir_for_player(p))


func _input(event: InputEvent) -> void:
	match mode:
		Mode.TABLE:
			# Keyboard: only for players that DON'T have a gamepad
			if event is InputEventKey and not event.is_echo():
				_handle_keyboard_action_event(1, event, P1_KEYS)
				_handle_keyboard_action_event(2, event, P2_KEYS)
		Mode.COUCH:
			# Route joypad events by device id → player index
			if event is InputEventJoypadButton:
				var player := _player_for_device(event.device)
				if player != 0:
					if event.pressed and not event.is_echo():
						if JOY_TO_ACTION.has(event.button_index):
							action_pressed.emit( player, JOY_TO_ACTION[event.button_index])
					else:
						if JOY_TO_ACTION.has(event.button_index):
							action_released.emit( player, JOY_TO_ACTION[event.button_index])
					get_viewport().set_input_as_handled()
					return


# If player has a gamepad, read stick; otherwise, read keyboard axes.
func _get_dir_for_player(player: int) -> Vector2:
	match mode:
		Mode.TABLE:
			var keys   := P1_KEYS if player == 1 else P2_KEYS
			var x_axis := Input.get_action_strength(keys[INPUT_RIGHT]) - Input.get_action_strength(keys[INPUT_LEFT])
			var y_axis := Input.get_action_strength(keys[INPUT_DOWN]) - Input.get_action_strength(keys[INPUT_UP])
			var v      := Vector2(x_axis, y_axis)
			return v.normalized() if v.length() > 1.0 else v
		Mode.COUCH:
			var dev := p1_device_id if player == 1 else p2_device_id
			var x   := Input.get_joy_axis(dev, JoyAxis.JOY_AXIS_LEFT_X)
			var y   := Input.get_joy_axis(dev, JoyAxis.JOY_AXIS_LEFT_Y)
			var v   := Vector2(x, y)
			# invert Y if you want up to be negative stick Y (depends on your game)
			if v.length() < DEADZONE:
				return Vector2.ZERO
			return v
	return Vector2.ZERO


func _player_for_device(device_id: int) -> int:
	if device_id == p1_device_id:
		return 1
	if device_id == p2_device_id:
		return 2
	return 0


# If only one pad, P2 stays -1 and uses keyboard.
func _handle_keyboard_action_event(player: int, event: InputEventKey, keys: Dictionary) -> void:
	# Map key events to abstract actions; movement is polled each frame separately.
	if event.pressed:
		if event.is_action_pressed(keys[INPUT_ACTION_A]):
			action_pressed.emit( player, INPUT_ACTION_A)
		if event.is_action_pressed(keys[INPUT_ACTION_B]):
			action_pressed.emit( player, INPUT_ACTION_B)
		if event.is_action_pressed(keys[INPUT_START]):
			action_pressed.emit( player, INPUT_START)
	else:
		if event.is_action_released(keys[INPUT_ACTION_A]):
			action_released.emit( player, INPUT_ACTION_A)
		if event.is_action_released(keys[INPUT_ACTION_B]):
			action_released.emit( player, INPUT_ACTION_B)
		if event.is_action_released(keys[INPUT_START]):
			action_released.emit( player, INPUT_START)
