extends Node

# All available signals -- use these constants to reference them to avoid typos
signal reset_game()
signal player_score_updated()
signal player_inventory_updated()
signal player_did_launch_projectile(player_num: int)
signal player_did_collect_gem(player_num: int)
signal player_did_harm(player_num: int)
signal player_enabled(player_num: int, enabled: bool)
signal projectile_count_updated
signal player_ready_updated
signal player_laser_charge_updated(player_num: int, charge_sec: float)
# Group names
const BLOCK_GROUP: StringName = "BlockGroup"
const GEM_GROUP: StringName   = "GemGroup"
# Enum for whether Player 1 wins, Player 2 wins, or a draw
enum Result {
	PLAYER_1_WINS,
	PLAYER_2_WINS,
	DRAW,
}
# Enum for player inventory items
enum InventoryItemType {
	PROJECTILE,
	EMPTY
}
# Keeping track of the score
@onready var player_score: Dictionary = {
									 1: 0,
									 2: 0,
								 }
# Keeping track of player inventory
@onready var player_inventory: Dictionary = {
									 1: [],
									 2: [],
								 }

# Keeping track of the gem count
@onready var gems_collected: int = 0
# Keeping track of the projectile count
@onready var projectiles_in_play: int = 0

# Check if the player can launch a projectile
func player_can_launch_projectile(player_num: int) -> bool:
	for player_inventory_item in player_inventory[player_num]:
		if player_inventory_item == InventoryItemType.PROJECTILE:
			return true
	return false
		

func _ready() -> void:
	reset_game.connect(_do_reset_game)
	player_did_launch_projectile.connect(_on_player_launch_projectile)
	player_did_collect_gem.connect(_on_player_collect_gem)
	player_did_harm.connect(_on_player_harm)
	projectile_count_updated.connect(_on_projectile_count_updated)
	player_ready_updated.connect(_on_player_ready_updated)
	player_laser_charge_updated.connect(_on_player_laser_charge_updated)
	player_enabled.connect(_on_player_enabled)


func _do_reset_game() -> void:
	gems_collected = 0
	player_score[1] = Constant.PLAYER_SCORE_INITIAL
	player_score[2] = Constant.PLAYER_SCORE_INITIAL
	player_inventory[1] = []
	player_inventory[2] = []
	for i in range(Constant.PLAYER_INVENTORY_MAX_ITEMS):
		player_inventory[1].append(Game.InventoryItemType.PROJECTILE)
		player_inventory[2].append(Game.InventoryItemType.PROJECTILE)
	print("[GAME] Resetting player score to: ", player_score)
	print("[GAME] Resetting player inventory to: ", player_inventory)
	player_score_updated.emit()
	player_inventory_updated.emit()


func _on_player_launch_projectile(player_num: int) -> void:
	_player_inventory_remove(player_num, InventoryItemType.PROJECTILE)
	player_inventory_updated.emit()


func _on_player_collect_gem(player_num: int) -> void:
	player_score[player_num] = clamp(player_score[player_num] + Constant.PLAYER_SCORE_COLLECT_GEM_VALUE, 0, Constant.PLAYER_SCORE_VICTORY)
	print("[GAME] Player %d collected gem, new score: %d" % [player_num, player_score[player_num]])
	player_score_updated.emit()


func _on_player_harm(player_num: int) -> void:
	player_score[player_num] = clamp(player_score[player_num] - Constant.PLAYER_SCORE_DISABLE_SHIP_VALUE, 0, Constant.PLAYER_SCORE_VICTORY)
	print("[GAME] Player %d did harm, new score: %d" % [player_num, player_score[player_num]])
	player_score_updated.emit()


func _on_projectile_count_updated() -> void:
	print ("[PROJECTILES] in play: ", projectiles_in_play)


func _on_player_ready_updated() -> void:
	pass


func _on_player_laser_charge_updated(_player_num: int, _charge_sec: float ) -> void:
	pass


func _on_player_enabled(_player_num: int, _enabled: bool) -> void:
	pass


func _player_inventory_remove(player_num: int, item: InventoryItemType) -> void:
	var new_inventory = [];
	var removed:bool = false;
	for player_inventory_item in player_inventory[player_num]:
		if player_inventory_item == item and not removed:
			removed = true
		else:
			new_inventory.append(player_inventory_item)
	player_inventory[player_num] = new_inventory
