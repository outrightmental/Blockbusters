class_name Menu
extends Control

# Structure to hold a menu item
class MenuItem:
	var label_node: RichTextLabel
	var action: Callable

# List of menu items
var menu_items: Array[MenuItem] = []

# Currently selected menu index
@export var selected_index: int = 0
# Font size for selected item
@export var selected_font_size: int = 50
# Font size for unselected items
@export var unselected_font_size: int = 40
# Active item color
@export var active_color: Color = Constant.PLAYER_COLORS[1][0]
# Inactive item color
@export var inactive_color: Color = Color(0.2, 0.2, 0.2, 1.0)

@onready var font: Font = load("res://assets/fonts/Montserrat/static/Montserrat-Black.ttf")

# Keep track of whether input movement is active, to prevent multiple navigation
var is_navigation_active: bool = false


# Configure the menu from an array of dictionaries with `label` and `action`
func configure(items: Array[Dictionary]) -> void:
	for child in $VBoxContainer.get_children():
		$VBoxContainer.remove_child(child)
		child.queue_free()
	menu_items.clear()
	selected_index = 0
	for d in items:
		var item  =  MenuItem.new()
		item.action = d["action"]
		var label := _create_label(d["label"])
		$VBoxContainer.add_child(label)
		item.label_node = label
		menu_items.append(item)
	_update_menu_display()


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	InputManager.action_pressed.connect(_on_action_pressed)


# Create a label node for a menu item
func _create_label(label_text: String) -> RichTextLabel:
	var label: RichTextLabel = RichTextLabel.new()
	label.bbcode_enabled = false
	label.text = label_text
	label.layout_direction = RichTextLabel.LAYOUT_DIRECTION_LTR
	_set_font(label, font)
	_set_font_size(label, unselected_font_size)
	_set_default_color(label, inactive_color)
	label.horizontal_alignment = HorizontalAlignment.HORIZONTAL_ALIGNMENT_CENTER
	label.text = label_text
	label.fit_content = true
	return label


# Update the visual display of the menu
func _update_menu_display() -> void:
	for i in range(menu_items.size()):
		var item: MenuItem = menu_items[i]
		if i == selected_index:
			_set_font_size(item.label_node, selected_font_size)
			_set_default_color(item.label_node, active_color)
		else:
			_set_font_size(item.label_node, unselected_font_size)
			_set_default_color(item.label_node, inactive_color)


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
	var m = InputManager.movement[1] + InputManager.movement[2]
	if is_navigation_active:
		if m.length() < Constant.INPUT_MENU_NAV_STICK_RESET_THRESHOLD:
			is_navigation_active = false
		else:
			return

	if m.length() > Constant.INPUT_MENU_NAV_STICK_ACTIVE_THRESHOLD:
		is_navigation_active = true
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
	if action in [
	InputManager.INPUT_ACTION_A,
	InputManager.INPUT_ACTION_B,
	InputManager.INPUT_START,
	]:
		if menu_items.size() > 0 and selected_index < menu_items.size():
			var item: MenuItem = menu_items[selected_index]
			if item.action:
				item.action.call()


# Navigate right
func _nav_right() -> void:
	pass


# Navigate left	
func _nav_left() -> void:
	pass


# Navigate down	
func _nav_down() -> void:
	selected_index = wrap(selected_index + 1, 0, menu_items.size())
	_update_menu_display()


# Navigate up	
func _nav_up() -> void:
	selected_index = wrap(selected_index - 1, 0, menu_items.size())
	_update_menu_display()
	
