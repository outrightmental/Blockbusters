extends Node


# --- Lifecycle -----------------------------------------------------------

func _ready() -> void:
	# hot-plug support
	Input.joy_connection_changed.connect(func(_device: int, _connected: bool):
		_detect_joypads()
	)
	_detect_joypads()
	match Game.mode:
		Game.Mode.TABLE:
			print("[INPUT] Table Mode")
		Game.Mode.COUCH:
			print("[INPUT] Couch Mode")


# Detect the input Game.mode based on the current input devices, see #126
func _detect_joypads() -> void:
	if Game.mode == Game.Mode.TABLE:
		return
	var joypads: Array = Input.get_connected_joypads()
	joypads.sort()  # lowest id first for stability
	p1_device_id = joypads[0] if joypads.size() >= 1 else -1
	p2_device_id = joypads[1] if joypads.size() >= 2 else -1
	Game.input_mode_updated.emit()


signal move(player: int, dir: Vector2)                 # per-frame movement vector
signal action_pressed(player: int, action: String)     # e.g., "fire", "start"
signal action_released(player: int, action: String)

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
	if Game.is_input_movement_paused:
		return
	for p in [1, 2]:
		move.emit( p, _get_dir_for_player(p))


func _input(event: InputEvent) -> void:
	if Game.is_input_tools_paused:
		return
	if event is InputEventKey and not event.is_echo():
		_handle_keyboard_action_event(1, event, P1_KEYS)
		_handle_keyboard_action_event(2, event, P2_KEYS)
	if Game.mode == Game.Mode.COUCH:
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
	var dir: Vector2 = Vector2.ZERO
	var keys   := P1_KEYS if player == 1 else P2_KEYS
	var kbd_x := Input.get_action_strength(keys[INPUT_RIGHT]) - Input.get_action_strength(keys[INPUT_LEFT])
	var kbd_y := Input.get_action_strength(keys[INPUT_DOWN]) - Input.get_action_strength(keys[INPUT_UP])
	match Game.mode:
		Game.Mode.TABLE:
			match player:
				1:
					dir.x -= kbd_y
					dir.y += kbd_x
				2:
					dir.x += kbd_y
					dir.y -= kbd_x
		Game.Mode.COUCH:
			dir.x += kbd_x
			dir.y += kbd_y
			var dev := p1_device_id if player == 1 else p2_device_id
			if dev != -1:
				var joy_x   := Input.get_joy_axis(dev, JoyAxis.JOY_AXIS_LEFT_X)
				var joy_y   := Input.get_joy_axis(dev, JoyAxis.JOY_AXIS_LEFT_Y)
				if abs(joy_x) > Constant.PLAYER_INPUT_JOYSTICK_DEADZONE:
					dir.x += joy_x
				if abs(joy_y) > Constant.PLAYER_INPUT_JOYSTICK_DEADZONE:
					dir.y += joy_y
	return dir.normalized()


func _player_for_device(device_id: int) -> int:
	if device_id == p1_device_id:
		return 1
	if device_id == p2_device_id:
		return 2
	return 0


# If only one pad, P2 stays -1 and uses keyboard.
func _handle_keyboard_action_event(player: int, event: InputEventKey, keys: Dictionary) -> void:
	if Game.is_input_tools_paused:
		return
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
