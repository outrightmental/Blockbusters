extends Control

# Dual viewport container for table mode
# Displays two copies of the title screen, one facing each direction

@onready var viewport_container_1: SubViewportContainer = $ViewportContainer1
@onready var viewport_container_2: SubViewportContainer = $ViewportContainer2
@onready var sub_viewport_1: SubViewport = $ViewportContainer1/SubViewport1
@onready var sub_viewport_2: SubViewport = $ViewportContainer2/SubViewport2

# Scene to display in both viewports
@export var scene_path: String = "res://scenes/title/title_screen.tscn"


# Called when the node enters the scene tree
func _ready() -> void:
	# Wait for ResolutionManager to be ready
	await get_tree().process_frame
	
	# Setup viewport containers
	_setup_viewports()
	
	# Load the scene into both viewports
	_load_scene()
	
	# Connect to window size changes
	get_tree().root.size_changed.connect(_on_viewport_size_changed)


# Setup the dual viewports
func _setup_viewports() -> void:
	var viewport_size: Vector2 = get_viewport().get_visible_rect().size
	var half_width: float = viewport_size.x * 0.5
	
	# Setup first viewport container (left side, player 1, rotated 90° clockwise)
	viewport_container_1.position = Vector2(0, 0)
	viewport_container_1.size = Vector2(half_width, viewport_size.y)
	viewport_container_1.stretch = true
	viewport_container_1.rotation = PI / 2  # 90° clockwise
	viewport_container_1.pivot_offset = Vector2(half_width * 0.5, viewport_size.y * 0.5)
	
	# Setup second viewport container (right side, player 2, rotated 90° counter-clockwise)
	viewport_container_2.position = Vector2(half_width, 0)
	viewport_container_2.size = Vector2(half_width, viewport_size.y)
	viewport_container_2.stretch = true
	viewport_container_2.rotation = -PI / 2  # 90° counter-clockwise
	viewport_container_2.pivot_offset = Vector2(half_width * 0.5, viewport_size.y * 0.5)
	
	# Setup sub-viewports with base resolution
	sub_viewport_1.size = Vector2i(ResolutionManager.BASE_WIDTH, ResolutionManager.BASE_HEIGHT)
	sub_viewport_2.size = Vector2i(ResolutionManager.BASE_WIDTH, ResolutionManager.BASE_HEIGHT)
	
	print("[TableDualContainer] Setup viewports - Size: %s, Half: %.0f" % [viewport_size, half_width])


# Load the scene into both viewports
func _load_scene() -> void:
	var scene_1: Node = load(scene_path).instantiate()
	var scene_2: Node = load(scene_path).instantiate()
	
	sub_viewport_1.add_child(scene_1)
	sub_viewport_2.add_child(scene_2)


# Called when viewport size changes
func _on_viewport_size_changed() -> void:
	_setup_viewports()

