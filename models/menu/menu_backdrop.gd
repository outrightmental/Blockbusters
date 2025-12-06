class_name MenuBackdrop
extends ColorRect

# Backdrop for menu screens that adjusts based on display resolution

# Constants for mip level based on resolution
@export var mip_level_at_full_resolution: float = 12.0
@export var mip_level_at_lofi_resolution: float = 4.0
@export var lighten_amount: float = 0.2


# Called when the node enters the scene tree for the first time
func _ready() -> void:
	ResolutionManager.display_resolution_changed.connect(_setup)
	_setup()


# Setup the backdrop

func _setup() -> void:
	# mip level based on resolution
	var mip_level: float = mip_level_at_full_resolution if ResolutionManager.is_full_resolution() else mip_level_at_lofi_resolution
	material.set("shader_parameter/mip_level", mip_level)

	# lighten based on property
	material.set("shader_parameter/lighten_amount", lighten_amount)

	
