class_name Menu
extends Control

# Structure to hold a menu item
class MenuItem:
	var label_text: String
	var label_node: RichTextLabel
	var action: Callable
	var value: Callable
	var disabled: Callable
	var active: Callable
	var is_small: bool = false

# List of menu items
var menu_items: Array[MenuItem] = []

# Font size for selected item ratio, item, small item, and title
@export var item_font_size: int = 40
@export var item_small_font_size: int = 30
@export var selected_font_size_ratio: float = 1.25
@export var title_font_size: int = item_small_font_size
# Colors for title, selected, disabled, and default items
@export var inactive_selected_color: Color = Constant.PLAYER_COLORS[1][1]
@export var active_selected_color: Color = Constant.PLAYER_COLORS[1][0]
@export var inactive_color: Color = Color(0.4, 0.4, 0.4, 1.0)
@export var active_color: Color = Constant.PLAYER_COLORS[2][1]
@export var default_color: Color = Color(0.2, 0.2, 0.2, 1.0)
@export var disabled_color: Color = Color(0.2, 0.2, 0.2, 0.3)
@export var selected_color: Color = Constant.PLAYER_COLORS[1][0]
@export var title_color: Color = Color(0.2, 0.2, 0.2, 1.0)
# Item label horizontal alignment
@export var label_h_align: HorizontalAlignment = HorizontalAlignment.HORIZONTAL_ALIGNMENT_CENTER

# Font size for items
@onready var _selected_item_font_size := int(item_font_size * selected_font_size_ratio)
@onready var _selected_item_small_font_size := int(item_small_font_size * selected_font_size_ratio)
# Font resource for menu items
@onready var item_font: Font = load("res://assets/fonts/Montserrat/static/Montserrat-Black.ttf")
# Font resource for title
@onready var title_font: Font = load("res://assets/fonts/Montserrat/static/Montserrat-BoldItalic.ttf")

# Keep track of whether navigation is active, to prevent multiple navigation
var _is_navigation_active: bool = false
# Whether input is currently active for the menu
var _is_input_active: bool = true
# Currently selected menu index
var _selected_index: int = 0


# Configure the menu from an array of dictionaries with `label` and `action`
func configure(items: Array[Dictionary], title: String = "") -> void:
	for child in $VBoxContainer.get_children():
		$VBoxContainer.call_deferred("remove_child", child)
		child.call_deferred("queue_free")
	menu_items.clear()
	_selected_index = 0
	# Add title if provided
	if title.length() > 0:
		var title_label := _create_label(title)
		_set_font(title_label, title_font)
		_set_font_size(title_label, title_font_size)
		_set_default_color(title_label, title_color)
		$VBoxContainer.add_child(title_label)
	# Add menu items
	for d in items:
		var item  =  MenuItem.new()
		item.label_text = d["label"] # String
		item.action = d["action"] # Callable
		var label := _create_label(item.label_text)
		$VBoxContainer.add_child(label)
		item.label_node = label
		if d.has("value"):
			item.value = d["value"] # Callable
		if d.has("disabled"):
			item.disabled = d["disabled"] # Callable
		if d.has("active"):
			item.active = d["active"] # Callable
		if d.has("small"):
			item.is_small = d["small"] as bool
		menu_items.append(item)
	update()


# Update the visual display of the menu
func update() -> void:
	for i in range(menu_items.size()):
		var item: MenuItem = menu_items[i]
		# Update label text with value if applicable
		if item.value != null and item.value.is_valid():
			item.label_node.text = "%s: %s" % [item.label_text, item.value.call()]
		else:
			item.label_node.text = item.label_text
		# Update font size and color based on state
		if _get_is_item_disabled(item):
			_set_font_size(item.label_node, item_small_font_size if item.is_small else item_font_size)
			_set_default_color(item.label_node, disabled_color)
		elif i == _selected_index:
			_set_font_size(item.label_node, _selected_item_small_font_size if item.is_small else _selected_item_font_size)
			if _get_is_item_active(item):
				_set_default_color(item.label_node, active_selected_color)
			elif _get_is_item_inactive(item):
				_set_default_color(item.label_node, inactive_selected_color)
			else:
				_set_default_color(item.label_node, selected_color)
		else:
			_set_font_size(item.label_node, item_small_font_size if item.is_small else item_font_size)
			if _get_is_item_active(item):
				_set_default_color(item.label_node, active_color)
			elif _get_is_item_inactive(item):
				_set_default_color(item.label_node, inactive_color)
			else:
				_set_default_color(item.label_node, default_color)


# Reset the menu to the first (or last item)
func reset(last: bool = false) -> void:
	_selected_index = 0 if not last else menu_items.size() - 1
	update()


# Hide the menu and disable input
func deactivate() -> void:
	visible = false
	_is_input_active = false


# Show the menu and enable input, but start with navigation inactive so user must reset stick
func activate() -> void:
	_is_navigation_active = false
	_is_input_active = true
	visible = true


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	InputManager.action_pressed.connect(_on_action_pressed)


# Create a label node for a menu item
func _create_label(label_text: String) -> RichTextLabel:
	var label: RichTextLabel = RichTextLabel.new()
	label.bbcode_enabled = false
	label.text = label_text
	label.layout_direction = RichTextLabel.LAYOUT_DIRECTION_LTR
	_set_font(label, item_font)
	_set_font_size(label, item_font_size)
	_set_default_color(label, default_color)
	label.horizontal_alignment = label_h_align
	label.text = label_text
	label.fit_content = true
	return label


# Set the theme font override of a rich text label
func _set_font(label: RichTextLabel, label_font: Font) -> void:
	label.add_theme_font_override("normal_font", label_font)


# Set the theme font size override of a rich text label
func _set_font_size(label: RichTextLabel, label_font_size: int) -> void:
	label.add_theme_font_size_override("normal_font_size", label_font_size)


# Set the theme default color of a rich text label
func _set_default_color(label: RichTextLabel, default_color: Color) -> void:
	label.add_theme_color_override("default_color", default_color)


# Check for input to navigate the menu
func _physics_process(_delta: float) -> void:
	if not _is_input_active:
		return
	var m = InputManager.movement[1] + InputManager.movement[2]
	if _is_navigation_active:
		if m.length() < Constant.INPUT_MENU_NAV_STICK_RESET_THRESHOLD:
			_is_navigation_active = false
		else:
			return

	if m.length() > Constant.INPUT_MENU_NAV_STICK_ACTIVE_THRESHOLD:
		_is_navigation_active = true
		if abs(m.x) > abs(m.y):
			# Horizontal movement
			if m.x > 0:
				_nav_right()
			else:
				_nav_left()
		else:
			# Vertical movement
			if m.y > 0:
				_nav_down()
			else:
				_nav_up()


# Action pressed
func _on_action_pressed(_player: int, action: String) -> void:
	if not _is_input_active:
		return
	if action in [
	InputManager.INPUT_ACTION_A,
	InputManager.INPUT_ACTION_B,
	InputManager.INPUT_START,
	]:
		if menu_items.size() > 0 and _selected_index < menu_items.size():
			var item: MenuItem = menu_items[_selected_index]
			if item.action:
				item.action.call()


# Navigate right
func _nav_right() -> void:
	if not _is_input_active:
		return
	pass


# Navigate left	
func _nav_left() -> void:
	if not _is_input_active:
		return
	pass


# Navigate down	
func _nav_down() -> void:
	if not _is_input_active:
		return
	_selected_index = wrap(_selected_index + 1, 0, menu_items.size())
	# Recurse (skip) item is disabled (WARNING: could infinite loop if all disabled)
	if _get_is_item_disabled(menu_items[_selected_index]):
		_nav_down()
	else:
		update()


# Navigate up	
func _nav_up() -> void:
	if not _is_input_active:
		return
	_selected_index = wrap(_selected_index - 1, 0, menu_items.size())
	# Recurse (skip) item is disabled (WARNING: could infinite loop if all disabled)
	if _get_is_item_disabled(menu_items[_selected_index]):
		_nav_up()
	else:
		update()


# Check if a menu item is disabled		
# meaning it has a callback with value returning boolean true
func _get_is_item_disabled(item: MenuItem) -> bool:
	if item.disabled != null and item.disabled.is_valid():
		return item.disabled.call()
	return false


# Check if a menu item is active		
# meaning it has a callback with value returning boolean true
func _get_is_item_active(item: MenuItem) -> bool:
	if item.active != null and item.active.is_valid():
		return item.active.call()
	return false

# Check if a menu item is inactive		
# meaning it has a callback with value returning boolean false
func _get_is_item_inactive(item: MenuItem) -> bool:
	if item.active != null and item.active.is_valid():
		return not item.active.call()
	return false
