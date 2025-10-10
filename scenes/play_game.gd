extends Node2D

# Preloaded Scenes
const ship_scene: PackedScene  = preload('res://models/player/ship.tscn')
const goal_scene: PackedScene  = preload('res://models/player/goal.tscn')
const score_scene: PackedScene = preload('res://models/hud/hud_score.tscn')
const block_scene: PackedScene  = preload('res://models/block/block.tscn')
const banner_scene: PackedScene = preload('res://models/hud/hud_banner.tscn')
# References to player goals
@onready var player_goal_1 = $GoalPlayer1
@onready var player_goal_2 = $GoalPlayer2
@onready var debug_text = $DebugText

# Variables
var grid: Dictionary                     = {}
var mesh: Dictionary                     = {}
var block_count: int                     = 0
var started_at_ticks_msec: int           = 0
var spawn_next_gem_at_msec: int          = 0
var spawn_next_pickup_at_msec: int       = 0
var gem_dont_spawn_until_ticks_msec: int = 0


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	started_at_ticks_msec = Time.get_ticks_msec()
	spawn_next_gem_at_msec = started_at_ticks_msec + int(Constant.SHOW_MODAL_SEC * 1000)
	spawn_next_pickup_at_msec = spawn_next_gem_at_msec + int(Constant.PICKUP_SPAWN_INITIAL_SEC * 1000)
	# Setup the board based on the current input mode
	_setup()
	Game.input_mode_updated.connect(_setup)
	# Create the board before resetting the game (so that scores update on the board)
	_create_board()
	# Reset the game
	Game.reset_game.emit()
	# Connect the game over signals after resetting the game
	Game.player_did_collect_gem.connect(_on_player_collect_gem)
	Game.player_enabled.connect(_on_player_enabled)
	Game.over.connect(_on_game_over)
	# Countdown and then start the game
	Game.pause_input()
	_show_banner(0, "READY...", "SET...")
	await Util.delay(Constant.SHOW_MODAL_SEC)
	Game.unpause_input()
	# Show debug text
	if OS.has_feature("editor"):
		Game.show_debug_text.connect(_on_show_debug_text)
		debug_text.show()
	else:
		debug_text.hide()
	pass


# Setup the UI based on the current input mode		
func _setup() -> void:
	match Game.mode:
		Game.Mode.TABLE:
			$HudPlayer1/ScoreP1.transform = Transform2D(PI/2, Vector2(31, 288))
			$HudPlayer1/EnergyP1.transform = Transform2D(PI/2, Vector2(31, 388))
			$HudPlayer1/InventoryP1.transform = Transform2D(PI/2, Vector2(31, 88))
			$HudPlayer2/ScoreP2.transform = Transform2D(-PI/2, Vector2(993, 288))
			$HudPlayer2/EnergyP2.transform = Transform2D(-PI/2, Vector2(993, 188))
			$HudPlayer2/InventoryP2.transform = Transform2D(-PI/2, Vector2(993, 488))
		Game.Mode.COUCH:
			$HudPlayer1/ScoreP1.transform = Transform2D(0, Vector2(31, 288))
			$HudPlayer1/EnergyP1.transform = Transform2D(-PI/2, Vector2(31, 488))
			$HudPlayer1/InventoryP1.transform = Transform2D(PI/2, Vector2(31, 88))
			$HudPlayer2/ScoreP2.transform = Transform2D(0, Vector2(993, 288))
			$HudPlayer2/EnergyP2.transform = Transform2D(-PI/2, Vector2(993, 488))
			$HudPlayer2/InventoryP2.transform = Transform2D(PI/2, Vector2(1, -1), 0, Vector2(993, 88))


# Called at a fixed rate. 'delta' is the elapsed time since the previous frame.
func _physics_process(_delta: float) -> void:
	# Check if it's time to spawn a gem
	if Time.get_ticks_msec() >= spawn_next_gem_at_msec:
		spawn_next_gem_at_msec = Time.get_ticks_msec() + int(Constant.GEM_SPAWN_EVERY_SEC * 1000)
		_spawn_gem()
	# Check if it's time to spawn a pickup
	if Time.get_ticks_msec() >= spawn_next_pickup_at_msec:
		spawn_next_pickup_at_msec = Time.get_ticks_msec() + int(Constant.PICKUP_SPAWN_EVERY_SEC * 1000)
		_spawn_pickup(Game.InventoryItemType.PROJECTILE) # FUTURE: other types of pickups
	pass


# Show the game over modal for some time, then go back to main screen
func _on_game_over(result: Game.Result) -> void:
	match result:
		Game.Result.PLAYER_1_WINS:
			_show_banner(1, "VICTORY!")
		Game.Result.PLAYER_2_WINS:
			_show_banner(2, "VICTORY!")
		Game.Result.DRAW:
			_show_banner(0, "DRAW")
	await Util.delay(Constant.SHOW_MODAL_SEC)
	_goto_scene('res://scenes/main.tscn')
	pass


# Spawn a banner at the given position
func _show_banner(player_num: int, message: String, message_2: String = "") -> void:
	var viewport_size: Vector2 = get_viewport().get_visible_rect().size
	match Game.mode:
		Game.Mode.COUCH:
			_spawn_banner(player_num, viewport_size.x / 2, viewport_size.y / 2, 0, 1, message, message_2)
		Game.Mode.TABLE:
			_spawn_banner(player_num, viewport_size.x * 0.75, viewport_size.y / 2, -90, 0.6, message, message_2)
			_spawn_banner(player_num, viewport_size.x * 0.25, viewport_size.y / 2, 90, 0.6, message, message_2)
	Game.pause_input_tools()
	await Util.delay(Constant.SHOW_MODAL_SEC)
	Game.unpause_input()

# Spawn a banner at the given position
func _spawn_banner(player_num: int, x: float, y: float, _rotation_degrees: float, _scale: float, message: String, message_2: String = "") -> void:
	var banner: Node = banner_scene.instantiate()
	banner.scale = Vector2(_scale, _scale)
	banner.position = Vector2(x, y)
	banner.rotation_degrees = _rotation_degrees
	banner.player_num = player_num
	banner.message = message
	banner.message_2 = message_2
	banner.z_index = 1000
	self.add_child(banner)


# Called when a player collects a gem
func _on_player_collect_gem(player_num: int) -> void:
	if Game.player_score[player_num] < Constant.PLAYER_SCORE_VICTORY:
		gem_dont_spawn_until_ticks_msec = Time.get_ticks_msec() + Constant.GEM_SPAWN_AFTER_SCORING_DELAY_MSEC
		_show_banner(player_num, "GOOOAAAAL!")
	else:
		gem_dont_spawn_until_ticks_msec = Time.get_ticks_msec() + 999999
	print ("[GAME] Player collected a gem")


# When ship is disabled, player HUD also appears disabled #155
func _on_player_enabled(player_num: int, enabled: bool) -> void:
	match player_num:
		1:
			$HudPlayer1/ScoreP1.modulate.a = 1.0 if enabled else Constant.PLAYER_HUD_DISABLED_ALPHA
			$HudPlayer1/InventoryP1.modulate.a = 1.0 if enabled else Constant.PLAYER_HUD_DISABLED_ALPHA
		2:
			$HudPlayer2/ScoreP2.modulate.a = 1.0 if enabled else Constant.PLAYER_HUD_DISABLED_ALPHA
			$HudPlayer2/InventoryP2.modulate.a = 1.0 if enabled else Constant.PLAYER_HUD_DISABLED_ALPHA


# Create the board with blocks and gems, and spawn player goals, ships, and scores
# Instantiate a models/ship/ship.gd for each player, so set player_num = 1 or 2 respectively
# Player 1 is 10% in from the left, vertical center, and Player 2 is 10% in from the right, vertical center.
#
# Before generating the board grid, generate a Gradient Mesh -- see https://github.com/outrightmental/Blockbusters/issues/30
# A block will only be placed if that block is above GRID_MESH_THRESHOLD in the gradient mesh
#
func _create_board() -> void:
	var block_attempt_count: int = 0
	_generate_mesh(floor(randf() * Constant.BOARD_SEED_MAX))
	var viewport_size: Vector2         = get_viewport().get_visible_rect().size
	var player_ship_1: Ship            = _spawn_player_ship(1, Vector2(viewport_size.x * 0.1, viewport_size.y * 0.5), 0)
	var player_ship_2: Ship            = _spawn_player_ship(2, Vector2(viewport_size.x * 0.9, viewport_size.y * 0.5), PI)
	var goal_positions: Array[Vector2] = [player_goal_1.position, player_goal_2.position, player_ship_1.position, player_ship_2.position]

	while block_count < Constant.BOARD_BLOCK_COUNT_MAX and block_attempt_count < Constant.BOARD_BLOCK_ATTEMPT_MAX:
		block_attempt_count += 1
		var x: int = randi() % Constant.BOARD_GRID_COLS
		var y: int = randi() % Constant.BOARD_GRID_ROWS
		if not grid.has(x):
			grid[x] = {}
		if grid[x].has(y):
			continue
		if not mesh.has(x):
			continue
		if not mesh[x].has(y):
			continue
		if mesh[x][y] < Constant.BOARD_GRID_MESH_THRESHOLD:
			continue
		if _is_clear_of_all(Constant.BOARD_GOAL_CLEARANCE_RADIUS, _grid_position(x, y), goal_positions):
			block_count += 1
			grid[x][y] = true

	for x in range(Constant.BOARD_GRID_COLS):
		for y in range(Constant.BOARD_GRID_ROWS):
			if grid.has(x) and grid[x].has(y):
				_spawn_block(_grid_position(x, y))


func _is_clear_of_all(distance: int, source: Vector2, targets: Array[Vector2]) -> bool:
	for target in targets:
		if not _is_clear_of(distance, source, target):
			return false
	return true


func _is_clear_of(distance: int, source: Vector2, target: Vector2) -> bool:
	return source.distance_to(target) >= distance


func _grid_position(x: int, y: int) -> Vector2:
	# Convert grid coordinates to world coordinates
	return Vector2( Constant.BOARD_GRID_COLS_MARGIN * Constant.BOARD_BLOCK_SIZE + Constant.BOARD_BLOCK_CENTER + x * Constant.BOARD_BLOCK_SIZE, Constant.BOARD_GRID_ROWS_MARGIN * Constant.BOARD_BLOCK_SIZE +Constant.BOARD_BLOCK_CENTER + y * Constant.BOARD_BLOCK_SIZE)


# Spawn a player ship at the given position and rotation
func _spawn_player_ship(num: int, start_position: Vector2, start_rotation: float) -> Ship:
	var ship: Ship = ship_scene.instantiate()
	ship.position = start_position
	ship.player_num = num
	ship.rotation = start_rotation
	self.add_child(ship)
	return ship


func _spawn_block(start_position: Vector2) -> Node:
	var block: Block = block_scene.instantiate()
	block.position = start_position
	self.add_child(block)
	return block


func _spawn_gem() -> void:
	if Game.is_over:
		return
	if get_tree().get_node_count_in_group(Game.GEM_GROUP) >= Constant.GEM_MAX_COUNT:
		return
	var block: Block = _get_block_spawn_candidate()
	if block != null:
		block.add_gem()
	else:
		Game.gem_spawned.emit()


func _spawn_pickup(type: Game.InventoryItemType) -> void:
	if Game.is_over:
		return
	if get_tree().get_node_count_in_group(Game.PICKUP_GROUP) >= Constant.PICKUP_MAX_COUNT:
		return
	var block: Block = _get_block_spawn_candidate()
	if block != null:
		block.add_pickup(type)
	else:
		Game.pickup_spawned.emit(type)


# Get a random block that may have something added to it
func _get_block_spawn_candidate() -> Block:
	var candidates: Array[Block]
	for block in get_tree().get_nodes_in_group(Game.BLOCK_GROUP):
		if block.can_add_item():
			candidates.append(block)
	if candidates.size() > 0:
		# Randomly select a block to spawn a pickup in
		return candidates[randi() % candidates.size()]
	return null


# Goto a scene, guarding against the condition that the tree has been unloaded since the calling thread arrived here
func _goto_scene(path: String) -> void:
	if get_tree():
		get_tree().change_scene_to_file(path)
		
		
# Show debug text
func _on_show_debug_text(text: String) -> void:
	debug_text.text = text


# ------------------------------------------------------------------ #
# Pertaining to generating a gradient mesh                           #
# ------------------------------------------------------------------ #

func _modulate(x: float, max_val: float, range_val: float) -> float:
	return 2.0 * range_val * (fmod(x, max_val) / max_val) - range_val


func _generate_mesh(_seed: int) -> void:
	# Factors between −1 and 1
	var f1 := _modulate(_seed, Constant.BOARD_SEED_F1, 1.0)
	var f2 := _modulate(_seed, Constant.BOARD_SEED_F2, 1.0)
	var f3 := _modulate(_seed, Constant.BOARD_SEED_F3, 1.0)
	var f4 := _modulate(_seed, Constant.BOARD_SEED_F4, 1.0)
	var f5 := _modulate(_seed, Constant.BOARD_SEED_F5, 1.0)
	var f6 := _modulate(_seed, Constant.BOARD_SEED_F6, 1.0)

	for x in range(Constant.BOARD_GRID_COLS):
		mesh[x] = {}
		for y in range(Constant.BOARD_GRID_ROWS):
			var r  := float(float(x * Constant.BOARD_GRID_COLS + y) / Constant.BOARD_GRID_COUNT_MAX)
			var g1 := cos(f1 * PI * x / Constant.BOARD_GRID_COLS)
			var g2 := sin(f2 * PI * y / Constant.BOARD_GRID_ROWS)
			var g3 := sin(f3 * PI * r)
			var g4 := sin(f4 * PI * r)
			var g5 := sin(f5 * PI * r)
			var g6 := sin(f6 * PI * r)
			var z  := sin(PI * wrap(g1 + g2 + g3 * g4 + g5 * g6, 0.0, 1.0))
			mesh[x][y] = z
