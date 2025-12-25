extends Control

## Level Select - Snowy village with house icons

const HOUSE_SPACING = 200
const HOUSE_Y = 350

func _ready() -> void:
	setup_ui()

func setup_ui() -> void:
	# Background - night sky
	var bg = ColorRect.new()
	bg.color = Color(0.02, 0.05, 0.15, 1)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	
	# Stars
	for i in range(50):
		var star = Label.new()
		star.text = "✦"
		star.position = Vector2(randf() * 1200, randf() * 300)
		star.add_theme_font_size_override("font_size", randi_range(8, 16))
		star.add_theme_color_override("font_color", Color(1, 1, 0.9, randf_range(0.3, 0.9)))
		add_child(star)
	
	# Snow ground
	var ground = ColorRect.new()
	ground.color = Color(0.9, 0.95, 1.0, 1)
	ground.position = Vector2(0, 420)
	ground.size = Vector2(1200, 180)
	add_child(ground)
	
	# Snow hills
	var hill1 = Polygon2D.new()
	hill1.color = Color(0.85, 0.9, 0.95, 1)
	hill1.polygon = PackedVector2Array([
		Vector2(0, 450), Vector2(300, 380), Vector2(500, 420), Vector2(500, 450)
	])
	add_child(hill1)
	
	var hill2 = Polygon2D.new()
	hill2.color = Color(0.88, 0.92, 0.97, 1)
	hill2.polygon = PackedVector2Array([
		Vector2(700, 450), Vector2(900, 390), Vector2(1200, 430), Vector2(1200, 450)
	])
	add_child(hill2)
	
	# Title
	var title = Label.new()
	title.text = "🏠 SELECT LEVEL 🏠"
	title.position = Vector2(400, 30)
	title.add_theme_font_size_override("font_size", 40)
	title.add_theme_color_override("font_color", Color(1.0, 0.95, 0.8))
	add_child(title)
	
	# House icons for each level
	var start_x = 150
	
	# Identify the "Next Playable Level" (Latest Unlocked)
	# Iterate backwards or iterate forwards and keep updating "latest"
	var next_playable_index = -1
	for i in range(LevelManager.levels.size()):
		var level = LevelManager.levels[i]
		if LevelManager.is_level_unlocked(level.id):
			# If unlocked, it's a candidate.
			# Ideally we want the first *incomplete* level, OR if all are complete, just the last one.
			# But "latest unlocked" usually implies progress. 
			# Let's say: The highest index that is unlocked.
			next_playable_index = i
			# If valid, check if completed? 
			# If completed, we might still want to wiggle the *next* locked one? No, we can't play locked ones.
			# So, wiggle the highest unlocked level.
	
	for i in range(LevelManager.levels.size()):
		var level = LevelManager.levels[i]
		var should_wiggle = (i == next_playable_index)
		create_house(start_x + i * HOUSE_SPACING, HOUSE_Y, level, should_wiggle)
	
	# Back button
	var back_btn = Button.new()
	back_btn.text = "← Back"
	back_btn.position = Vector2(20, 20)
	back_btn.custom_minimum_size = Vector2(100, 40)
	style_button(back_btn, Color(0.5, 0.5, 0.5))
	back_btn.pressed.connect(_on_back_pressed)
	add_child(back_btn)
	
	# Falling snow
	for i in range(20):
		add_snowflake()

func create_house(x: float, y: float, level: Dictionary, should_wiggle: bool) -> void:
	var container = Control.new()
	container.position = Vector2(x, y)
	# Center pivot for rotation/scale
	# House width is ~80 (-40 to 40), height ~50.
	# Let's pivot at bottom center (0, 50) or center (0, 25)? 
	# User wants rotational wiggle. Center of mass (0, 25) usually looks best for that.
	# But drawing is from (0,0) down to 50. Wait, polygon is (-40, 0) to (40, 50).
	# So (0,0) is top center of base. Roof is above.
	# Let's pivot around (0, 20) roughly.
	# Control node pivot usually matters for scale/rotation.
	# We'll set pivot offset if we want to rotate the container.
	# BUT, Control nodes don't have "pivot_offset" in Godot 3.x easily without rect_pivot_offset.
	# In Godot 4.x it's pivot_offset. 
	# Let's assume Godot 4.x semantics (as seen with TextServer usage earlier).
	container.pivot_offset = Vector2(0, 25) 
	
	add_child(container)
	
	var is_unlocked = LevelManager.is_level_unlocked(level.id)
	var is_completed = LevelManager.is_level_completed(level.id)
	
	# House base
	var house = Polygon2D.new()
	if is_unlocked:
		house.color = Color(0.6, 0.3, 0.2) if not is_completed else Color(0.5, 0.35, 0.25)
	else:
		house.color = Color(0.3, 0.3, 0.3)  # Locked - gray
	house.polygon = PackedVector2Array([
		Vector2(-40, 0), Vector2(40, 0), Vector2(40, 50), Vector2(-40, 50)
	])
	container.add_child(house)
	
	# Roof
	var roof = Polygon2D.new()
	if is_unlocked:
		roof.color = Color(0.7, 0.2, 0.15)
	else:
		roof.color = Color(0.4, 0.4, 0.4)
	roof.polygon = PackedVector2Array([
		Vector2(-50, 0), Vector2(0, -40), Vector2(50, 0)
	])
	container.add_child(roof)
	
	# Snow on roof
	var snow_roof = Polygon2D.new()
	snow_roof.color = Color(1, 1, 1)
	snow_roof.polygon = PackedVector2Array([
		Vector2(-45, -3), Vector2(0, -38), Vector2(45, -3), Vector2(0, -30)
	])
	container.add_child(snow_roof)
	
	# Door
	var door = Polygon2D.new()
	door.color = Color(0.35, 0.2, 0.1)
	door.polygon = PackedVector2Array([
		Vector2(-10, 20), Vector2(10, 20), Vector2(10, 50), Vector2(-10, 50)
	])
	container.add_child(door)
	
	# Window with light (if completed)
	var window = Polygon2D.new()
	if is_completed:
		window.color = Color(1, 0.9, 0.5)  # Warm light
	elif is_unlocked:
		window.color = Color(0.4, 0.5, 0.6)  # Dark window
	else:
		window.color = Color(0.25, 0.25, 0.25)
	window.polygon = PackedVector2Array([
		Vector2(-25, 8), Vector2(-10, 8), Vector2(-10, 18), Vector2(-25, 18)
	])
	container.add_child(window)
	
	var window2 = window.duplicate()
	window2.position.x = 35
	container.add_child(window2)
	
	# Chimney
	var chimney = Polygon2D.new()
	chimney.color = Color(0.5, 0.25, 0.2)
	chimney.polygon = PackedVector2Array([
		Vector2(20, -30), Vector2(35, -30), Vector2(35, -10), Vector2(20, -10)
	])
	container.add_child(chimney)
	
	# Lock icon if locked
	if not is_unlocked:
		var lock = Label.new()
		lock.text = "🔒"
		lock.position = Vector2(-15, 5)
		lock.add_theme_font_size_override("font_size", 30)
		container.add_child(lock)
	
	# Star if completed
	if is_completed:
		var star = Label.new()
		star.text = "⭐"
		star.position = Vector2(-15, -70)
		star.add_theme_font_size_override("font_size", 30)
		container.add_child(star)
	
	# Level name
	var name_label = Label.new()
	name_label.text = level.name
	name_label.position = Vector2(-60, 55)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.custom_minimum_size = Vector2(120, 20)
	name_label.add_theme_font_size_override("font_size", 14)
	if is_unlocked:
		name_label.add_theme_color_override("font_color", Color(0.2, 0.6, 0.2)) # Lighter Green
	else:
		name_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
	container.add_child(name_label)
	
	# Clickable button (invisible)
	if is_unlocked:
		var btn = Button.new()
		btn.flat = true
		btn.focus_mode = Control.FOCUS_NONE
		btn.position = Vector2(-50, -50) # Improve click area (cover roof too)
		btn.custom_minimum_size = Vector2(100, 110)
		btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		btn.pressed.connect(_on_level_pressed.bind(level.id))
		
		# Hover Scaling
		btn.mouse_entered.connect(func(): 
			var tween = create_tween()
			tween.tween_property(container, "scale", Vector2(1.1, 1.1), 0.1)
		)
		btn.mouse_exited.connect(func():
			var tween = create_tween()
			tween.tween_property(container, "scale", Vector2(1.0, 1.0), 0.1)
		)
		
		container.add_child(btn)
	
	# Wiggle Effect
	if should_wiggle and is_unlocked:
		var wiggle_tween = create_tween().set_loops()
		wiggle_tween.tween_property(container, "rotation", 0.05, 0.1)
		wiggle_tween.tween_property(container, "rotation", -0.05, 0.1)
		wiggle_tween.tween_property(container, "rotation", 0.0, 0.1)
		wiggle_tween.tween_interval(1.5) # Wait 1.5s between wiggles

func add_snowflake() -> void:
	var flake = Label.new()
	flake.text = "❄"
	flake.position = Vector2(randf() * 1200, randf() * 400)
	flake.add_theme_font_size_override("font_size", randi_range(10, 20))
	flake.modulate.a = randf_range(0.2, 0.6)
	add_child(flake)
	
	var tween = create_tween().set_loops()
	tween.tween_property(flake, "position:y", 550.0, randf_range(4.0, 10.0))
	tween.tween_callback(func(): flake.position.y = -20; flake.position.x = randf() * 1200)

func style_button(btn: Button, color: Color) -> void:
	btn.focus_mode = Control.FOCUS_NONE
	var style = StyleBoxFlat.new()
	style.bg_color = color
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	btn.add_theme_stylebox_override("normal", style)
	btn.add_theme_color_override("font_color", Color.WHITE)

func _on_level_pressed(level_id: String) -> void:
	print("Loading level: ", level_id)
	LevelManager.load_level(level_id)

func _on_back_pressed() -> void:
	LevelManager.go_to_main_menu()
