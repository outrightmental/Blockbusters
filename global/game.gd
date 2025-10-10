extends Node

# All available signals -- use these constants to reference them to avoid typos
signal gem_spawned()
signal input_mode_updated()
signal over(result: Result)
signal pickup_spawned(type: InventoryItemType)
signal player_did_collect_gem(player_num: int)
signal player_did_collect_item(player_num: int, type: InventoryItemType)
signal player_did_harm(player_num: int)
signal player_did_launch_projectile(player_num: int)
signal player_enabled(player_num: int, enabled: bool)
signal player_energy_updated(player_num: int, charge_ratio: float, is_available: bool)
signal player_inventory_updated()
signal player_ready_updated
signal player_score_updated()
signal projectile_count_updated
signal reset_game()
signal show_debug_text(text: String)
# Group names
const BLOCK_GROUP: StringName  = "BlockGroup"
const GEM_GROUP: StringName    = "GemGroup"
const PICKUP_GROUP: StringName = "PickupGroup"
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
# Enum for input modes
enum Mode {
	TABLE,
	COUCH,
}
# Keep track of the input mode
@export var mode: Mode = _compute_mode()

# Keeping track of the score
@export var player_score: Dictionary = {
										   1: 0,
										   2: 0,
									   }

# Keeping track of player inventory
@export var player_inventory: Dictionary = {
											   1: [],
											   2: [],
										   }

# Keeping track of the gem count
@export var gems_collected: int = 0
# Keeping track of the projectile count
@export var projectiles_in_play: int = 0
# Keep track of whether the game is over
@export var is_over: bool = false
# Whether the input is paused
@export var is_input_movement_paused: bool = false
@export var is_input_tools_paused: bool = false
@export var is_lighting_enabled: bool = true


# Check if the player can launch a projectile
func player_can_launch_projectile(player_num: int) -> bool:
	for player_inventory_item in player_inventory[player_num]:
		if player_inventory_item == InventoryItemType.PROJECTILE:
			return true
	return false


# Check if the player has room in their inventory for a new item
func player_can_add_item(player_num: int) -> bool:
	return len(player_inventory[player_num]) < Constant.PLAYER_INVENTORY_MAX_ITEMS


# Pause the player input
func pause_input() -> void:
	is_input_movement_paused = true
	is_input_tools_paused = true


# Pause only the player tool use input
func pause_input_tools() -> void:
	is_input_tools_paused = true


# Unpause the game
func unpause_input() -> void:
	is_input_movement_paused = false
	is_input_tools_paused = false


# Get the command line arguments on init
func _init() -> void:
	for arg in OS.get_cmdline_args():
		if arg == "--no_lighting":
			is_lighting_enabled = false


func _ready() -> void:
	gem_spawned.connect(_check_for_game_over)
	over.connect(_on_game_over)
	pickup_spawned.connect(_check_for_game_over)
	player_did_collect_gem.connect(_on_player_collect_gem)
	player_did_collect_item.connect(_on_player_did_collect_item)
	player_did_harm.connect(_on_player_harm)
	player_did_launch_projectile.connect(_on_player_launch_projectile)
	player_enabled.connect(_on_player_enabled)
	player_energy_updated.connect(_on_player_energy_updated)
	player_ready_updated.connect(_on_player_ready_updated)
	player_score_updated.connect(_check_for_game_over)
	projectile_count_updated.connect(_check_for_game_over)
	projectile_count_updated.connect(_on_projectile_count_updated)
	reset_game.connect(_do_reset_game)
	show_debug_text.connect(_on_show_debug_text)


func _do_reset_game() -> void:
	unpause_input()
	is_over = false
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


# Check for game over, e.g. when score or gem count is updated
# ---
# The game is a stalemate if a state is reached where no player can win based on the number of gems left in play, 
# ---
# The game is a stalemate if neither player can afford to launch a projectile, and there are not enough free gems (gems 
# not enclosed in blocks) for either player to win, BUT deciding stalemate based on whether players don't have enough 
# points to launch projectiles is tricky, because it's possible that a player launched their last projectile and is in 
# fact going to win after that projectile explodes, so we need to also test that no projectiles are in play
func _check_for_game_over() -> void:
	if is_over:
		return
	if Game.player_score[1] == Constant.PLAYER_SCORE_VICTORY:
		over.emit(Game.Result.PLAYER_1_WINS)
		return
	elif Game.player_score[2] == Constant.PLAYER_SCORE_VICTORY:
		over.emit(Game.Result.PLAYER_2_WINS)
		return
	elif Game.player_score[1] == Constant.PLAYER_SCORE_VICTORY and Game.player_score[2] == Constant.PLAYER_SCORE_VICTORY:
		over.emit(Game.Result.DRAW)
		return

	var total_gems: int                 = get_tree().get_node_count_in_group(Game.GEM_GROUP)
	var total_gem_candidate_blocks: int = 0
	var blocks: Array[Node]             = get_tree().get_nodes_in_group(Game.BLOCK_GROUP)
	for block in blocks:
		if block.is_empty():
			total_gem_candidate_blocks += 1
	if total_gems == 0 and total_gem_candidate_blocks == 0:
		if Game.player_score[1]  > Game.player_score[2]:
			over.emit(Game.Result.PLAYER_1_WINS)
			return
		elif Game.player_score[2] > Game.player_score[1]:
			over.emit(Game.Result.PLAYER_2_WINS)
			return
		else:
			over.emit(Game.Result.DRAW)
			return


func _on_game_over() -> void:
	pause_input()
	is_over = true


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


func _on_player_energy_updated(_player_num: int, _charge_ratio: float, _is_available: bool) -> void:
	pass


func _on_player_enabled(_player_num: int, _enabled: bool) -> void:
	pass


func _on_show_debug_text(_text: String) -> void:
	pass


func _on_player_did_collect_item(player_num: int, type: InventoryItemType) -> void:
	print("[GAME] Player %d collected pickup: %s" % [player_num, type])
	player_inventory[player_num].append(type)
	player_inventory_updated.emit()
	pass


func _player_inventory_remove(player_num: int, item: InventoryItemType) -> void:
	var new_inventory = [];
	var removed: bool = false;
	for player_inventory_item in player_inventory[player_num]:
		if player_inventory_item == item and not removed:
			removed = true
		else:
			new_inventory.append(player_inventory_item)
	player_inventory[player_num] = new_inventory


# Table / Couch mode are two separate builds #150
static func _compute_mode() -> Mode:
	if OS.has_feature("couch_mode"):
		return Mode.COUCH
	if OS.has_feature("editor"):
		return Mode.COUCH
	else:
		return Mode.TABLE
