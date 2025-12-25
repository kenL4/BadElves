extends Control

## Game HUD - Play/Stop, restart, and menu controls

var play_button: Button
var restart_button: Button
var menu_button: Button
var next_button: Button
var status_label: Label
var victory_label: Label = null
var error_label: Label = null


func _ready() -> void:
	setup_ui()
	setup_snow() # Add snow!
	
	if GameManager:
		GameManager.state_changed.connect(_on_game_state_changed)
		GameManager.level_completed.connect(_on_level_completed)
		GameManager.show_error.connect(_on_show_error)

func setup_ui() -> void:
	# Top bar background
	var top_bg = Panel.new()
	top_bg.position = Vector2(150, 0)
	top_bg.size = Vector2(1050, 70)
	var bg_style = StyleBoxFlat.new()
	bg_style.bg_color = Color(0.1, 0.15, 0.2, 0.9)
	top_bg.add_theme_stylebox_override("panel", bg_style)
	add_child(top_bg)
	
	# Top bar container
	var top_bar = HBoxContainer.new()
	top_bar.position = Vector2(170, 10)
	top_bar.add_theme_constant_override("separation", 15)
	add_child(top_bar)
	
	# Menu button
	menu_button = Button.new()
	menu_button.custom_minimum_size = Vector2(80, 50)
	menu_button.text = "☰ Menu"
	style_button(menu_button, Color(0.4, 0.4, 0.5))
	menu_button.pressed.connect(_on_menu_pressed)
	top_bar.add_child(menu_button)
	
	# Play/Stop button
	play_button = Button.new()
	play_button.custom_minimum_size = Vector2(90, 50)
	play_button.text = "▶ PLAY"
	style_button(play_button, Color(0.2, 0.7, 0.2))
	play_button.pressed.connect(_on_play_pressed)
	top_bar.add_child(play_button)
	
	# Restart button
	restart_button = Button.new()
	restart_button.custom_minimum_size = Vector2(90, 50)
	restart_button.text = "↺ RESET"
	style_button(restart_button, Color(0.7, 0.5, 0.2))
	restart_button.pressed.connect(_on_restart_pressed)
	top_bar.add_child(restart_button)
	
	# Status label
	status_label = Label.new()
	status_label.text = "BUILD MODE"
	status_label.add_theme_font_size_override("font_size", 16)
	status_label.add_theme_color_override("font_color", Color.WHITE)
	top_bar.add_child(status_label)
	
	# Level title - show current level name
	var title = Label.new()
	if LevelManager and not LevelManager.current_level_id.is_empty():
		var level = LevelManager.get_level(LevelManager.current_level_id)
		title.text = "🎄 " + level.get("name", "BAD ELVES") + " 🎄"
	else:
		title.text = "🎄 BAD ELVES 🎄"
	title.position = Vector2(800, 20)
	title.add_theme_font_size_override("font_size", 24)
	title.add_theme_color_override("font_color", Color(1.0, 0.9, 0.3))
	add_child(title)
	
	# Instructions at bottom
	var instructions = Label.new()
	instructions.text = "← → = Drive | Space = Play/Stop | R = Reset | Right-Click = Delete"
	instructions.position = Vector2(350, 565)
	instructions.add_theme_font_size_override("font_size", 13)
	instructions.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
	add_child(instructions)

func style_button(btn: Button, color: Color) -> void:
	btn.focus_mode = Control.FOCUS_NONE
	var style = StyleBoxFlat.new()
	style.bg_color = color
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	btn.add_theme_stylebox_override("normal", style)
	
	var hover_style = style.duplicate()
	hover_style.bg_color = color.lightened(0.2)
	btn.add_theme_stylebox_override("hover", hover_style)
	
	btn.add_theme_color_override("font_color", Color.WHITE)
	btn.add_theme_font_size_override("font_size", 14)

func _on_play_pressed() -> void:
	# Check tutorial restrictions
	if TutorialManager and TutorialManager.is_active:
		if not TutorialManager.is_click_allowed("play_button"):
			print("Tutorial: Not time to play yet")
			return
	
	if GameManager:
		GameManager.toggle_play_mode()
		# Notify tutorial
		if TutorialManager and TutorialManager.is_active:
			if GameManager.current_state == GameManager.GameState.PLAY:
				TutorialManager.on_event("play_started")

func _on_restart_pressed() -> void:
	if GameManager:
		GameManager.restart_level()

func _on_menu_pressed() -> void:
	if LevelManager:
		GameManager.clear_all_parts()
		LevelManager.go_to_level_select()

func _on_game_state_changed(new_state: int) -> void:
	# Clear victory label if exists
	if victory_label and new_state == GameManager.GameState.BUILD:
		victory_label.queue_free()
		victory_label = null
		if next_button:
			next_button.queue_free()
			next_button = null
	
	match new_state:
		GameManager.GameState.BUILD:
			play_button.text = "▶ PLAY"
			status_label.text = "BUILD MODE"
			status_label.add_theme_color_override("font_color", Color.WHITE)
		GameManager.GameState.PLAY:
			play_button.text = "■ STOP"
			status_label.text = "PLAYING..."
			status_label.add_theme_color_override("font_color", Color(0.5, 1.0, 0.5))
		GameManager.GameState.COMPLETE:
			status_label.text = "🎉 COMPLETE!"
			status_label.add_theme_color_override("font_color", Color(1.0, 0.9, 0.3))

func _on_level_completed() -> void:
	# Show victory message
	victory_label = Label.new()
	victory_label.text = "🎄 PRESENT DELIVERED! 🎄"
	victory_label.position = Vector2(380, 250)
	victory_label.add_theme_font_size_override("font_size", 36)
	victory_label.add_theme_color_override("font_color", Color(1.0, 0.9, 0.3))
	add_child(victory_label)
	
	# Next level button
	next_button = Button.new()
	next_button.text = "Next Level →"
	next_button.position = Vector2(500, 320)
	next_button.custom_minimum_size = Vector2(150, 50)
	style_button(next_button, Color(0.2, 0.6, 0.8))
	next_button.pressed.connect(_on_next_pressed)
	add_child(next_button)
	
	# Add glow effect
	var tween = create_tween().set_loops()
	tween.tween_property(victory_label, "modulate:a", 0.6, 0.5)
	tween.tween_property(victory_label, "modulate:a", 1.0, 0.5)
	
	spawn_confetti()

func _on_next_pressed() -> void:
	if LevelManager:
		GameManager.clear_all_parts()
		LevelManager.go_to_level_select()

func _on_show_error(message: String) -> void:
	# Create error label if not exists
	if not error_label:
		error_label = Label.new()
		error_label.add_theme_font_size_override("font_size", 24)
		error_label.add_theme_color_override("font_color", Color(1.0, 0.4, 0.4))
		error_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		# Background panel for better visibility
		var style = StyleBoxFlat.new()
		style.bg_color = Color(0.1, 0.05, 0.05, 0.9)
		style.corner_radius_top_left = 10
		style.corner_radius_top_right = 10
		style.corner_radius_bottom_left = 10
		style.corner_radius_bottom_right = 10
		style.expand_margin_left = 20
		style.expand_margin_right = 20
		style.expand_margin_top = 10
		style.expand_margin_bottom = 10
		error_label.add_theme_stylebox_override("normal", style)
		add_child(error_label)
	
	error_label.text = "⚠️ " + message
	error_label.size = Vector2(0, 0) # Reset size to content
	error_label.position = Vector2(600 - error_label.size.x / 2, 300) # Center roughly
	# Recenter after frame update ideally, but rough center is fine for jam
	
	# Animate
	error_label.modulate.a = 0.0
	error_label.position = Vector2(400, 300) # Fixed center area
	error_label.size = Vector2(400, 50)
	
	var tween = create_tween()
	tween.tween_property(error_label, "modulate:a", 1.0, 0.2)
	tween.tween_interval(2.0)
	tween.tween_property(error_label, "modulate:a", 0.0, 0.5)



func setup_snow() -> void:
	# Create a container behind buttons (z-index wise, simpler to just add snowflakes)
	# But buttons are already added in setup_ui. 
	# To be safe, let's just make them ignore mouse input so they don't block clicks.
	for i in range(30):
		add_snowflake()

func add_snowflake() -> void:
	var flake = Label.new()
	flake.text = "❄"
	# Scatter across the entire screen
	flake.position = Vector2(randf() * 1200, randf() * 600) 
	flake.add_theme_font_size_override("font_size", randi_range(12, 24))
	flake.modulate.a = randf_range(0.2, 0.5) # Slightly more transparent for gameplay
	flake.mouse_filter = Control.MOUSE_FILTER_IGNORE # Critical: Click-through!
	add_child(flake)
	move_child(flake, 0) # Put behind everything else in HUD if possible
	
	# Animate falling
	var tween = create_tween().set_loops()
	# Fall down to bottom of screen (600)
	tween.tween_property(flake, "position:y", 650.0, randf_range(3.0, 8.0))
	tween.tween_callback(func(): flake.position.y = -20; flake.position.x = randf() * 1200)

func spawn_confetti() -> void:
	var confetti = CPUParticles2D.new()
	confetti.position = Vector2(600, -50) # Top center
	confetti.amount = 60
	confetti.lifetime = 3.0
	confetti.explosiveness = 0.6
	confetti.direction = Vector2(0, 1) # Down
	confetti.spread = 60.0 # Wide cone
	confetti.initial_velocity_min = 200.0
	confetti.initial_velocity_max = 500.0
	confetti.angular_velocity_min = 100.0
	confetti.angular_velocity_max = 300.0
	confetti.scale_amount_min = 4.0
	confetti.scale_amount_max = 8.0
	confetti.color = Color(1, 0, 0) # Base red
	confetti.hue_variation_min = -1.0 # Full rainbow
	confetti.hue_variation_max = 1.0
	confetti.one_shot = true
	confetti.emitting = true
	
	add_child(confetti)
	move_child(confetti, get_child_count() - 1) # On top
	
	# Cleanup
	var timer = get_tree().create_timer(4.0)
	timer.timeout.connect(func(): 
		if is_instance_valid(confetti):
			confetti.queue_free()
	)
