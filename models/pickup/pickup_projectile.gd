class_name PickupProjectile
extends Pickup


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	type = Game.InventoryItemType.PROJECTILE
	super._ready()
