extends Node

#
# This is a dictionary of player colors, where the key is the player ID and the value is an array of two colors.
const PLAYER_COLORS: Dictionary = {
									  1: [Color(1.0, 0.0, 0.894, 1.0), Color(0.733, 0.0, 0.655, 1.0)], # Pink
									  2: [Color(0.0, 0.722, 1.0, 1.0), Color(0.0, 0.529, 0.733, 1.0)]   # Blue
								  }
#
# player ship threshold that's rotation only (strafe) before applying force
const PLAYER_INPUT_JOYSTICK_DEADZONE: float             = 0.25
const PLAYER_INVENTORY_MAX_ITEMS: int                   = 2
const PLAYER_SCORE_COLLECT_GEM_VALUE: int               = 2
const PLAYER_SCORE_DISABLE_SHIP_VALUE: int              = 0
const PLAYER_SCORE_INITIAL: int                         = 0
const PLAYER_SCORE_VICTORY: int                         = 7
const PLAYER_SHIP_DISABLED_SEC: float                   = 3
const PLAYER_SHIP_DISABLED_S_RATIO: float               = 0.14
const PLAYER_SHIP_DISABLED_V_RATIO: float               = 0.38
const PLAYER_SHIP_FORCEFIELD_EFFECT_GRAVITY: float      = 170.0
const PLAYER_SHIP_FORCEFIELD_EFFECT_KG_MAX: int         = 10
const PLAYER_SHIP_FORCEFIELD_EFFECT_SCALE_MAX: float    = 3.0
const PLAYER_SHIP_FORCEFIELD_EFFECT_SCALE_MIN: float    = 1.0
const PLAYER_SHIP_FORCEFIELD_INWARD_FORCE: float        = 10000.0
const PLAYER_SHIP_FORCEFIELD_MOTION_FORCE: float        = 30000.0
const PLAYER_SHIP_FORCEFIELD_MOTION_THRESHOLD: float    = 1.0
const PLAYER_SHIP_FORCE_AMOUNT: int                     = 5000
const PLAYER_SHIP_HEATED_DISABLED_THRESHOLD_SEC: float  = 10.0
const PLAYER_SHIP_LASER_ALPHA_MAX: float                = 0.5
const PLAYER_SHIP_LASER_AVAILABLE_MIN_CHARGE_SEC: float = 1
const PLAYER_SHIP_LASER_CHARGE_MAX_SEC: float           = 3
const PLAYER_SHIP_LASER_CLUSTER_COUNT: int              = 5
const PLAYER_SHIP_LASER_CLUSTER_SPREAD: float           = 5
const PLAYER_SHIP_LASER_FLICKER_RATE: float             = 5
const PLAYER_SHIP_LASER_RECHARGE_RATE: float            = 0.5
const PLAYER_SHIP_LINEAR_DAMP: float                    = 0.9
const PLAYER_SHIP_STRAFE_THRESHOLD_MSEC: float          = 500
const PLAYER_SHIP_TARGET_ROTATION_FACTOR: float         = 10
#
# blocks
const BLOCK_ACTIVATION_HEAT_THRESHOLD: float       = 0.3
const BLOCK_BREAK_APART_VELOCITY: float            = 50
const BLOCK_BREAK_HALF_HEAT_TRANSFER_RATIO: float  = 0.9
const BLOCK_BREAK_QUART_HEAT_TRANSFER_RATIO: float = 0.9
const BLOCK_EXPLOSION_OVERHEAT_RATIO: float        = 3 # exploson maxes at ratio above the amount of heat needed to break the block
const BLOCK_HALF_BREAK_APART_VELOCITY: float       = BLOCK_BREAK_APART_VELOCITY / 2
const BLOCK_HALF_HEATED_BREAK_SEC: float           = BLOCK_HEATED_BREAK_SEC / 2
const BLOCK_HEATED_BREAK_SEC: float                = 0.5
const BLOCK_INACTIVE_OPACITY: float                = 0.25
const BLOCK_INNER_GEM_ALPHA: float                 = 0.8
const BLOCK_LINEAR_DAMP: float                     = 0.1
const BLOCK_QUART_HEATED_BREAK_SEC: float          = BLOCK_HEATED_BREAK_SEC / 4
#
# gem behavior
const GEM_MAX_COUNT: int                      = 1
const GEM_SPAWN_EVERY_MSEC: int               = 100 # delay between spawning gems
const GEM_SPAWN_INITIAL_MSEC: int             = 1000 # initial delay before spawning the first gem
const GEM_SPAWN_AFTER_SCORING_DELAY_MSEC: int = 1500 # delay after scoring before spawning a new gem
#
# game behavior
const GAME_OVER_DELAY_SEC: float      = 1.0 # tiny delay before checking game over state, to allow projectiles to finish
const GAME_OVER_SHOW_MODAL_SEC: float = 4.0
const GAME_START_COUNTER_DELAY: float = 1.0
#
# projectile explosive behavior
const PROJECTILE_EXPLOSIVE_ACCELERATION: float     = 500.0
const PROJECTILE_EXPLOSIVE_COOLDOWN_MSEC: float    = 500
const PROJECTILE_EXPLOSIVE_INITIAL_VELOCITY: float = 200.0
const PROJECTILE_EXPLOSIVE_MAX_VELOCITY: float     = 2000.0
#
# pertaining to explosive
const EXPLOSION_FORCE: int               = 8000
const EXPLOSION_HEAT_RADIUS_RATIO: float = 0.6
const EXPLOSION_LIFETIME_MSEC: int       = 1000
const EXPLOSION_SHIP_EFFECT_MULTIPLIER: float = 0.8 # ratio multiplied by ship overheating threshold
#
# pertaining to heat
const HEATING_TIMEOUT_MSEC: int = 250 # timeout after heat not applied when we consider the block no longer heating up
#
# Board
# Spawn blocks in a grid pattern, 32 blocks wide and 18 blocks tall, starting at (16, 16) and spaced 32 pixels apart
# The blocks are32x32 pixels, so the grid is 1024x576 pixels
const BOARD_BLOCK_ATTEMPT_MAX: int          = 1_000_000 # max attempts to place a block
const BOARD_BLOCK_CENTER: int               = floori(BOARD_BLOCK_SIZE * 0.5)
const BOARD_BLOCK_COUNT_MAX: int            = floori(BOARD_GRID_COUNT_MAX * BOARD_BLOCK_COUNT_RATIO)
const BOARD_BLOCK_COUNT_RATIO: float        = 0.3 # ratio of the grid that is filled with blocks
const BOARD_BLOCK_SIZE: int                 = 32
const BOARD_GRID_COLS: int                  = 24
const BOARD_GRID_COLS_MARGIN: int           = 4
const BOARD_GRID_COUNT_MAX: int             = BOARD_GRID_COLS * BOARD_GRID_ROWS
const BOARD_GRID_MESH_THRESHOLD: float      = 0.62
const BOARD_GRID_ROWS: int                  = 14
const BOARD_GRID_ROWS_MARGIN: int           = 2
const BOARD_HOME_CLEARANCE_RADIUS: int      = 130
const BOARD_MODAL_NEUTRAL_TEXT_COLOR: Color = Color(1, 1, 1, 1)
const BOARD_SEED_MAX: int                   = 1_000_000_000
const BOARD_SEED_F1: int                    = 18_285_756
const BOARD_SEED_F2: int                    = 89_074_356
const BOARD_SEED_F3: int                    = 973_523_665
const BOARD_SEED_F4: int                    = 167_653_873
const BOARD_SEED_F5: int                    = 423_587_300
const BOARD_SEED_F6: int                    = 798_647_400
