extends Node2D

## Main Game Scene - Loads the current level dynamically

var game_world: Node2D = null

func _ready() -> void:
	load_current_level()
	
	# Setup game manager for this level's build zone
	if GameManager:
		GameManager.setup_for_level()
		# Ensure we start in BUILD mode (resetting any leftover state from previous level)
		if GameManager.current_state != GameManager.GameState.BUILD:
			GameManager.stop_play()
		# Clear any parts from previous level memory if not already clear
		GameManager.clear_all_parts()
	
	# Add dynamic camera
	var cam = Camera2D.new()
	cam.script = load("res://scripts/camera_controller.gd")
	add_child(cam)
	cam.make_current()
	
	# Wait for scene to be ready, then start tutorial if needed
	await get_tree().process_frame
	await get_tree().process_frame
	
	if LevelManager and LevelManager.current_level_id == "tutorial":
		if TutorialManager:
			TutorialManager.start_tutorial()

func load_current_level() -> void:
	if not LevelManager:
		push_error("LevelManager not found!")
		return
	
	var level_scene_path = LevelManager.get_current_level_scene()
	if level_scene_path.is_empty():
		push_error("No level scene to load!")
		return
	
	print("Loading level scene: ", level_scene_path)
	
	var level_scene = load(level_scene_path)
	if not level_scene:
		push_error("Could not load level: " + level_scene_path)
		return
	
	# Remove placeholder if exists
	var placeholder = get_node_or_null("GameWorld")
	if placeholder:
		placeholder.queue_free()
	
	# Instance and add the level
	game_world = level_scene.instantiate()
	game_world.name = "GameWorld"
	add_child(game_world)
	move_child(game_world, 0)
	
	setup_environment()
	
	print("Level loaded: ", LevelManager.current_level_id)

func setup_environment() -> void:
	if not game_world:
		return
	
	# Find background to determine size and layer order
	var bg = game_world.get_node_or_null("Background")
	var scene_width = 2500.0 # Default fallback
	var bg_index = 0
	
	if bg:
		bg_index = bg.get_index()
		if bg is ColorRect:
			scene_width = bg.size.x
		elif bg is Polygon2D:
			# Estimate from polygon bounds? Fallback is safer for now.
			pass
	
	# Create a container for environment to keep scene tree clean
	# and to manage draw order easily
	var env_container = Node2D.new()
	env_container.name = "Environment"
	game_world.add_child(env_container)
	
	# Place container immediately after background so it draws ON TOP of background
	# but BEHIND everything else (Terrain, BuildZone, etc.)
	game_world.move_child(env_container, bg_index + 1)
		
	# 1. Stars
	var star_count = 100
	for i in range(star_count):
		var star = Label.new()
		star.text = "✦" if randf() > 0.3 else "."
		
		# Generate across the full scene width
		var sx = randf_range(0, scene_width)
		var sy = randf() * 400
		
		star.position = Vector2(sx, sy)
		star.modulate = Color(1, 1, 0.9, randf_range(0.2, 0.8))
		star.add_theme_font_size_override("font_size", randi_range(8, 16))
		# No z_index needed, rely on Scene Tree order (Environment > Background)
		env_container.add_child(star)
	
	# 2. Trees (Background)
	var tree_count = int(scene_width / 80.0) # Density based on width
	for i in range(tree_count):
		var tree = Node2D.new()
		
		var tx = randf_range(0, scene_width)
		var ty = randf_range(450, 520)
		
		tree.position = Vector2(tx, ty)
		tree.scale = Vector2(randf_range(0.8, 1.5), randf_range(0.8, 1.5))
		
		# Tree Trunk
		var trunk = Polygon2D.new()
		trunk.color = Color(0.4, 0.3, 0.2)
		trunk.polygon = PackedVector2Array([
			Vector2(-5, 0), Vector2(5, 0), Vector2(5, -20), Vector2(-5, -20)
		])
		tree.add_child(trunk)
		
		# Tree Leaves (Triangle)
		var leaves = Polygon2D.new()
		leaves.color = Color(0.1, randf_range(0.3, 0.5), 0.2) # Varied green
		leaves.polygon = PackedVector2Array([
			Vector2(-30, -15), Vector2(30, -15), Vector2(0, -90)
		])
		tree.add_child(leaves)
		
		# Snow on tree
		var snow = Polygon2D.new()
		snow.color = Color(0.9, 0.95, 1.0, 0.9)
		snow.polygon = PackedVector2Array([
			Vector2(-20, -25), Vector2(20, -25), Vector2(0, -80) # Slightly smaller triangle tip
		])
		tree.add_child(snow)
		
		env_container.add_child(tree)
