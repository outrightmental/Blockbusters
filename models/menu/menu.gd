class_name Menu
extends Control

# Structure to hold a menu item
class MenuItem:
	var label_node: RichTextLabel
	var action: Callable

# List of menu items
var menu_items: Array[MenuItem] = []
# Currently selected menu index
var selected_index: int = 0
# Font size for selected item
var selected_font_size: int = 64
# Font size for unselected items
var unselected_font_size: int = 45
# Keep track of whether input movement is active, to prevent multiple navigation
var is_navigation_active: bool = false
# Inactive item value modulation
var inactive_modulation_value: float = 0.62


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	print("[MENU] has %d items" % menu_items.size())
	_update_menu_display()
	InputManager.action_pressed.connect(_on_action_pressed)


func _register_menu_item(label_node: RichTextLabel, action: Callable) -> void:
	var item = MenuItem.new()
	item.action = action
	item.label_node = label_node
	menu_items.append(item)


# Update the visual display of the menu
func _update_menu_display() -> void:
	for i in range(menu_items.size()):
		var item: MenuItem = menu_items[i]
		if i == selected_index:
			_set_font_size(item, selected_font_size)
			_set_mod_value(item, 1.0)
		else:
			_set_font_size(item, unselected_font_size)
			_set_mod_value(item, inactive_modulation_value)


# Set the font size of a menu item
func _set_font_size(item: MenuItem, font_size: int) -> void:
	item.label_node.add_theme_font_size_override("normal_font_size", font_size)


# Set the modulation value of a menu item
func _set_mod_value(item: MenuItem, value: float) -> void:
	item.label_node.modulate.v = value


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


# Goto a scene, guarding against the condition that the tree has been unloaded since the calling thread arrived here
func _goto_scene(path: String) -> void:
	if get_tree():
		get_tree().change_scene_to_file(path)
