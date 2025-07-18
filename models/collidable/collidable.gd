class_name Collidable
extends RigidBody2D

# Unique identifier for the collidable object
@export var number: int = 0

# Static variable to hold the number counter
static var _numberCounter: int = 0

# Velocity last seen and delta when it was sampled
var last_velocity: Vector2 = Vector2.ZERO

# Time created
var created_at: float = 0.0

# Get the acceleration between the last processed frame and now
# Acceleration = Change in velocity / time between samples
# Last delta is just an approximation of the current frame rate
# Because it was from the last processed frame, but it will work for our purposes.
func acceleration() -> Vector2:
	return (linear_velocity - last_velocity);


# Function to get the age of the bubble in milliseconds 
func age() -> float:
	return Time.get_ticks_msec() - created_at

 
# Called when the bubble is instantiated
func _init():
	_numberCounter += 1
	number = _numberCounter
 

# Called when the scene is added to the tree
# Load the sprite and connect the signal
func _ready():
	created_at = Time.get_ticks_msec()
	contact_monitor = true
	max_contacts_reported = 1
	
	
# Called at a fixed rate
func _physics_process(_delta):
	last_velocity = linear_velocity
