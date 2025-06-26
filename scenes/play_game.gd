extends Node2D

# Enum for whether a grid square is empty or block
enum GridType {
	BLOCK,
}
# Enum for whether Player 1 wins, Player 2 wins, or a draw
enum GameResult {
	PLAYER_1_WINS,
	PLAYER_2_WINS,
	DRAW,
}
# Constants
# Spawn blocks in a grid pattern, 32 blocks wide and 18 blocks tall, starting at (16, 16) and spaced 32 pixels apart
# The blocks are32x32 pixels, so the grid is 1024x576 pixels
const GRID_COLS: int                  = 28
const GRID_COUNT_MAX: int             = GRID_COLS * GRID_ROWS
const GRID_MARGIN: int                = 2
const GRID_ROWS: int                  = 14
const HOME_CLEARANCE_RADIUS: int      = 130
const BLOCK_CENTER: int               = floori(BLOCK_SIZE * 0.5)
const BLOCK_COUNT_MAX: int            = floori(GRID_COUNT_MAX * BLOCK_COUNT_RATIO)
const BLOCK_ATTEMPT_MAX: int          = 1_000_000 # max attempts to place a block
const BLOCK_COUNT_RATIO: float        = 0.3 # ratio of the grid that is filled with blocks
const BLOCK_SIZE: int                 = 32
const GEM_SPAWN_INITIAL_MSEC: int     = 1000 # initial delay before spawning the first gem
const GEM_SPAWN_EVERY_MSEC: int       = 5000 # delay between spawning gems
const GEM_MAX_COUNT: int              = 5
const GAME_START_COUNTER_DELAY: float = 1.0
const GAME_DRAW_MODAL_DELAY: float    = 1.0 # in a draw situation, wait before showing the game over modal
const GAME_OVER_DELAY: float          = 2.5
const GAME_CHECK_OVER_DELAY: float    = 0.3 # tiny delay before checking game over state, to allow projectiles to finish
const MODAL_NEUTRAL_TEXT_COLOR: Color = Color(1, 1, 1, 1)
const GRID_MESH_THRESHOLD: float      = 0.62
# Preloaded Scenes
const ship_scene: PackedScene  = preload('res://models/player/ship.tscn')
const home_scene: PackedScene  = preload('res://models/player/home.tscn')
const score_scene: PackedScene = preload('res://models/player/score.tscn')
const block_scene: PackedScene = preload('res://models/block/block.tscn')
# References to player homes
@onready var player_home_1 = $HomePlayer1
@onready var player_home_2 = $HomePlayer2

# Variables
var grid: Dictionary            = {}
var mesh: Dictionary            = {}
var block_count: int            = 0
var started_at_ticks_msec: int  = 0
var spawn_next_gem_at_msec: int = 0
# Signal that never happens, in case the tree is unloaded
signal never


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	started_at_ticks_msec = Time.get_ticks_msec()
	spawn_next_gem_at_msec = started_at_ticks_msec + GEM_SPAWN_INITIAL_MSEC
	# Create the board before resetting the game (so that scores update on the board)
	_create_board()
	# Reset the game
	Game.reset_game.emit()
	# Connect the game over signals after resetting the game
	Game.score_updated.connect(_check_for_game_over)
	Game.gem_count_updated.connect(_check_for_game_over)
	Game.gem_count_updated.connect(_reset_gem_spawn_time)
	Game.projectile_count_updated.connect(_check_for_game_over)
	# Countdown and then start the game
	AudioManager.create_audio(SoundEffectSetting.SOUND_EFFECT_TYPE.GAME_START)
	_show_modal("Ready...", MODAL_NEUTRAL_TEXT_COLOR)
	await _delay(GAME_START_COUNTER_DELAY)
	_show_modal("Set...", MODAL_NEUTRAL_TEXT_COLOR)
	await _delay(GAME_START_COUNTER_DELAY)
	_hide_modal()
	pass


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	# Check if it's time to spawn a gem
	if Time.get_ticks_msec() >= spawn_next_gem_at_msec:
		_spawn_gem()
	pass


# Show the game over modal for some time, then go back to main screen
func _game_over(result: GameResult) -> void:
	match result:
		GameResult.PLAYER_1_WINS:
			_show_modal("Player 1 wins!", Config.PLAYER_COLORS[1][0])
		GameResult.PLAYER_2_WINS:
			_show_modal("Player 2 wins!", Config.PLAYER_COLORS[2][0])
		GameResult.DRAW:
			await _delay(GAME_DRAW_MODAL_DELAY)
			_show_modal("Draw!", MODAL_NEUTRAL_TEXT_COLOR)
	await _delay(GAME_OVER_DELAY)
	_hide_modal()
	_goto_scene('res://scenes/main.tscn')
	pass


# Show the modal with the given text and color
func _show_modal(text: String, color: Color) -> void:
	$Modal.show()
	$Modal/Text1.text = text
	$Modal/Text1.set("theme_override_colors/default_color", color)
	$Modal/Text2.text = text
	$Modal/Text2.set("theme_override_colors/default_color", color)
	_pause_game()


# Hide the modal
func _hide_modal() -> void:
	$Modal.hide()
	_unpause_game()


# Check for game over, e.g. when score or gem count is updated
# ---
# The game is a stalemate if a state is reached where no player can win based on the number of gems left in play, 
# ---
# The game is a stalemate if neither player can afford to launch a projectile, and there are not enough free gems (gems 
# not enclosed in blocks) for either player to win, BUT deciding stalemate based on whether players don't have enough 
# points to launch projectiles is tricky, because it's possible that a player launched their last projectile and is in 
# fact going to win after that projectile explodes, so we need to also test that no projectiles are in play
func _check_for_game_over() -> void:
	await _delay(GAME_CHECK_OVER_DELAY)
	if Game.score[1] == Config.PLAYER_VICTORY_SCORE:
		_game_over(GameResult.PLAYER_1_WINS)
		return
	if Game.score[2] == Config.PLAYER_VICTORY_SCORE:
		_game_over(GameResult.PLAYER_2_WINS)
		return
	if Game.score[1] == Config.PLAYER_VICTORY_SCORE and Game.score[2] == Config.PLAYER_VICTORY_SCORE:
		_game_over(GameResult.DRAW)
		return


# Reset the gem spawn time 
func _reset_gem_spawn_time() -> void:
	spawn_next_gem_at_msec = Time.get_ticks_msec() + GEM_SPAWN_EVERY_MSEC


# Create the board with blocks and gems, and spawn player homes, ships, and scores
# Instantiate a models/ship/ship.gd for each player, so set player_num = 1 or 2 respectively
# Player 1 is 10% in from the left, vertical center, and Player 2 is 10% in from the right, vertical center.
#
# Before generating the board grid, generate a Gradient Mesh -- see https://github.com/outrightmental/Blasteroids/issues/30
# A block will only be placed if that block is above GRID_MESH_THRESHOLD in the gradient mesh
#
func _create_board() -> void:
	var block_attempt_count: int = 0
	_generate_mesh(floor(randf() * SEED_MAX))
	var viewport_size: Vector2         = get_viewport().get_visible_rect().size
	var player_ship_1: Ship            = _spawn_player_ship(1, Vector2(viewport_size.x * 0.08, viewport_size.y * 0.5), 0)
	var player_ship_2: Ship            = _spawn_player_ship(2, Vector2(viewport_size.x * 0.92, viewport_size.y * 0.5), PI)
	var home_positions: Array[Vector2] = [player_home_1.position, player_home_2.position, player_ship_1.position, player_ship_2.position]

	while block_count < BLOCK_COUNT_MAX and block_attempt_count < BLOCK_ATTEMPT_MAX:
		block_attempt_count += 1
		var x: int = randi() % GRID_COLS
		var y: int = randi() % GRID_ROWS
		if not grid.has(x):
			grid[x] = {}
		if grid[x].has(y):
			continue
		if not mesh.has(x):
			continue
		if not mesh[x].has(y):
			continue
		if mesh[x][y] < GRID_MESH_THRESHOLD:
			continue
		if _is_clear_of_all(HOME_CLEARANCE_RADIUS, _grid_position(x, y), home_positions):
			block_count += 1
			grid[x][y] = GridType.BLOCK

	for x in range(GRID_COLS):
		for y in range(GRID_ROWS):
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
	return Vector2( GRID_MARGIN * BLOCK_SIZE + BLOCK_CENTER + x * BLOCK_SIZE, GRID_MARGIN * BLOCK_SIZE +BLOCK_CENTER + y * BLOCK_SIZE)


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
	if get_tree().get_node_count_in_group(Game.GEM_GROUP) >= GEM_MAX_COUNT:
		return
	spawn_next_gem_at_msec = Time.get_ticks_msec() + GEM_SPAWN_EVERY_MSEC
	var blocks: Array[Node] = get_tree().get_nodes_in_group(Game.BLOCK_GROUP)
	if blocks.size() > 0:
		# Randomly select a block to spawn a gem in
		var random_block: Node = blocks[randi() % blocks.size()]
		if random_block is Block and random_block.has_gem == false:
			random_block.add_gem()
			Game.spawned_gem.emit()
	else:
		push_error("No blocks found to spawn a gem in!")


# Goto a scene, guarding against the condition that the tree has been unloaded since the calling thread arrived here
func _goto_scene(path: String) -> void:
	if get_tree():
		get_tree().change_scene_to_file(path)


# Delay, guarding against the condition that the tree has been unloaded since the calling thread arrived here
func _delay(seconds: float) -> Signal:
	if get_tree():
		return get_tree().create_timer(seconds).timeout
	else:
		return never


# Pause game, guarding against the condition that the tree has been unloaded since the calling thread arrived here
func _pause_game() -> void:
	if get_tree():
		get_tree().paused = true


# Unpause game, guarding against the condition that the tree has been unloaded since the calling thread arrived here
func _unpause_game() -> void:
	if get_tree():
		get_tree().paused = false


# ------------------------------------------------------------------ #
# Pertaining to generating a gradient mesh                           #
# ------------------------------------------------------------------ #
const PI: float             = 3.14159
const SEED_MAX: int         = 1_000_000_000
const SEED_F1: int          = 18_285_756
const SEED_F2: int          = 89_074_356
const SEED_F3: int          = 973_523_665
const SEED_F4: int          = 167_653_873
const SEED_F5: int          = 423_587_300
const SEED_F6: int          = 798_647_400
const DEMO_REPETITIONS: int = 1_000


func _modulate(x: float, max_val: float, range_val: float) -> float:
	return 2.0 * range_val * (fmod(x, max_val) / max_val) - range_val


func _generate_mesh(_seed: int) -> void:
	# Factors between −1 and 1
	var f1 := _modulate(_seed, SEED_F1, 1.0)
	var f2 := _modulate(_seed, SEED_F2, 1.0)
	var f3 := _modulate(_seed, SEED_F3, 1.0)
	var f4 := _modulate(_seed, SEED_F4, 1.0)
	var f5 := _modulate(_seed, SEED_F5, 1.0)
	var f6 := _modulate(_seed, SEED_F6, 1.0)

	for x in range(GRID_COLS):
		mesh[x] = {}
		for y in range(GRID_ROWS):
			var r  := float(x * GRID_COLS + y) / GRID_COUNT_MAX
			var g1 := cos(f1 * PI * x / GRID_COLS)
			var g2 := sin(f2 * PI * y / GRID_ROWS)
			var g3 := sin(f3 * PI * r)
			var g4 := sin(f4 * PI * r)
			var g5 := sin(f5 * PI * r)
			var g6 := sin(f6 * PI * r)
			var z  := sin(PI * wrap(g1 + g2 + g3 * g4 + g5 * g6, 0.0, 1.0))
			mesh[x][y] = z
