extends Control

## Build UI - Part selection palette

var build_system: Node2D = null
var part_buttons: Array[Button] = []

func _ready() -> void:
	# Wait a frame for the scene tree to be ready
	await get_tree().process_frame
	
	# Get build system reference
	build_system = get_node_or_null("/root/Main/BuildSystem")
	if not build_system:
		push_error("BuildUI: Could not find BuildSystem node!")
	
	setup_ui()
	
	if GameManager:
		GameManager.state_changed.connect(_on_game_state_changed)

func setup_ui() -> void:
	# Create background panel for parts
	var bg_panel = Panel.new()
	bg_panel.position = Vector2(0, 0)
	bg_panel.size = Vector2(150, 600)
	var bg_style = StyleBoxFlat.new()
	bg_style.bg_color = Color(0.1, 0.15, 0.2, 0.9)
	bg_panel.add_theme_stylebox_override("panel", bg_style)
	add_child(bg_panel)
	
	# Create part palette
	var palette = VBoxContainer.new()
	palette.name = "PartPalette"
	palette.position = Vector2(10, 80)
	palette.add_theme_constant_override("separation", 10)
	add_child(palette)
	
	# Title
	var title = Label.new()
	title.text = "🎁 PARTS"
	title.position = Vector2(10, 20)
	title.add_theme_font_size_override("font_size", 24)
	title.add_theme_color_override("font_color", Color.WHITE)
	add_child(title)
	
	# Part buttons
	create_part_button(palette, "gift_box", "🎁 Gift Box", Color(0.8, 0.2, 0.2))
	create_part_button(palette, "wheel", "⭕ Wheel", Color(0.6, 0.6, 0.6))
	create_part_button(palette, "elf", "🧝 Elf", Color(0.2, 0.7, 0.2))

func create_part_button(parent: Control, part_type: String, label_text: String, color: Color) -> void:
	var btn = Button.new()
	btn.custom_minimum_size = Vector2(130, 50)
	btn.text = label_text
	btn.focus_mode = Control.FOCUS_NONE
	
	# Style the button
	var style = StyleBoxFlat.new()
	style.bg_color = color
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_width_bottom = 2
	style.border_color = Color.WHITE
	btn.add_theme_stylebox_override("normal", style)
	
	var hover_style = style.duplicate()
	hover_style.bg_color = color.lightened(0.2)
	btn.add_theme_stylebox_override("hover", hover_style)
	
	var pressed_style = style.duplicate()
	pressed_style.bg_color = color.darkened(0.2)
	btn.add_theme_stylebox_override("pressed", pressed_style)
	
	btn.add_theme_color_override("font_color", Color.WHITE)
	btn.add_theme_color_override("font_hover_color", Color.WHITE)
	btn.add_theme_font_size_override("font_size", 14)
	
	btn.pressed.connect(_on_part_button_pressed.bind(part_type))
	btn.set_meta("part_type", part_type)
	
	parent.add_child(btn)
	part_buttons.append(btn)

func _on_part_button_pressed(part_type: String) -> void:
	# Check tutorial restrictions
	if TutorialManager and TutorialManager.is_active:
		if not TutorialManager.is_click_allowed("part_button", part_type):
			print("Tutorial: wrong button, need to click ", TutorialManager.current_target)
			return
	
	if build_system:
		build_system.start_drag(part_type)
		# Notify tutorial
		if TutorialManager and TutorialManager.is_active:
			TutorialManager.on_event("part_selected")
	else:
		push_error("BuildUI: build_system is null!")

func _on_game_state_changed(new_state: int) -> void:
	# Disable part buttons during play mode
	var is_build_mode = new_state == GameManager.GameState.BUILD
	for btn in part_buttons:
		btn.disabled = not is_build_mode
