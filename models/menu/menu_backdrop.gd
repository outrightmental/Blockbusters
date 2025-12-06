extends ColorRect

# Backdrop for menu screens that adjusts based on display resolution

# Constants for mip level based on resolution
const BG_MIP_LEVEL_RESOLUTION_FULL: float = 12.0
const BG_MIP_LEVEL_RESOLUTION_LOFI: float = 4.0


# Called when the node enters the scene tree for the first time
func _ready() -> void:
	ResolutionManager.display_resolution_changed.connect(_setup)
	_setup()


# Setup the backdrop based on resolution
func _setup() -> void:
	var mip_level: float = BG_MIP_LEVEL_RESOLUTION_FULL if ResolutionManager.is_full_resolution() else BG_MIP_LEVEL_RESOLUTION_LOFI
	material.set("shader_parameter/mip_level", mip_level)

	
