extends Node

## Tutorial Manager - Interactive step-by-step tutorial

signal tutorial_step_changed(step: int)
signal tutorial_completed

# Tutorial steps with specific target positions
var tutorial_steps: Array[Dictionary] = [
	{
		"text": "Welcome! Click the 🎁 Gift Box button",
		"target": "gift_box",
		"wait_for": "part_selected",
		"build_pos": Vector2.ZERO  # Not a build step
	},
	{
		"text": "Place the first box here",
		"target": "build",
		"wait_for": "part_placed",
		"build_pos": Vector2(296, 360)
	},
	{
		"text": "Place the second box next to it",
		"target": "build",
		"wait_for": "part_placed",
		"build_pos": Vector2(360, 360)
	},
	{
		"text": "Now click the ⭕ Wheel button",
		"target": "wheel",
		"wait_for": "part_selected",
		"build_pos": Vector2.ZERO
	},
	{
		"text": "Place a wheel under the first box",
		"target": "build",
		"wait_for": "part_placed",
		"build_pos": Vector2(296, 424)
	},
	{
		"text": "Place another wheel under the second box",
		"target": "build",
		"wait_for": "part_placed",
		"build_pos": Vector2(360, 424)
	},
	{
		"text": "Click the 🧝 Elf button",
		"target": "elf",
		"wait_for": "part_selected",
		"build_pos": Vector2.ZERO
	},
	{
		"text": "Place the elf on the tail",
		"target": "build",
		"wait_for": "part_placed",
		"build_pos": Vector2(424, 360)
	},
	{
		"text": "Click ▶ PLAY to start!",
		"target": "play",
		"wait_for": "play_started",
		"build_pos": Vector2.ZERO
	},
	{
		"text": "Use Arrow Keys to Drive!",
		"target": "none",
		"wait_for": "level_complete",
		"build_pos": Vector2.ZERO,
		"show_keys": true
	}
]

var current_step: int = -1
var is_active: bool = false
var current_build_pos: Vector2 = Vector2.ZERO
var current_target: String = ""

var tutorial_ui: CanvasLayer = null
var mask_top: ColorRect = null
var mask_bottom: ColorRect = null
var mask_left: ColorRect = null
var mask_right: ColorRect = null
var popup_container: PanelContainer = null
var popup_label: Label = null
var highlight_rect: Panel = null
var keys_container: HBoxContainer = null

func start_tutorial() -> void:
	print("Starting tutorial...")
	is_active = true
	current_step = -1
	
	create_ui()
	await get_tree().process_frame
	next_step()

func create_ui() -> void:
	var root = get_tree().get_root()
	var main = root.get_child(root.get_child_count() - 1)
	
	# Create canvas layer on top of everything
	tutorial_ui = CanvasLayer.new()
	tutorial_ui.name = "TutorialUI"
	tutorial_ui.layer = 100
	main.add_child(tutorial_ui)
	
	# Create 4 masking rects for the "hole" effect
	mask_top = create_mask_rect("MaskTop")
	mask_bottom = create_mask_rect("MaskBottom")
	mask_left = create_mask_rect("MaskLeft")
	mask_right = create_mask_rect("MaskRight")
	
	# Instruction text popup with styling
	popup_container = PanelContainer.new()
	popup_container.name = "InstructionBox"
	popup_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.15, 0.3, 0.95) # Dark Blue
	style.border_width_left = 3
	style.border_width_top = 3
	style.border_width_right = 3
	style.border_width_bottom = 3
	style.border_color = Color(0.4, 0.9, 1.0) # Light Cyan Border
	style.corner_radius_top_left = 12
	style.corner_radius_top_right = 12
	style.corner_radius_bottom_left = 12
	style.corner_radius_bottom_right = 12
	style.content_margin_left = 20
	style.content_margin_right = 20
	style.content_margin_top = 15
	style.content_margin_bottom = 15
	
	popup_container.add_theme_stylebox_override("panel", style)
	
	# Initial position (centered top, slightly lower to clear HUD)
	popup_container.position = Vector2(300, 100)
	popup_container.custom_minimum_size = Vector2(600, 0) # Fixed width, auto height
	
	popup_label = Label.new()
	popup_label.name = "Text"
	popup_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	popup_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	popup_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	popup_label.add_theme_font_size_override("font_size", 22)
	popup_label.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0)) # White Text
	
	popup_container.add_child(popup_label)
	tutorial_ui.add_child(popup_container)
	
	# Highlight rectangle
	highlight_rect = Panel.new()
	highlight_rect.name = "Highlight"
	
	# Create stylebox for border
	var highlight_style = StyleBoxFlat.new()
	highlight_style.bg_color = Color(0, 0, 0, 0)  # Transparent center
	highlight_style.border_width_left = 4
	highlight_style.border_width_top = 4
	highlight_style.border_width_right = 4
	highlight_style.border_width_bottom = 4
	highlight_style.border_color = Color(0.2, 0.8, 1.0)
	highlight_style.set_corner_radius_all(8)
	
	highlight_rect.add_theme_stylebox_override("panel", highlight_style)
	highlight_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	highlight_rect.visible = false
	tutorial_ui.add_child(highlight_rect)
	
	# Arrow Keys Hint Container
	keys_container = HBoxContainer.new()
	keys_container.name = "KeysHint"
	keys_container.add_theme_constant_override("separation", 20)
	keys_container.alignment = BoxContainer.ALIGNMENT_CENTER
	# Position above hints (hints at 565)
	keys_container.position = Vector2(500, 510) 
	keys_container.custom_minimum_size = Vector2(200, 50)
	keys_container.visible = false
	
	# Left Key
	var left_key = create_key_visual("←")
	keys_container.add_child(left_key)
	
	# Right Key
	var right_key = create_key_visual("→")
	keys_container.add_child(right_key)
	
	tutorial_ui.add_child(keys_container)

func create_mask_rect(name: String) -> ColorRect:
	var rect = ColorRect.new()
	rect.name = name
	rect.color = Color(0, 0, 0, 0.8)
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tutorial_ui.add_child(rect)
	return rect

func next_step() -> void:
	current_step += 1
	
	if current_step >= tutorial_steps.size():
		complete_tutorial()
		return
	
	var step = tutorial_steps[current_step]
	current_target = step.target
	current_build_pos = step.build_pos
	
	print("Tutorial step ", current_step, ": ", step.target)
	
	# Update instruction text
	popup_label.text = step.text
	popup_container.visible = not step.text.is_empty()
	
	# Show/Hide keys hint
	if keys_container:
		keys_container.visible = step.get("show_keys", false)
	
	# Recenter container based on its new size after text update
	# We defer this slightly to ensure size is calculated
	_update_popup_position.call_deferred()
	
	# Position highlight based on target
	update_highlight(step.target, step.build_pos)
	
	tutorial_step_changed.emit(current_step)

func update_highlight(target: String, build_pos: Vector2) -> void:
	highlight_rect.visible = true
	
	# Animate highlight border
	var tween = highlight_rect.create_tween().set_loops()
	tween.tween_property(highlight_rect, "modulate:a", 0.5, 0.5)
	tween.tween_property(highlight_rect, "modulate:a", 1.0, 0.5)
	
	match target:
		"gift_box":
			# Left panel, first button
			highlight_rect.position = Vector2(6, 76)
			highlight_rect.size = Vector2(138, 58)
		"wheel":
			highlight_rect.position = Vector2(6, 136)
			highlight_rect.size = Vector2(138, 58)
		"elf":
			highlight_rect.position = Vector2(6, 196)
			highlight_rect.size = Vector2(138, 58)
		"play":
			# Play button in HUD
			highlight_rect.position = Vector2(261, 6)
			highlight_rect.size = Vector2(98, 58)
		"build":
			# Specific build position - show a grid cell
			highlight_rect.position = build_pos - Vector2(32, 32)
			highlight_rect.size = Vector2(64, 64)
		_:
			highlight_rect.visible = false
	
	# Update masks to surround the highlight
	if highlight_rect.visible:
		var screen_size = get_viewport().get_visible_rect().size
		var h_rect = Rect2(highlight_rect.position, highlight_rect.size)
		
		# Top mask
		mask_top.position = Vector2(0, 0)
		mask_top.size = Vector2(screen_size.x, h_rect.position.y)
		mask_top.visible = true
		
		# Bottom mask
		mask_bottom.position = Vector2(0, h_rect.end.y)
		mask_bottom.size = Vector2(screen_size.x, screen_size.y - h_rect.end.y)
		mask_bottom.visible = true
		
		# Left mask (between top and bottom)
		mask_left.position = Vector2(0, h_rect.position.y)
		mask_left.size = Vector2(h_rect.position.x, h_rect.size.y)
		mask_left.visible = true
		
		# Right mask (between top and bottom)
		mask_right.position = Vector2(h_rect.end.x, h_rect.position.y)
		mask_right.size = Vector2(screen_size.x - h_rect.end.x, h_rect.size.y)
		mask_right.visible = true
	else:
		# Full screen mask if no highlight (or hide all? Assume we always highlight something in steps)
		mask_top.visible = false
		mask_bottom.visible = false
		mask_left.visible = false
		mask_right.visible = false


func is_click_allowed(click_type: String, part_type: String = "") -> bool:
	if not is_active:
		return true
	
	var step = tutorial_steps[current_step]
	
	# Check if this click matches what we're waiting for
	match step.target:
		"gift_box":
			return click_type == "part_button" and part_type == "gift_box"
		"wheel":
			return click_type == "part_button" and part_type == "wheel"
		"elf":
			return click_type == "part_button" and part_type == "elf"
		"play":
			return click_type == "play_button"
		"build":
			return click_type == "build_zone"
		"none":
			return true
		_:
			return false

func is_build_position_allowed(pos: Vector2) -> bool:
	if not is_active:
		return true
	
	var step = tutorial_steps[current_step]
	if step.target != "build":
		return true
	
	# Check if position is close to the required position
	var snapped = GameManager.snap_to_grid(pos)
	var allowed_pos = step.build_pos
	
	return snapped.distance_to(allowed_pos) < 10

func on_event(event_type: String) -> void:
	if not is_active or current_step < 0:
		return
	
	var step = tutorial_steps[current_step]
	
	if event_type == step.wait_for:
		next_step()

func complete_tutorial() -> void:
	print("Tutorial completed!")
	is_active = false
	current_target = ""
	current_build_pos = Vector2.ZERO
	
	if tutorial_ui:
		tutorial_ui.queue_free()
		tutorial_ui = null
	
	tutorial_completed.emit()


func hide_tutorial() -> void:
	complete_tutorial()

func _update_popup_position() -> void:
	var screen_width = get_viewport().get_visible_rect().size.x
	
	if popup_container and popup_container.visible:
		popup_container.position.x = (screen_width - popup_container.size.x) / 2
		
	if keys_container and keys_container.visible:
		# Recenter keys
		keys_container.position.x = (screen_width - keys_container.size.x) / 2

func create_key_visual(text: String) -> PanelContainer:
	var panel = PanelContainer.new()
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.9, 0.9, 0.95) # Off-white key
	style.border_width_bottom = 4
	style.border_color = Color(0.6, 0.6, 0.7) # Darker shadow/side
	style.corner_radius_top_left = 6
	style.corner_radius_top_right = 6
	style.corner_radius_bottom_left = 6
	style.corner_radius_bottom_right = 6
	style.content_margin_left = 15
	style.content_margin_right = 15
	style.content_margin_top = 5
	style.content_margin_bottom = 5
	panel.add_theme_stylebox_override("panel", style)
	
	var label = Label.new()
	label.text = text
	label.add_theme_color_override("font_color", Color(0.2, 0.2, 0.3))
	label.add_theme_font_size_override("font_size", 24)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	panel.add_child(label)
	
	return panel
