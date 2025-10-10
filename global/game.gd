extends Node

# All available signals -- use these constants to reference them to avoid typos
signal finished()
signal player_did_collect_item(player_num: int, type: InventoryItemType)
signal player_did_launch_projectile(player_num: int)
signal player_enabled(player_num: int, enabled: bool)
signal player_energy_updated(player_num: int, charge_ratio: float, is_available: bool)
signal player_inventory_updated()
signal player_ready_updated
signal player_score_updated()
signal show_banner(player_num: int, message: String, message_2: String)
signal show_debug_text(text: String)
signal spawn_gem()
signal spawn_pickup(type: Game.InventoryItemType)
signal start_new_game()
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

# Keep track of whether the game is over
@export var is_over: bool = false
# Whether the input is paused
@export var is_input_movement_paused: bool = false
@export var is_input_tools_paused: bool = false
@export var is_lighting_enabled: bool = true

# Internal variables
var _started_at_ticks_msec: int           = 0
var _spawn_next_gem_at_msec: int          = 0
var _spawn_next_pickup_at_msec: int       = 0
var _gem_dont_spawn_until_ticks_msec: int = 0


# Check if the player can launch a projectile
func player_can_launch_projectile(player_num: int) -> bool:
	for player_inventory_item in player_inventory[player_num]:
		if player_inventory_item == InventoryItemType.PROJECTILE:
			return true
	return false


# Check if the player has room in their inventory for a new item
func player_can_add_item(player_num: int) -> bool:
	return len(player_inventory[player_num]) < Constant.PLAYER_INVENTORY_MAX_ITEMS


# Player scored a goal
func do_player_goal(player_num: int) -> void:
	player_score[player_num] = clamp(player_score[player_num] + Constant.PLAYER_SCORE_GOAL_VALUE, 0, Constant.PLAYER_SCORE_VICTORY)
	print("[GAME] Player %d scored a goal, new score: %d" % [player_num, player_score[player_num]])
	player_score_updated.emit()
	_gem_dont_spawn_until_ticks_msec = Time.get_ticks_msec() + Constant.GEM_SPAWN_AFTER_SCORING_DELAY_MSEC
	if not _check_for_game_over():
		show_banner.emit(player_num, Constant.BANNER_TEXT_GOAL, "")


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
	player_did_collect_item.connect(_on_player_did_collect_item)
	player_did_launch_projectile.connect(_on_player_launch_projectile)
	player_enabled.connect(_on_player_enabled)
	player_energy_updated.connect(_on_player_energy_updated)
	player_ready_updated.connect(_on_player_ready_updated)
	player_score_updated.connect(_check_for_game_over)
	show_banner.connect(_on_show_banner)
	show_debug_text.connect(_on_show_debug_text)
	start_new_game.connect(_do_start_new_game)


func _do_start_new_game() -> void:
	unpause_input()
	is_over = false
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
	_started_at_ticks_msec = Time.get_ticks_msec()
	_spawn_next_gem_at_msec = _started_at_ticks_msec + int(Constant.BANNER_SHOW_SEC * 1000 * Constant.BANNER_SHOW_TIME_SCALE)
	_spawn_next_pickup_at_msec = _spawn_next_gem_at_msec + int(Constant.PICKUP_SPAWN_INITIAL_SEC * 1000 * Constant.BANNER_SHOW_TIME_SCALE)
	# Countdown and then start the game
	Game.pause_input()
	show_banner.emit(0, Constant.BANNER_TEXT_READY, Constant.BANNER_TEXT_SET)
	await Util.delay(Constant.BANNER_SHOW_SEC * Constant.BANNER_SHOW_TIME_SCALE)
	Game.unpause_input()


# Called at a fixed rate. 'delta' is the elapsed time since the previous frame.
func _physics_process(_delta: float) -> void:
	# Check if it's time to spawn a gem
	if not is_over and Time.get_ticks_msec() >= _spawn_next_gem_at_msec:
		_spawn_next_gem_at_msec = Time.get_ticks_msec() + int(Constant.GEM_SPAWN_EVERY_SEC * 1000)
		spawn_gem.emit()
	# Check if it's time to spawn a pickup
	if not is_over and Time.get_ticks_msec() >= _spawn_next_pickup_at_msec:
		_spawn_next_pickup_at_msec = Time.get_ticks_msec() + int(Constant.PICKUP_SPAWN_EVERY_SEC * 1000)
		spawn_pickup.emit(Game.InventoryItemType.PROJECTILE) # FUTURE: other types of pickups
	pass


# Check for game over, e.g. when score or gem count is updated
# ---
# The game is a stalemate if a state is reached where no player can win based on the number of gems left in play, 
# ---
# The game is a stalemate if neither player can afford to launch a projectile, and there are not enough free gems (gems 
# not enclosed in blocks) for either player to win, BUT deciding stalemate based on whether players don't have enough 
# points to launch projectiles is tricky, because it's possible that a player launched their last projectile and is in 
# fact going to win after that projectile explodes, so we need to also test that no projectiles are in play
func _check_for_game_over() -> bool:
	if is_over:
		return true
	if Game.player_score[1] == Constant.PLAYER_SCORE_VICTORY:
		_do_game_over(Game.Result.PLAYER_1_WINS)
		return true
	elif Game.player_score[2] == Constant.PLAYER_SCORE_VICTORY:
		_do_game_over(Game.Result.PLAYER_2_WINS)
		return true
	elif Game.player_score[1] == Constant.PLAYER_SCORE_VICTORY and Game.player_score[2] == Constant.PLAYER_SCORE_VICTORY:
		_do_game_over(Game.Result.DRAW)
		return true

	var total_gems: int                 = get_tree().get_node_count_in_group(Game.GEM_GROUP)
	var total_gem_candidate_blocks: int = 0
	var blocks: Array[Node]             = get_tree().get_nodes_in_group(Game.BLOCK_GROUP)
	for block in blocks:
		if block.is_empty():
			total_gem_candidate_blocks += 1
	if total_gems == 0 and total_gem_candidate_blocks == 0:
		if Game.player_score[1]  > Game.player_score[2]:
			_do_game_over(Game.Result.PLAYER_1_WINS)
			return true
		elif Game.player_score[2] > Game.player_score[1]:
			_do_game_over(Game.Result.PLAYER_2_WINS)
			return true
		else:
			_do_game_over(Game.Result.DRAW)
			return true

	return false


func _do_game_over(result: Result) -> void:
	if is_over:
		return
	pause_input()
	is_over = true
	match result:
		Result.PLAYER_1_WINS:
			show_banner.emit(1, Constant.BANNER_TEXT_VICTORY, "")
		Result.PLAYER_2_WINS:
			show_banner.emit(2, Constant.BANNER_TEXT_VICTORY, "")
		Result.DRAW:
			show_banner.emit(0, Constant.BANNER_TEXT_DRAW, "")
	await Util.delay(Constant.BANNER_SHOW_SEC * Constant.BANNER_SHOW_TIME_SCALE)
	finished.emit()


func _on_player_launch_projectile(player_num: int) -> void:
	_player_inventory_remove(player_num, InventoryItemType.PROJECTILE)
	player_inventory_updated.emit()


func _on_player_ready_updated() -> void:
	pass


func _on_player_energy_updated(_player_num: int, _charge_ratio: float, _is_available: bool) -> void:
	pass


func _on_player_enabled(_player_num: int, _enabled: bool) -> void:
	pass


func _on_show_debug_text(_text: String) -> void:
	pass


func _on_show_banner(_p: int, _m1: String, _m2: String) -> void:
	Game.pause_input_tools()
	Engine.time_scale = Constant.BANNER_SHOW_TIME_SCALE
	await Util.delay(Constant.BANNER_SHOW_SEC * Constant.BANNER_SHOW_TIME_SCALE)
	Game.unpause_input()
	Engine.time_scale = 1.0

	
func _on_player_did_collect_item(player_num: int, type: InventoryItemType) -> void:
	print("[GAME] Player %d collected pickup: %s" % [player_num, type])
	player_inventory[player_num].append(type)
	player_inventory_updated.emit()
	pass


func _player_inventory_remove(player_num: int, item: InventoryItemType) -> void:
	var new_inventory: Array[Variant] = [];
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
