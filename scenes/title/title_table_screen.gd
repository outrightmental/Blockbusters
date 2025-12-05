extends Node2D

@onready var center_container: Node2D = $CenterContainer


# Called when the node enters the scene tree for the first time.
# Setup dynamic scaling
func _ready() -> void:
	_setup_dynamic_scaling()
	var tree: SceneTree = get_tree()
	if tree:
		tree.root.size_changed.connect(_setup_dynamic_scaling)


# Setup the correct screen based on game mode
func _setup_dynamic_scaling() -> void:
	center_container.position = ResolutionManager.get_center()
