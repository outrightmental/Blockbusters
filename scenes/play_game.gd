extends Node2D

# References to player goals
@onready var player_goal_1 = $GoalPlayer1
@onready var player_goal_2 = $GoalPlayer2
@onready var debug_text = $DebugText

# Variables
var grid: Dictionary = {}
var mesh: Dictionary = {}


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Setup the board based on the current input mode
	_setup()
	# Create the board before resetting the game (so that scores update on the board)
	_create_board()
	# Connect the game signals
	Game.player_enabled.connect(_on_player_enabled)
	Game.finished.connect(_on_finished)
	Game.spawn_gem.connect(_on_spawn_gem)
	Game.spawn_pickup.connect(_on_spawn_pickup)
	# Show debug text in editor only
	if OS.has_feature("editor"):
		Game.show_debug_text.connect(_on_show_debug_text)
	else:
		debug_text.hide()
	pass
	# Start a new game
	Game.start_new_game.emit()


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


# Show the game over banner for some time, then go back to main screen
func _on_finished() -> void:
	_goto_scene('res://scenes/main.tscn')
	pass


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
	var block_count: int         = 0
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
	var ship: Ship = ScenePreloader.ship_scene.instantiate()
	ship.position = start_position
	ship.player_num = num
	ship.rotation = start_rotation
	self.add_child(ship)
	return ship


func _spawn_block(start_position: Vector2) -> Node:
	var block: Block = ScenePreloader.block_scene.instantiate()
	block.position = start_position
	self.add_child(block)
	return block


func _on_spawn_gem() -> void:
	if Game.is_over:
		return
	if get_tree().get_node_count_in_group(Game.GEM_GROUP) >= Constant.GEM_MAX_COUNT:
		return
	var block: Block = _get_block_spawn_candidate()
	if block != null:
		block.add_gem()


func _on_spawn_pickup(type: Game.InventoryItemType) -> void:
	if Game.is_over:
		return
	if get_tree().get_node_count_in_group(Game.PICKUP_GROUP) >= Constant.PICKUP_MAX_COUNT:
		return
	var block: Block = _get_block_spawn_candidate()
	if block != null:
		block.add_pickup(type)


# Get a random block that may have something added to it
func _get_block_spawn_candidate() -> Block:
	var candidates: Array[Block]
	for block in get_tree().get_nodes_in_group(Game.BLOCK_GROUP):
		if block.is_empty():
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
	debug_text.show()


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
