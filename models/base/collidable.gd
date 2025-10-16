class_name Collidable
extends RigidBody2D

# Unique identifier for the collidable object
@export var number: int = _nextNumber()

# Static variable to hold the number counter
static var _numberCounter: int = 0


# Called when the bubble is instantiated
func _nextNumber() -> int:
	_numberCounter += 1
	return _numberCounter


# Called when the scene is added to the tree
# Load the sprite and connect the signal
func _ready():
	contact_monitor = true
	max_contacts_reported = 1

