extends RigidBody2D


const FORCE_AMOUNT: int       = 1000
const LINEAR_DAMP: int        = 1
const SCREEN_WRAP_MARGIN: int = 15

var screen_size: Vector2

var input_mapping: Dictionary = {
									"left": "ui_left",
									"right": "ui_right",
									"up": "ui_up",
									"down": "ui_down"
								}
var input_mapping_format: Dictionary = {
									"left": "p%d_left",
									"right": "p%d_right",
									"up": "p%d_up",
									"down": "p%d_down"
								}

@export var player_num: int = 0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	set_linear_damp(LINEAR_DAMP)
	get_tree().root.size_changed.connect(_on_viewport_resize)
	_on_viewport_resize()
	# Set up input mapping for player
	for key in input_mapping.keys():
		var action_name: String = input_mapping_format[key] % player_num
		if InputMap.has_action(action_name):
			input_mapping[key] = action_name
		else:
			print("Input action not found: ", action_name)
	pass # Replace with function body.


func _on_viewport_resize() -> void:
	screen_size = get_viewport_rect().size
	pass

 
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	# Apply forces based on input mapping
	if Input.is_action_pressed(input_mapping["right"]):
		apply_central_force(Vector2(FORCE_AMOUNT, 0))
	if Input.is_action_pressed(input_mapping["left"]):
		apply_central_force(Vector2(-FORCE_AMOUNT, 0))
	if Input.is_action_pressed(input_mapping["up"]):
		apply_central_force(Vector2(0, -FORCE_AMOUNT))
	if Input.is_action_pressed(input_mapping["down"]):
		apply_central_force(Vector2(0, FORCE_AMOUNT))
		
	# get angle from linear velocity and rotate the ship halfway towards that target
	var target_angle: float = linear_velocity.angle()
	rotation = target_angle

	# ship position wraps around the screen edges
	position.x = wrapf(position.x, -SCREEN_WRAP_MARGIN, screen_size.x + SCREEN_WRAP_MARGIN)
	position.y = wrapf(position.y, -SCREEN_WRAP_MARGIN, screen_size.y + SCREEN_WRAP_MARGIN)
	
	pass

			
