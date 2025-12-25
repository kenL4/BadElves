extends Node2D

## Build System - Handles drag and drop part placement

signal part_placed(part: Node2D)
signal part_removed(part: Node2D)

var game_world: Node2D = null
var current_ghost: Node2D = null
var current_part_scene: PackedScene = null
var is_dragging: bool = false

# Part scenes
var part_scenes: Dictionary = {}

func _ready() -> void:
	# Wait a frame for scene to be ready
	await get_tree().process_frame
	
	# Get game world reference
	game_world = get_node_or_null("/root/Main/GameWorld")
	if not game_world:
		push_error("BuildSystem: Could not find GameWorld node!")
	
	# Load part scenes
	part_scenes = {
		"gift_box": preload("res://scenes/parts/gift_box.tscn"),
		"wheel": preload("res://scenes/parts/wheel.tscn"),
		"elf": preload("res://scenes/parts/elf.tscn")
	}
	
	if GameManager:
		GameManager.state_changed.connect(_on_game_state_changed)

func _on_game_state_changed(new_state) -> void:
	if new_state == GameManager.GameState.PLAY:
		cancel_drag()

func _process(_delta: float) -> void:
	if current_ghost and is_dragging:
		update_ghost_position()

func _input(event: InputEvent) -> void:
	if GameManager and GameManager.current_state != GameManager.GameState.BUILD:
		return
	
	if event is InputEventMouseButton and event.pressed:
		var mouse_pos = get_global_mouse_position()
		
		if event.button_index == MOUSE_BUTTON_LEFT:
			if is_dragging:
				# Check if mouse is in game area (not over UI)
				if mouse_pos.x > 150:  # Past the left UI panel
					try_place_part()
		
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			if is_dragging:
				# Cancel current drag
				cancel_drag()
			else:
				# Try to delete a part at mouse position
				try_delete_part_at(mouse_pos)

func try_delete_part_at(pos: Vector2) -> void:
	# Find the closest part to the click position
	var closest_part: Node2D = null
	var closest_distance: float = 40.0  # Max distance to detect click
	
	for part in GameManager.placed_parts:
		var dist = part.global_position.distance_to(pos)
		if dist < closest_distance:
			closest_distance = dist
			closest_part = part
	
	if closest_part:
		print("Deleting part at: ", closest_part.global_position)
		if closest_part.has_method("remove"):
			closest_part.remove()
		else:
			GameManager.unregister_part(closest_part)
			closest_part.queue_free()

func start_drag(part_type: String) -> void:
	if GameManager and GameManager.current_state != GameManager.GameState.BUILD:
		return
	
	if not part_scenes.has(part_type):
		push_error("Unknown part type: " + part_type)
		return
	
	# Clear any existing ghost
	if current_ghost:
		current_ghost.queue_free()
		current_ghost = null
	
	current_part_scene = part_scenes[part_type]
	
	# Create ghost preview
	current_ghost = current_part_scene.instantiate()
	current_ghost.modulate.a = 0.5
	current_ghost.freeze = true
	# Disable all collision on ghost
	current_ghost.set_collision_layer_value(1, false)
	current_ghost.set_collision_layer_value(2, false)
	current_ghost.set_collision_mask_value(1, false)
	current_ghost.set_collision_mask_value(2, false)
	add_child(current_ghost)
	
	is_dragging = true
	update_ghost_position()
	print("Started dragging: ", part_type)

func update_ghost_position() -> void:
	if not current_ghost:
		return
	
	var mouse_pos = get_global_mouse_position()
	var snapped_pos = GameManager.snap_to_grid(mouse_pos)
	current_ghost.global_position = snapped_pos
	
	# Update ghost color based on validity
	if can_place_at(snapped_pos):
		current_ghost.modulate = Color(0.5, 1.0, 0.5, 0.7)  # Green = valid
	else:
		current_ghost.modulate = Color(1.0, 0.5, 0.5, 0.7)  # Red = invalid

func can_place_at(pos: Vector2) -> bool:
	if not GameManager.is_in_build_zone(pos):
		return false
	if GameManager.is_position_occupied(pos):
		return false
	return true

func try_place_part() -> void:
	if not current_ghost or not current_part_scene:
		cancel_drag()
		return
	
	var pos = current_ghost.global_position
	
	# Check tutorial position restriction
	if TutorialManager and TutorialManager.is_active:
		if not TutorialManager.is_build_position_allowed(pos):
			print("Tutorial: Must place at highlighted position")
			return  # Don't cancel drag, let them try again
	
	print("Trying to place at: ", pos, " - can_place: ", can_place_at(pos))
	
	if can_place_at(pos):
		if not game_world:
			game_world = get_node_or_null("/root/Main/GameWorld")
		
		if game_world:
			# Create the actual part
			var new_part = current_part_scene.instantiate()
			game_world.add_child(new_part)
			new_part.place_at(pos)
			
			# Pop Animation (Visuals only, do not scale RigidBody!)
			animate_part_pop(new_part)
			
			# Connect to nearby parts
			connect_to_nearby_parts(new_part)
			
			part_placed.emit(new_part)
			print("Successfully placed part at: ", pos)
			
			# Notify tutorial
			if TutorialManager and TutorialManager.is_active:
				TutorialManager.on_event("part_placed")
		else:
			push_error("BuildSystem: game_world is null!")
	else:
		print("Cannot place at: ", pos)
		# Only cancel if we couldn't place (optional, maybe better to keep trying?)
		# For now, let's keep it selected even on fail so they can move slightly and try again
		pass

func cancel_drag() -> void:
	if current_ghost:
		current_ghost.queue_free()
		current_ghost = null
	current_part_scene = null
	is_dragging = false

func connect_to_nearby_parts(new_part: Node2D) -> void:
	if not new_part.has_method("create_connection_to"):
		return
	
	for other_part in GameManager.placed_parts:
		if other_part == new_part:
			continue
		
		var distance = new_part.global_position.distance_to(other_part.global_position)
		if distance <= GameManager.GRID_SIZE * 1.5:
			new_part.create_connection_to(other_part)

func animate_part_pop(part: Node2D) -> void:
	for child in part.get_children():
		# Skip physics nodes to prevent breaking joints
		if child is CollisionShape2D or child is CollisionPolygon2D or child is Joint2D:
			continue
		
		# Animate visuals (Polygons, Sprites, Labels, etc.)
		if child is Node2D or child is Control:
			child.scale = Vector2(0.1, 0.1)
			var tween = create_tween()
			tween.tween_property(child, "scale", Vector2(1.2, 1.2), 0.15).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
			tween.tween_property(child, "scale", Vector2(1.0, 1.0), 0.1)
