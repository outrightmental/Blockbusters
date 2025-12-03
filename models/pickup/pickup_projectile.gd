class_name PickupProjectile
extends Pickup

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	type = Game.InventoryItemType.PROJECTILE

	# Disable lighting if not enabled in settings
	if not Game.is_lighting_fx_enabled:
		$PointLight2D.enabled = false

	# Call the parent _ready method
	super._ready()
