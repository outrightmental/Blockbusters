extends Node

# All available signals -- use these constants to reference them to avoid typos
signal finished()
signal outcome(result: Result)
signal player_did_collect_item(player_num: int, type: InventoryItemType)
signal player_did_launch_projectile(player_num: int)
signal player_enabled(player_num: int, enabled: bool)
signal player_energy_updated(player_num: int, charge_ratio: float, is_available: bool)
signal player_goal(player_num: int)
signal player_inventory_updated()
signal player_ready_updated
signal player_score_updated()
signal show_banner(player_num: int, message: String, message_2: String)
signal show_debug_text(text: String)
signal spawn_gem()
signal spawn_pickup(type: Game.InventoryItemType)
signal start_new_game()
# Group names
const BLOCK_GROUP: StringName       = "BlockGroup"
const BLOCK_HALF_GROUP: StringName  = "BlockHalfGroup"
const BLOCK_QUART_GROUP: StringName = "BlockQuartGroup"
const GEM_GROUP: StringName         = "GemGroup"
const PICKUP_GROUP: StringName      = "PickupGroup"
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
@export var is_game_paused: bool = false
@export var is_input_movement_paused: bool = false
@export var is_input_tools_paused: bool = false
@export var is_lighting_fx_enabled: bool = true
@export var is_shadow_fx_enabled: bool = true

# Internal variables
var _seconds_until_next_gem: float    = 0
var _seconds_until_next_pickup: float = 0


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
	_seconds_until_next_pickup = Constant.PICKUP_SPAWN_EVERY_SEC
	if not _check_for_game_over():
		player_goal.emit(player_num)
		show_banner.emit(player_num, Constant.BANNER_TEXT_GOAL, "")


# Pause the whole game
func pause() -> void:
	is_game_paused = true
	var tree: SceneTree = get_tree()
	if not tree:
		return
	tree.paused = true


# Pause the player input
func pause_input() -> void:
	is_input_movement_paused = true
	is_input_tools_paused = true


# Pause only the player tool use input
func pause_input_tools() -> void:
	is_input_tools_paused = true


# Unpause the whole game
func unpause() -> void:
	is_game_paused = false
	var tree: SceneTree = get_tree()
	if not tree:
		return
	tree.paused = false


# Unpause the game
func unpause_input() -> void:
	is_input_movement_paused = false
	is_input_tools_paused = false


# Whether the game is in table mode
func is_table_mode() -> bool:
	return mode == Mode.TABLE


# Whether the game is in couch mode
func is_couch_mode() -> bool:
	return mode == Mode.COUCH


# Get the name of an inventory item
func get_inventory_item_name(item: InventoryItemType) -> String:
	match item:
		InventoryItemType.PROJECTILE:
			return "Projectile"
		InventoryItemType.EMPTY:
			return "Empty"
	return "Unknown"


# Show a banner message
# Public for testing purposes
func do_show_banner(player_num: int, message: String, message_2) -> Signal:
	# Spawn the banner(s) based on mode, using base resolution for logical coordinates
	var viewport_width: float  = ResolutionManager.BASE_WIDTH
	var viewport_height: float = ResolutionManager.BASE_HEIGHT
	match Game.mode:
		Game.Mode.COUCH:
			_spawn_banner(player_num, viewport_width / 2, viewport_height / 2, 0, 1, message, message_2)
		Game.Mode.TABLE:
			_spawn_banner(player_num, viewport_width * 0.75, viewport_height / 2, -90, 0.6, message, message_2)
			_spawn_banner(player_num, viewport_width * 0.25, viewport_height / 2, 90, 0.6, message, message_2)
	# Pause input and slow down time during the banner display
	Game.pause_input_tools()
	_do_time_slow()
	await Util.delay(Constant.BANNER_SHOW_SEC * Constant.TIME_SLOW_SCALE)
	Game.unpause_input()
	_do_time_norm()
	return Util.callback()


# Toggle the lighting FX
func toggle_lighting_fx() -> bool:
	is_lighting_fx_enabled = not is_lighting_fx_enabled
	return is_lighting_fx_enabled


# Toggle the shadow FX
func toggle_shadow_fx() -> bool:
	is_shadow_fx_enabled = not is_shadow_fx_enabled
	return is_shadow_fx_enabled


# Spawn a banner at the given position
# Public for testing purposes
func _spawn_banner(player_num: int, x: float, y: float, _rotation_degrees: float, _scale: float, message: String, message_2: String) -> void:
	var banner: Node = ScenePreloader.banner_scene.instantiate()
	banner.scale = Vector2(_scale, _scale)
	banner.position = ResolutionManager.get_offset() + Vector2(x, y)
	banner.rotation_degrees = _rotation_degrees
	banner.player_num = player_num
	banner.message = message
	banner.message_2 = message_2
	banner.z_index = 1000
	self.add_child(banner)


# Get the command line arguments on init
func _init() -> void:
	for arg in OS.get_cmdline_args():
		if arg == "--no-lighting-fx":
			is_lighting_fx_enabled = false
		if arg == "--no-shadow-fx":
			is_shadow_fx_enabled = false


func _ready() -> void:
	player_did_collect_item.connect(_on_player_did_collect_item)
	player_did_launch_projectile.connect(_on_player_launch_projectile)
	player_enabled.connect(_on_player_enabled)
	player_energy_updated.connect(_on_player_energy_updated)
	player_ready_updated.connect(_on_player_ready_updated)
	player_score_updated.connect(_check_for_game_over)
	show_banner.connect(do_show_banner)
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
	_seconds_until_next_gem = 0
	_seconds_until_next_pickup = Constant.BANNER_SHOW_SEC * Constant.TIME_SLOW_SCALE + Constant.PICKUP_SPAWN_INITIAL_SEC * Constant.TIME_SLOW_SCALE
	# Countdown and then start the game
	Game.pause_input()
	show_banner.emit(0, Constant.BANNER_TEXT_READY, Constant.BANNER_TEXT_SET)
	await Util.delay(Constant.BANNER_SHOW_SEC * Constant.TIME_SLOW_SCALE)
	Game.unpause_input()


# Called at a fixed rate. 'delta' is the elapsed time since the previous frame.
func _physics_process(_delta: float) -> void:
	# Check if it's time to spawn a gem
	_seconds_until_next_gem -= _delta
	if not is_over and _seconds_until_next_gem <= 0:
		_seconds_until_next_gem = Constant.GEM_SPAWN_EVERY_SEC
		spawn_gem.emit()
	# Check if it's time to spawn a pickup
	_seconds_until_next_pickup -= _delta
	if not is_over and _seconds_until_next_pickup <= 0:
		_seconds_until_next_pickup = Constant.PICKUP_SPAWN_EVERY_SEC
		spawn_pickup.emit(Game.InventoryItemType.PROJECTILE) # FUTURE: other types of pickups
	pass


# Slow down time
func  _do_time_slow() -> void:
	var tween := create_tween()
	tween.tween_property(Engine, "time_scale", Constant.TIME_SLOW_SCALE, Constant.TIME_TWEEN_SLOW_DURATION)
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_QUAD)


# Return to normal time
func _do_time_norm() -> void:
	var tween := create_tween()
	tween.tween_property(Engine, "time_scale", 1.0, Constant.TIME_TWEEN_NORM_DURATION)
	tween.set_ease(Tween.EASE_IN)
	tween.set_trans(Tween.TRANS_QUAD)


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
		_do_outcome(Game.Result.PLAYER_1_WINS)
		return true
	elif Game.player_score[2] == Constant.PLAYER_SCORE_VICTORY:
		_do_outcome(Game.Result.PLAYER_2_WINS)
		return true
	elif Game.player_score[1] == Constant.PLAYER_SCORE_VICTORY and Game.player_score[2] == Constant.PLAYER_SCORE_VICTORY:
		_do_outcome(Game.Result.DRAW)
		return true

	var tree: SceneTree = get_tree()
	if not tree:
		return false
	var total_gems: int                 = tree.get_node_count_in_group(Game.GEM_GROUP)
	var total_gem_candidate_blocks: int = 0
	var blocks: Array[Node]             = tree.get_nodes_in_group(Game.BLOCK_GROUP)
	for block in blocks:
		if block.is_empty():
			total_gem_candidate_blocks += 1
	if total_gems == 0 and total_gem_candidate_blocks == 0:
		if Game.player_score[1]  > Game.player_score[2]:
			_do_outcome(Game.Result.PLAYER_1_WINS)
			return true
		elif Game.player_score[2] > Game.player_score[1]:
			_do_outcome(Game.Result.PLAYER_2_WINS)
			return true
		else:
			_do_outcome(Game.Result.DRAW)
			return true

	return false


func _do_outcome(result: Result) -> void:
	if is_over:
		return
	outcome.emit(result)
	pause_input()
	is_over = true
	match result:
		Result.PLAYER_1_WINS:
			show_banner.emit(1, Constant.BANNER_TEXT_VICTORY, "")
		Result.PLAYER_2_WINS:
			show_banner.emit(2, Constant.BANNER_TEXT_VICTORY, "")
		Result.DRAW:
			show_banner.emit(0, Constant.BANNER_TEXT_DRAW, "")
	await Util.delay(Constant.BANNER_SHOW_FINAL_SEC * Constant.TIME_SLOW_SCALE)
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


func _on_player_did_collect_item(player_num: int, type: InventoryItemType) -> void:
	print("[GAME] Player %d collected pickup: %s" % [player_num, Game.get_inventory_item_name(type)])
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


# Table / Couch mode are two separate builds #150 #126
func _compute_mode() -> Mode:
	if OS.has_feature("couch_mode"):
		return Mode.COUCH
	if OS.has_feature("editor"):
		return Mode.COUCH
	else:
		return Mode.TABLE
