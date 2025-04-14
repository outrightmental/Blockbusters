extends RigidBody2D


const FORCE_AMOUNT: int       = 500
const LINEAR_DAMP: int        = 1
const SCREEN_WRAP_MARGIN: int = 15

var screen_size: Vector2

var input_mapping: Dictionary = {
									"left": "ui_left",
									"right": "ui_right",
									"up": "ui_up",
									"down": "ui_down"
								}
const input_mapping_format: Dictionary = {
									"left": "p%d_left",
									"right": "p%d_right",
									"up": "p%d_up",
									"down": "p%d_down"
								}

const dir_vectors := {
					   "right": Vector2(1, 0),
					   "left": Vector2(-1, 0),
					   "up": Vector2(0, -1),
					   "down": Vector2(0, 1),
				   }

@export var player_num: int = 0

# Map player_num to textures
var player_textures: Dictionary = {
									  1: preload("res://assets/ships/ship1.png"),
									  2: preload("res://assets/ships/ship2.png")
								  }

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
		
	# Set the sprite texture based on player_num
	if player_num in player_textures:
		$Sprite2D.texture = player_textures[player_num]
	else:
		print("No texture found for player_num: ", player_num)		

	pass


func _on_viewport_resize() -> void:
	screen_size = get_viewport_rect().size
	pass

 
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
#	# Apply forces based on input mapping
#	if Input.is_action_pressed(input_mapping["right"]):
#		apply_central_force(Vector2(FORCE_AMOUNT, 0))
#	if Input.is_action_pressed(input_mapping["left"]):
#		apply_central_force(Vector2(-FORCE_AMOUNT, 0))
#	if Input.is_action_pressed(input_mapping["up"]):
#		apply_central_force(Vector2(0, -FORCE_AMOUNT))
#	if Input.is_action_pressed(input_mapping["down"]):
#		apply_central_force(Vector2(0, FORCE_AMOUNT))

	for key in dir_vectors.keys():
		# Tap to rotate (strafe)
		if Input.is_action_just_pressed(input_mapping[key]):
			rotation = dir_vectors[key].angle()

		# Hold to move and rotate to velocity
		if Input.is_action_pressed(input_mapping[key]):
			apply_central_force(dir_vectors[key] * FORCE_AMOUNT)
			rotation = linear_velocity.angle()
		
	# get angle from linear velocity and rotate the ship halfway towards that target
	var target_angle: float = linear_velocity.angle()
	rotation = target_angle

	# ship position wraps around the screen edges
	position.x = wrapf(position.x, -SCREEN_WRAP_MARGIN, screen_size.x + SCREEN_WRAP_MARGIN)
	position.y = wrapf(position.y, -SCREEN_WRAP_MARGIN, screen_size.y + SCREEN_WRAP_MARGIN)
	
	pass

			
