class_name HudInventory
extends Node2D

const ITEM_SPACING_X = 50

# Player number to identify the inventory
@export var player_num: int = 0

# Preloaded scene for the projectile item
const item_projectile_scene: PackedScene = preload("res://models/hud/hud_item_projectile.tscn")
const item_empty_scene: PackedScene = preload("res://models/hud/hud_item_empty.tscn")


# Current items displayed
var displayed_items: Array[HudInventoryItem] = []


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	Game.player_inventory_updated.connect(_on_inventory_updated)


# The player's inventory was updated
func _on_inventory_updated() -> void:
	for i in range(Constant.PLAYER_INVENTORY_MAX_ITEMS):
		var to_show: Game.InventoryItemType = Game.player_inventory[player_num][i] if i < Game.player_inventory[player_num].size() else Game.InventoryItemType.EMPTY
		if i < displayed_items.size():
			if displayed_items[i].type == to_show:
				continue
			else:
				displayed_items[i].queue_free()
				var new_item = _instantiate_item(to_show)
				new_item.position.x = ITEM_SPACING_X * i
				displayed_items[i] = new_item
		else:
			var new_item = _instantiate_item(to_show)
			new_item.position.x = ITEM_SPACING_X * i
			displayed_items.append(new_item)
			


# Instantiate an item scene by type
func _instantiate_item(type: Game.InventoryItemType) -> HudInventoryItem:
	match type:
		Game.InventoryItemType.PROJECTILE:
			var item = item_projectile_scene.instantiate()
			item.player_num = player_num
			return item
	return item_empty_scene.instantiate()
	
