class_name Gem
extends Collidable

# Player number to identify the ship
@export var player_num: int = 0


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass
	

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass


# Called when the ship is instantiated
func _init():
	super._init()
