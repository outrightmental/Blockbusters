extends Node2D

# Preloaded Scenes
const ship_scene: PackedScene  = preload('res://models/player/ship.tscn')
const home_scene: PackedScene  = preload('res://models/player/home.tscn')
const score_scene: PackedScene = preload('res://models/hud/hud_score.tscn')
const block_scene: PackedScene = preload('res://models/block/block.tscn')
const banner_scene: PackedScene = preload('res://models/hud/hud_banner.tscn')
# References to player homes
@onready var player_home_1 = $HomePlayer1
@onready var player_home_2 = $HomePlayer2

# Variables
var grid: Dictionary                     = {}
var mesh: Dictionary                     = {}
var block_count: int                     = 0
var started_at_ticks_msec: int           = 0
var spawn_next_gem_at_msec: int          = 0
var spawn_next_pickup_at_msec: int   = 0
var gem_dont_spawn_until_ticks_msec: int = 0
var is_game_over: bool                   = false


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	started_at_ticks_msec = Time.get_ticks_msec()
	spawn_next_gem_at_msec = started_at_ticks_msec + int(Constant.SHOW_MODAL_SEC * 1000)
	spawn_next_pickup_at_msec = started_at_ticks_msec + int(Constant.PICKUP_SPAWN_EVERY_MSEC)
	# Setup the board based on the current input mode
	_setup()
	InputManager.input_mode_updated.connect(_setup)
	# Create the board before resetting the game (so that scores update on the board)
	_create_board()
	# Reset the game
	Game.reset_game.emit()
	# Connect the game over signals after resetting the game
	Game.player_score_updated.connect(_check_for_game_over)
	Game.projectile_count_updated.connect(_check_for_game_over)
	Game.player_did_collect_gem.connect(_on_player_collect_gem)
	Game.player_enabled.connect(_on_player_enabled)
	# Countdown and then start the game
	_pause_game()
	_show_banner(0, "READY...", "SET...")
	await Util.delay(Constant.SHOW_MODAL_SEC)
	_unpause_game()
	pass


# Setup the UI based on the current input mode		
func _setup() -> void:
	match InputManager.mode:
		InputManager.Mode.TABLE:
			$HudPlayer1/ScoreP1.transform = Transform2D(PI/2, Vector2(31, 288))
			$HudPlayer1/EnergyP1.transform = Transform2D(PI/2, Vector2(31, 388))
			$HudPlayer1/InventoryP1.transform = Transform2D(PI/2, Vector2(31, 88))
			$HudPlayer2/ScoreP2.transform = Transform2D(-PI/2, Vector2(993, 288))
			$HudPlayer2/EnergyP2.transform = Transform2D(-PI/2, Vector2(993, 188))
			$HudPlayer2/InventoryP2.transform = Transform2D(-PI/2, Vector2(993, 488))
		InputManager.Mode.COUCH:
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
		spawn_next_gem_at_msec = Time.get_ticks_msec() + Constant.GEM_SPAWN_EVERY_MSEC
		_spawn_gem()
	# Check if it's time to spawn a pickup
	if Time.get_ticks_msec() >= spawn_next_pickup_at_msec:
		spawn_next_pickup_at_msec = Time.get_ticks_msec() + Constant.PICKUP_SPAWN_EVERY_MSEC
		_spawn_pickup()
	pass


# Show the game over modal for some time, then go back to main screen
func _game_over(result: Game.Result) -> void:
	if is_game_over:
		return
	is_game_over = true
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
func _show_banner(player_num: int, message:String, message_2:String = "") -> void:
	var viewport_size: Vector2 = get_viewport().get_visible_rect().size
	match InputManager.mode:
		InputManager.Mode.COUCH:
			_spawn_banner(player_num, viewport_size.x / 2, viewport_size.y / 2, 0, 1, message, message_2)
		InputManager.Mode.TABLE:
			_spawn_banner(player_num, viewport_size.x * 0.75, viewport_size.y / 2, -90, 0.6, message, message_2)
			_spawn_banner(player_num, viewport_size.x * 0.25, viewport_size.y / 2, 90, 0.6, message, message_2)

# Spawn a banner at the given position
func _spawn_banner(player_num: int, x: float, y:float, _rotation_degrees:float, _scale:float, message:String, message_2: String = "") -> void:
	var banner: Node        = banner_scene.instantiate()
	banner.scale = Vector2(_scale, _scale)
	banner.position = Vector2(x,y)
	banner.rotation_degrees = _rotation_degrees
	banner.player_num = player_num
	banner.message = message
	banner.message_2 = message_2
	banner.z_index = 1000
	self.add_child(banner)


# Check for game over, e.g. when score or gem count is updated
# ---
# The game is a stalemate if a state is reached where no player can win based on the number of gems left in play, 
# ---
# The game is a stalemate if neither player can afford to launch a projectile, and there are not enough free gems (gems 
# not enclosed in blocks) for either player to win, BUT deciding stalemate based on whether players don't have enough 
# points to launch projectiles is tricky, because it's possible that a player launched their last projectile and is in 
# fact going to win after that projectile explodes, so we need to also test that no projectiles are in play
func _check_for_game_over() -> void:
	if Game.player_score[1] == Constant.PLAYER_SCORE_VICTORY:
		_game_over(Game.Result.PLAYER_1_WINS)
		return
	elif Game.player_score[2] == Constant.PLAYER_SCORE_VICTORY:
		_game_over(Game.Result.PLAYER_2_WINS)
		return
	elif Game.player_score[1] == Constant.PLAYER_SCORE_VICTORY and Game.player_score[2] == Constant.PLAYER_SCORE_VICTORY:
		_game_over(Game.Result.DRAW)
		return

	var total_gems: int                 = get_tree().get_node_count_in_group(Game.GEM_GROUP)
	var total_gem_candidate_blocks: int = 0
	var blocks: Array[Node]             = get_tree().get_nodes_in_group(Game.BLOCK_GROUP)
	for block in blocks:
		if block is Block and block.freeze:
			total_gem_candidate_blocks += 1
	if total_gems == 0 and total_gem_candidate_blocks == 0:
		if Game.player_score[1]  > Game.player_score[2]:
			_game_over(Game.Result.PLAYER_1_WINS)
			return
		elif Game.player_score[2] > Game.player_score[1]:
			_game_over(Game.Result.PLAYER_2_WINS)
			return
		else:
			_game_over(Game.Result.DRAW)
			return


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
			$HudPlayer1.modulate.a = 1.0 if enabled else Constant.PLAYER_HUD_DISABLED_ALPHA
		2:
			$HudPlayer2.modulate.a = 1.0 if enabled else Constant.PLAYER_HUD_DISABLED_ALPHA


# Create the board with blocks and gems, and spawn player homes, ships, and scores
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
	var home_positions: Array[Vector2] = [player_home_1.position, player_home_2.position, player_ship_1.position, player_ship_2.position]

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
		if _is_clear_of_all(Constant.BOARD_HOME_CLEARANCE_RADIUS, _grid_position(x, y), home_positions):
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
	if get_tree().get_node_count_in_group(Game.GEM_GROUP) >= Constant.GEM_MAX_COUNT:
		return
	var block = _get_block_spawn_candidate()
	if block != null:
		block.add_gem()
	else:
		_check_for_game_over()


func _spawn_pickup() -> void:
	if get_tree().get_node_count_in_group(Game.PICKUP_GROUP) >= Constant.PICKUP_MAX_COUNT:
		return
	var block = _get_block_spawn_candidate()
	if block != null:
		block.add_pickup()
	else:
		_check_for_game_over()

	
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


# Pause game, guarding against the condition that the tree has been unloaded since the calling thread arrived here
func _pause_game() -> void:
	InputManager.paused = true


# Unpause game, guarding against the condition that the tree has been unloaded since the calling thread arrived here
func _unpause_game() -> void:
	InputManager.paused = false


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
