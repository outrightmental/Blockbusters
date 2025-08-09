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
	_assign_gamepads()


# Detect the input mode based on the current input devices, see #126
func _on_joy_connection_changed(_device: int, _connected: bool) -> void:
	if Input.get_connected_joypads().size() >= 2:
		print ("[GAME] Activating dual gamepad input mode")
		mode = Mode.COUCH
	else:
		print ("[GAME] Activating single gamepad input mode")
		mode = Mode.TABLE
	input_mode_updated.emit()
	_assign_gamepads()


signal move(player: int, dir: Vector2)                 # per-frame movement vector
signal action_pressed(player: int, action: String)     # e.g., "fire", "start"
signal action_released(player: int, action: String)
# --- Config --------------------------------------------------------------

# Deadzone for sticks
const DEADZONE := 0.25
# Axes (0=X, 1=Y on most devices; customize if needed)
const AXIS_LEFT_X := 0
const AXIS_LEFT_Y := 1
# Map joypad buttons → abstract actions (adjust to your liking)
# 0=A 1=B 2=X 3=Y 6=BACK 7=START on XInput; tweak for your target
const JOY_TO_ACTION := {
						   0: "fire",
						   7: "start"
					   }
# Keyboard action names that already exist in your Input Map
const P1_KEYS := {
					 "left": "p1_left",
					 "right": "p1_right",
					 "up": "p1_up",
					 "down": "p1_down",
					 "fire": "p1_fire",
					 "start": "p1_start"
				 }
const P2_KEYS := {
					 "left": "p2_left",
					 "right": "p2_right",
					 "up": "p2_up",
					 "down": "p2_down",
					 "fire": "p2_fire",
					 "start": "p2_start"
				 }
# --- State ---------------------------------------------------------------

var p1_device_id: int = -1   # -1 = no gamepad (uses keyboard)
var p2_device_id: int = -1


func _physics_process(_delta: float) -> void:
	# Player 1 movement
	var p1_dir := _get_dir_for_player(1)
	emit_signal("move", 1, p1_dir)
	# Player 2 movement
	var p2_dir := _get_dir_for_player(2)
	emit_signal("move", 2, p2_dir)


func _input(event: InputEvent) -> void:
	# Route joypad events by device id → player index
	if event is InputEventJoypadButton:
		var player := _player_for_device(event.device)
		if player != 0:
			if event.pressed and not event.is_echo():
				if JOY_TO_ACTION.has(event.button_index):
					emit_signal("action_pressed", player, JOY_TO_ACTION[event.button_index])
			else:
				if JOY_TO_ACTION.has(event.button_index):
					emit_signal("action_released", player, JOY_TO_ACTION[event.button_index])
			get_viewport().set_input_as_handled()
			return

	# Keyboard: only for players that DON'T have a gamepad
	if event is InputEventKey and not event.is_echo():
		# P1 keyboard actions
		if p1_device_id == -1:
			_handle_keyboard_action_event(1, event, P1_KEYS)
		# P2 keyboard actions
		if p2_device_id == -1:
			_handle_keyboard_action_event(2, event, P2_KEYS)


# --- Helpers -------------------------------------------------------------

func _get_dir_for_player(player: int) -> Vector2:
	# If player has a gamepad, read stick; otherwise, read keyboard axes.
	var dev := p1_device_id if player == 1 else p2_device_id
	if dev != -1:
		var x := Input.get_joy_axis(dev, AXIS_LEFT_X)
		var y := Input.get_joy_axis(dev, AXIS_LEFT_Y)
		var v := Vector2(x, y)
		# invert Y if you want up to be negative stick Y (depends on your game)
		if v.length() < DEADZONE:
			return Vector2.ZERO
		return v
	else:
		var keys   := P1_KEYS if player == 1 else P2_KEYS
		var x_axis := Input.get_action_strength(keys["right"]) - Input.get_action_strength(keys["left"])
		var y_axis := Input.get_action_strength(keys["down"]) - Input.get_action_strength(keys["up"])
		var v      := Vector2(x_axis, y_axis)
		return v.normalized() if v.length() > 1.0 else v


func _player_for_device(device_id: int) -> int:
	if device_id == p1_device_id:
		return 1
	if device_id == p2_device_id:
		return 2
	return 0


func _assign_gamepads() -> void:
	var devices := Input.get_connected_joypads()
	devices.sort()  # lowest id first for stability
	# Optionally: dedupe "ghost" XInput mirrors by GUID/name here.

	p1_device_id = -1
	p2_device_id = -1
	if devices.size() >= 1:
		p1_device_id = devices[0]
	if devices.size() >= 2:
		p2_device_id = devices[1]


# If only one pad, P2 stays -1 and uses keyboard.

func _handle_keyboard_action_event(player: int, event: InputEventKey, keys: Dictionary) -> void:
	# Map key events to abstract actions; movement is polled each frame separately.
	if event.pressed:
		if event.is_action_pressed(keys["fire"]):
			emit_signal("action_pressed", player, "fire")
		if event.is_action_pressed(keys["start"]):
			emit_signal("action_pressed", player, "start")
	else:
		if event.is_action_released(keys["fire"]):
			emit_signal("action_released", player, "fire")
		if event.is_action_released(keys["start"]):
			emit_signal("action_released", player, "start")
