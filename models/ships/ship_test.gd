extends RigidBody2D


const FORCE_AMOUNT = 1000
const LINEAR_DAMP = 10
const SCREEN_WRAPAROUND_MARGIN = 10

var screen_size: Vector2

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	set_linear_damp(LINEAR_DAMP)
	get_tree().root.size_changed.connect(_on_viewport_resize)
	_on_viewport_resize()
	pass # Replace with function body.


func _on_viewport_resize() -> void:
	screen_size = get_viewport_rect().size
	pass

 
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	# listen for ASDW keys and apply acceleration to this rigid body 2d physics object
	if Input.is_action_pressed("ui_right"):
		apply_central_force(Vector2(FORCE_AMOUNT, 0))
	if Input.is_action_pressed("ui_left"):
		apply_central_force(Vector2(-FORCE_AMOUNT, 0))
	if Input.is_action_pressed("ui_up"):
		apply_central_force(Vector2(0, -FORCE_AMOUNT))
	if Input.is_action_pressed("ui_down"):
		apply_central_force(Vector2(0, FORCE_AMOUNT))
		
	# get angle from linear velocity and rotate the ship halfway towards that target
	var target_angle = linear_velocity.angle()
	rotation = target_angle
	
	# if ship leaves the screen, wrap around
	if position.x < -SCREEN_WRAPAROUND_MARGIN:
		position.x += screen_size.x + SCREEN_WRAPAROUND_MARGIN * 2
	elif position.x > screen_size.x + SCREEN_WRAPAROUND_MARGIN:
		position.x -= screen_size.x  + SCREEN_WRAPAROUND_MARGIN * 2
	elif position.y < -SCREEN_WRAPAROUND_MARGIN:
		position.y += screen_size.y + SCREEN_WRAPAROUND_MARGIN * 2
	elif position.y > screen_size.y + SCREEN_WRAPAROUND_MARGIN:
		position.y -= screen_size.y + SCREEN_WRAPAROUND_MARGIN * 2
			
	pass
