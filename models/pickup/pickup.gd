class_name Pickup
extends Collidable


@export var type : Game.InventoryItemType = Game.InventoryItemType.EMPTY


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	add_to_group(Game.PICKUP_GROUP)
	pass
