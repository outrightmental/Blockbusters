extends Node2D

# Enum for whether a grid square is empty, block, or gem
enum GridType {
	BLOCK,
	GEM,
}
# Enum for whether Player 1 wins, Player 2 wins, or a draw
enum GameResult {
	PLAYER_1_WINS,
	PLAYER_2_WINS,
	DRAW,
}
# Constants
# Spawn blocks in a grid pattern, 32 blocks wide and 18 blocks tall, starting at (16, 16) and spaced 32 pixels apart
# The blocks are 32x32 pixels, so the grid is 1024x576 pixels
const GRID_COLS: int                  = 32
const GRID_COUNT_MAX: int             = GRID_COLS * GRID_ROWS
const GRID_ROWS: int                  = 18
const HOME_CLEARANCE_RADIUS: int      = 130
const BLOCK_CENTER: int               = floori(BLOCK_SIZE * 0.5)
const BLOCK_COUNT_MAX: int            = floori(GRID_COUNT_MAX * BLOCK_COUNT_RATIO)
const BLOCK_COUNT_RATIO: float        = 0.3 # ratio of the grid that is filled with blocks
const BLOCK_SIZE: int                 = 32
const GEM_COUNT_RATIO: float          = 0.05 # ratio of the grid that is filled with gems
const GAME_START_COUNTER_DELAY: float = 1.0
const GAME_DRAW_MODAL_DELAY: float    = 1.0 # in a draw situation, wait before showing the game over modal
const GAME_OVER_DELAY: float          = 2.5
const GAME_CHECK_OVER_DELAY: float    = 0.3 # tiny delay before checking game over state, to allow projectiles to finish
const MODAL_NEUTRAL_TEXT_COLOR: Color = Color(1, 1, 1, 1)
const INITIAL_GEMS_IN_BLOCKS: int     = floori(GRID_COUNT_MAX * GEM_COUNT_RATIO)
# Variables
var grid: Dictionary           = {}
var block_count: int           = 0
var gem_count: int             = 0
var started_at_ticks_msec: int = 0
# Signal that never happens, in case the tree is unloaded
signal never


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	started_at_ticks_msec = Time.get_ticks_msec()
	# Create the board before resetting the game (so that scores update on the board)
	_create_board()
	# Reset the game
	Game.reset_game.emit(INITIAL_GEMS_IN_BLOCKS)
	# Connect the game over signals after resetting the game
	Game.score_updated.connect(_check_for_game_over)
	Game.gem_count_updated.connect(_check_for_game_over)
	Game.projectile_count_updated.connect(_check_for_game_over)
	# Countdown and then start the game
	_show_modal("Ready...", MODAL_NEUTRAL_TEXT_COLOR)
	await _delay(GAME_START_COUNTER_DELAY)
	_show_modal("Set...", MODAL_NEUTRAL_TEXT_COLOR)
	await _delay(GAME_START_COUNTER_DELAY)
	_hide_modal()
	pass


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
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
	$Modal/Text.text = text
	$Modal/Text.set("theme_override_colors/default_color", color)
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
	if Game.score[2] == 0 or Game.score[1] == Config.PLAYER_VICTORY_SCORE:
		_game_over(GameResult.PLAYER_1_WINS)
		return
	if Game.score[1] == 0 or Game.score[2] == Config.PLAYER_VICTORY_SCORE:
		_game_over(GameResult.PLAYER_2_WINS)
		return
	if Game.score[1] == Config.PLAYER_VICTORY_SCORE and Game.score[2] == Config.PLAYER_VICTORY_SCORE:
		_game_over(GameResult.DRAW)
		return

	var total_gems_available            = Game.gems_in_blocks + Game.gems_free
	var min_points_required_for_victory = min(Config.PLAYER_VICTORY_SCORE - Game.score[1], Config.PLAYER_VICTORY_SCORE - Game.score[2])
	if total_gems_available * Config.PLAYER_COLLECT_GEM_VALUE < min_points_required_for_victory:
		_game_over(GameResult.DRAW)

	# the rest of these conditions test whether either player can win based on their ability to launch projectiles or
	# projectiles are in play or there are enough free gems for either player to win
	if Game.projectiles_in_play > 0:
		return
	if Game.player_can_launch_projectile(1) or Game.player_can_launch_projectile(2):
		return
	if Game.gems_free * Config.PLAYER_COLLECT_GEM_VALUE >= min_points_required_for_victory:
		return
	_game_over(GameResult.DRAW)


# Create the board with blocks and gems, and spawn player homes, ships, and scores
# Instantiate a models/ship/ship.gd for each player, so set player_num = 1 or 2 respectively
# Player 1 is 10% in from the left, vertical center, and Player 2 is 10% in from the right, vertical center.
func _create_board() -> void:
	var viewport_size: Vector2 = get_viewport().get_visible_rect().size
	_spawn_player_ship(1, Vector2(viewport_size.x * 0.08, viewport_size.y * 0.5), 0)
	_spawn_player_ship(2, Vector2(viewport_size.x * 0.92, viewport_size.y * 0.5), PI)
	_spawn_player_score(1, Vector2(viewport_size.x * 0.03, viewport_size.y * 0.5), PI/2)
	_spawn_player_score(2, Vector2(viewport_size.x * 0.97, viewport_size.y * 0.5), -PI/2)
	var player_home_1: Home            = _spawn_player_home(1, Vector2(0, viewport_size.y * 0.5), 0)
	var player_home_2: Home            = _spawn_player_home(2, Vector2(viewport_size.x, viewport_size.y * 0.5), PI)
	var home_positions: Array[Vector2] = [player_home_1.position, player_home_2.position]

	while block_count < BLOCK_COUNT_MAX:
		var x: int = randi() % GRID_COLS
		var y: int = randi() % GRID_ROWS
		if not grid.has(x):
			grid[x] = {}
		if grid[x].has(y):
			continue
		if _is_clear_of_all(HOME_CLEARANCE_RADIUS, _grid_position(x, y), home_positions):
			block_count += 1
			if gem_count < INITIAL_GEMS_IN_BLOCKS:
				grid[x][y] = GridType.GEM
				gem_count += 1
			else:
				grid[x][y] = GridType.BLOCK

	for x in range(GRID_COLS):
		for y in range(GRID_ROWS):
			if grid.has(x) and grid[x].has(y):
				_spawn_block(_grid_position(x, y), grid[x][y] == GridType.GEM)


func _is_clear_of_all(distance: int, source: Vector2, targets: Array[Vector2]) -> bool:
	for target in targets:
		if not _is_clear_of(distance, source, target):
			return false
	return true


func _is_clear_of(distance: int, source: Vector2, target: Vector2) -> bool:
	return source.distance_to(target) >= distance


func _grid_position(x: int, y: int) -> Vector2:
	# Convert grid coordinates to world coordinates
	return Vector2( BLOCK_CENTER + x * BLOCK_SIZE, BLOCK_CENTER + y * BLOCK_SIZE)


# Spawn a player ship at the given position and rotation
func _spawn_player_ship(num: int, start_position: Vector2, start_rotation: float) -> Ship:
	var ship_scene: Ship = preload('res://models/player/ship.tscn').instantiate()
	ship_scene.position = start_position
	ship_scene.player_num = num
	ship_scene.rotation = start_rotation
	self.add_child(ship_scene)
	return ship_scene


# Spawn a player home at the given position and rotation
func _spawn_player_home(num: int, start_position: Vector2, start_rotation: float) -> Home:
	var home_scene: Home = preload('res://models/player/home.tscn').instantiate()
	home_scene.position = start_position
	home_scene.player_num = num
	home_scene.rotation = start_rotation
	home_scene.z_index = -1
	self.add_child(home_scene)
	return home_scene


# Spawn a player score at the given position and rotation
func _spawn_player_score(num: int, start_position: Vector2, start_rotation: float) -> Score:
	var score_scene: Score = preload('res://models/player/score.tscn').instantiate()
	score_scene.position = start_position
	score_scene.player_num = num
	score_scene.rotation = start_rotation
	score_scene.z_index = -1
	self.add_child(score_scene)
	return score_scene


func _spawn_block(start_position: Vector2, has_gem: bool) -> Node:
	var block_scene: Block = preload('res://models/block/block.tscn').instantiate()
	block_scene.position = start_position
	block_scene.has_gem = has_gem
	self.add_child(block_scene)
	return block_scene


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
