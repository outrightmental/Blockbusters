class_name  HudItemEmpty
extends HudInventoryItem

const COLOR_ALPHA_RATIO = 0.2

# Initialize the type of inventory item
func _init() -> void:
	type = Game.InventoryItemType.EMPTY

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Set the sprite texture based on player_num
	if player_num in Constant.PLAYER_COLORS:
		$Shape.material.set_shader_parameter("color", Util.color_at_alpha_ratio(Constant.PLAYER_COLORS[player_num][0], COLOR_ALPHA_RATIO))
	else:
		push_error("No color found for player ", player_num)
