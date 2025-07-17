extends Node

# This is a dictionary of player colors, where the key is the player ID and the value is an array of two colors.
const PLAYER_COLORS: Dictionary = {
									  1: [Color(1.0, 0.0, 0.894, 1.0), Color(0.733, 0.0, 0.655, 1.0)], # Pink
									  2: [Color(0.0, 0.722, 1.0, 1.0), Color(0.0, 0.529, 0.733, 1.0)]   # Blue
								  }
# player ship threshold that's rotation only (strafe) before applying force
const PLAYER_SCORE_COLLECT_GEM_VALUE: int               = 2
const PLAYER_SCORE_DISABLE_SHIP_VALUE: int              = 0
const PLAYER_SCORE_INITIAL: int                         = 3000 # todo restore 3
const PLAYER_SCORE_VICTORY: int                         = 10000 # todo restore 10
const PLAYER_SHIP_DISABLED_SEC: float                   = 5
const PLAYER_SHIP_DISABLED_S_RATIO: float               = 0.14
const PLAYER_SHIP_DISABLED_V_RATIO: float               = 0.38
const PLAYER_SHIP_FORCEFIELD_FORCE: float               = 10000.0
const PLAYER_SHIP_FORCEFIELD_EFFECT_SCALE_MIN: float    = 1.0
const PLAYER_SHIP_FORCEFIELD_EFFECT_SCALE_MAX: float    = 3.0
const PLAYER_SHIP_FORCEFIELD_EFFECT_GRAVITY: float      = 170.0
const PLAYER_SHIP_FORCEFIELD_EFFECT_KG_MAX: int         = 10
const PLAYER_SHIP_FORCE_AMOUNT: int                     = 5000
const PLAYER_SHIP_HEATED_DISABLED_THRESHOLD_SEC: float  = 2.0
const PLAYER_SHIP_LASER_AVAILABLE_MIN_CHARGE_SEC: float = 1
const PLAYER_SHIP_LASER_CHARGE_MAX_SEC: float           = 1000 # todo restore 3
const PLAYER_SHIP_LASER_FLICKER_RATE: float             = 5
const PLAYER_SHIP_LASER_RECHARGE_RATE: float            = 0.5
const PLAYER_SHIP_LINEAR_DAMP: float                    = 0.9
const PLAYER_SHIP_STRAFE_THRESHOLD_MSEC: float          = 500
const PLAYER_SHIP_TARGET_ROTATION_FACTOR: float         = 10
# blocks
const BLOCK_ACTIVATION_HEAT_THRESHOLD: float = 0.5
const BLOCK_BREAK_APART_VELOCITY: float      = 50
const BLOCK_BREAK_HEAT_TRANSFER_RATIO: float = 0.7
const BLOCK_HALF_BREAK_APART_VELOCITY: float = BLOCK_BREAK_APART_VELOCITY / 2
const BLOCK_HALF_HEATED_BREAK_SEC: float     = BLOCK_HEATED_BREAK_SEC / 2
const BLOCK_HEATED_BREAK_SEC: float          = 0.1 # todo restore 1.0
const BLOCK_INACTIVE_OPACITY: float          = 0.4
const BLOCK_INNER_GEM_ALPHA: float           = 0.8
const BLOCK_LINEAR_DAMP: float               = 0.1
const BLOCK_QUART_HEATED_BREAK_SEC: float    = BLOCK_HEATED_BREAK_SEC / 4
# gem behavior
const GEM_MAX_COUNT: int                      = 1
const GEM_SPAWN_EVERY_MSEC: int               = 100 # delay between spawning gems
const GEM_SPAWN_INITIAL_MSEC: int             = 1000 # initial delay before spawning the first gem
const GEM_SPAWN_AFTER_SCORING_DELAY_MSEC: int = 1500 # delay after scoring before spawning a new gem
# game behavior
const GAME_OVER_DELAY_SEC: float      = 1.0 # tiny delay before checking game over state, to allow projectiles to finish
const GAME_OVER_SHOW_MODAL_SEC: float = 2.5
const GAME_START_COUNTER_DELAY: float = 1.0
# projectile explosive behavior
const PROJECTILE_EXPLOSIVE_ACCELERATION: float     = 500.0
const PROJECTILE_EXPLOSIVE_COOLDOWN_MSEC: float    = 500
const PROJECTILE_EXPLOSIVE_INITIAL_VELOCITY: float = 200.0
const PROJECTILE_EXPLOSIVE_MAX_VELOCITY: float     = 2000.0
# pertaining to explosive
const EXPLOSION_CRITICAL_RADIUS_BLOCK_BREAK_LEVEL_1_RATIO: float   = 0.0 # todo restore to 0.4
const EXPLOSION_CRITICAL_RADIUS_BLOCK_BREAK_LEVEL_2_RATIO: float   = 0.0 # todo restore to 0.25
const EXPLOSION_CRITICAL_RADIUS_BLOCK_BREAK_LEVEL_3_RATIO: float   = 0.5 # todo restore to 0.1
const EXPLOSION_CRITICAL_RADIUS_SHIP_RATIO: float          = 0.4
const EXPLOSION_FORCE: int                                 = 8000
const EXPLOSION_HEAT_RADIUS_RATIO: float                   = 0.7
const EXPLOSION_LIFETIME_MSEC: int                         = 1000
# Formatting template for player input
const player_input_mapping_format: Dictionary = {
													"left": "p%d_left",
													"right": "p%d_right",
													"up": "p%d_up",
													"down": "p%d_down",
													"action_a": "p%d_action_a",
													"action_b": "p%d_action_b",
													"start": "p%d_start",
												}
