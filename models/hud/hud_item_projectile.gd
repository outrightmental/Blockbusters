class_name  HudItemProjectile
extends HudInventoryItem

# Player number to identify the projectile
@export var player_num: int = 0


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
