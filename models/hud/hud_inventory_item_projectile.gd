class_name  HudInventoryItemProjectile
extends HudInventoryItem

# Preloaded scene for the splash effect


# Initialize the type of inventory item
func _init() -> void:
	type = Game.InventoryItemType.PROJECTILE


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Set the sprite texture based on player_num
	if player_num in Constant.PLAYER_COLORS:
		$TriangleLight.color = Constant.PLAYER_COLORS[player_num][0]
		$TriangleDark.color = Constant.PLAYER_COLORS[player_num][1]
	else:
		push_error("No color found for player ", player_num)
	var splash: Node = ScenePreloader.explosive_splash_scene.instantiate()
	splash.position = position
	self.get_parent().call_deferred("add_child", splash)
