extends Control

## Main Menu

func _ready() -> void:
	setup_ui()

func setup_ui() -> void:
	# Background
	var bg = ColorRect.new()
	bg.color = Color(0.02, 0.05, 0.12, 1)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	
	# Snow ground
	var ground = ColorRect.new()
	ground.color = Color(0.9, 0.95, 1.0, 1)
	ground.position = Vector2(0, 450)
	ground.size = Vector2(1200, 150)
	add_child(ground)
	
	# Title container
	var title_container = VBoxContainer.new()
	title_container.set_anchors_preset(Control.PRESET_CENTER)
	title_container.position = Vector2(600, 200)
	title_container.alignment = BoxContainer.ALIGNMENT_CENTER
	add_child(title_container)
	
	# Title
	var title = Label.new()
	title.text = "🎄 BAD ELVES 🎄"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 72)
	title.add_theme_color_override("font_color", Color(1.0, 0.9, 0.3))
	add_child(title)
	title.position = Vector2(300, 120)
	
	# Subtitle
	var subtitle = Label.new()
	subtitle.text = "A Christmas Delivery Game"
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_size_override("font_size", 24)
	subtitle.add_theme_color_override("font_color", Color(0.8, 0.9, 1.0))
	add_child(subtitle)
	subtitle.position = Vector2(420, 210)
	
	# Play button
	var play_btn = Button.new()
	play_btn.text = "🎁 PLAY"
	play_btn.custom_minimum_size = Vector2(200, 80)
	play_btn.add_theme_font_size_override("font_size", 32)
	style_button(play_btn, Color(0.2, 0.7, 0.2))
	play_btn.pressed.connect(_on_play_pressed)
	add_child(play_btn)
	play_btn.position = Vector2(500, 320)
	
	# Reset Progress Button
	var reset_btn = Button.new()
	reset_btn.text = "⚠️ RESET PROGRESS"
	reset_btn.custom_minimum_size = Vector2(180, 40)
	reset_btn.position = Vector2(980, 20)
	reset_btn.add_theme_font_size_override("font_size", 14)
	style_button(reset_btn, Color(0.8, 0.2, 0.2))
	reset_btn.pressed.connect(_on_reset_pressed)
	add_child(reset_btn)
	
	# Decorations - simple trees
	add_tree(100, 400)
	add_tree(200, 420)
	add_tree(1000, 410)
	add_tree(1100, 430)
	
	# Snowflakes
	for i in range(30):
		add_snowflake()

func add_tree(x: float, y: float) -> void:
	var tree = Polygon2D.new()
	tree.color = Color(0.1, 0.4, 0.15)
	tree.polygon = PackedVector2Array([
		Vector2(0, -60), Vector2(30, 0), Vector2(-30, 0)
	])
	tree.position = Vector2(x, y)
	add_child(tree)
	
	var trunk = Polygon2D.new()
	trunk.color = Color(0.4, 0.25, 0.15)
	trunk.polygon = PackedVector2Array([
		Vector2(-8, 0), Vector2(8, 0), Vector2(8, 20), Vector2(-8, 20)
	])
	trunk.position = Vector2(x, y)
	add_child(trunk)

func add_snowflake() -> void:
	var flake = Label.new()
	flake.text = "❄"
	flake.position = Vector2(randf() * 1200, randf() * 400)
	flake.add_theme_font_size_override("font_size", randi_range(12, 24))
	flake.modulate.a = randf_range(0.3, 0.8)
	add_child(flake)
	
	# Animate falling
	var tween = create_tween().set_loops()
	tween.tween_property(flake, "position:y", 500.0, randf_range(3.0, 8.0))
	tween.tween_callback(func(): flake.position.y = -20; flake.position.x = randf() * 1200)

func style_button(btn: Button, color: Color) -> void:
	var style = StyleBoxFlat.new()
	style.bg_color = color
	style.corner_radius_top_left = 12
	style.corner_radius_top_right = 12
	style.corner_radius_bottom_left = 12
	style.corner_radius_bottom_right = 12
	style.border_width_left = 3
	style.border_width_right = 3
	style.border_width_top = 3
	style.border_width_bottom = 3
	style.border_color = Color.WHITE
	btn.add_theme_stylebox_override("normal", style)
	
	var hover = style.duplicate()
	hover.bg_color = color.lightened(0.2)
	btn.add_theme_stylebox_override("hover", hover)
	
	btn.add_theme_color_override("font_color", Color.WHITE)

func _on_play_pressed() -> void:
	if LevelManager:
		LevelManager.go_to_level_select()
	else:
		get_tree().change_scene_to_file("res://scenes/level_select.tscn")

func _on_reset_pressed() -> void:
	if LevelManager:
		LevelManager.reset_progress()
		print("Progress Reset!")
		get_tree().reload_current_scene()
