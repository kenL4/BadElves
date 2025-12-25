extends Node

## Game Manager - Autoload singleton managing game state

signal state_changed(new_state)
signal level_completed
signal level_failed

signal show_error(message)

enum GameState { BUILD, PLAY, PAUSED, COMPLETE }


var current_state: GameState = GameState.BUILD
var placed_parts: Array[Node2D] = []
var elf_node: Node2D = null

# Grid settings
const GRID_SIZE: int = 64
var build_zone_start: Vector2 = Vector2(200, 200)
var build_zone_size: Vector2 = Vector2(6, 4)

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("restart"):
		restart_level()
	if event.is_action_pressed("toggle_play"):
		# Check tutorial restrictions
		if TutorialManager and TutorialManager.is_active:
			if not TutorialManager.is_click_allowed("play_button"):
				return
		toggle_play_mode()

func setup_for_level() -> void:
	# Get build zone from current level
	if LevelManager:
		var level = LevelManager.get_current_level()
		if not level.is_empty():
			build_zone_start = level.get("build_zone_start", Vector2(200, 200))
			build_zone_size = level.get("build_zone_size", Vector2(6, 4))
			print("Build zone set: ", build_zone_start, " size: ", build_zone_size)

func toggle_play_mode() -> void:
	if current_state == GameState.BUILD:
		start_play()
	elif current_state == GameState.PLAY:
		stop_play()

func start_play() -> void:
	if placed_parts.size() == 0:
		print("No parts placed!")
		show_error.emit("Place some parts first!")
		return
	
	if not elf_node:
		print("Cannot play: No elf placed!")
		show_error.emit("Missing Pilot! Add an Elf!")
		return
	
	current_state = GameState.PLAY
	
	for part in placed_parts:
		if part.has_method("start_physics"):
			part.start_physics()
	
	state_changed.emit(current_state)
	
	if TutorialManager and TutorialManager.is_active:
		TutorialManager.on_event("play_started")

func stop_play() -> void:
	current_state = GameState.BUILD
	
	for part in placed_parts:
		if part.has_method("stop_physics"):
			part.stop_physics()
	
	state_changed.emit(current_state)

func restart_level() -> void:
	stop_play()
	clear_all_parts()

func complete_level() -> void:
	current_state = GameState.COMPLETE
	level_completed.emit()
	state_changed.emit(current_state)
	
	if LevelManager:
		LevelManager.complete_current_level()
	
	if TutorialManager and TutorialManager.is_active:
		TutorialManager.on_event("level_complete")

func register_part(part: Node2D) -> void:
	if not placed_parts.has(part):
		placed_parts.append(part)
		if part.has_method("get_part_type") and part.get_part_type() == "elf":
			elf_node = part

func unregister_part(part: Node2D) -> void:
	placed_parts.erase(part)
	if part == elf_node:
		elf_node = null

func clear_all_parts() -> void:
	for part in placed_parts.duplicate():
		part.queue_free()
	placed_parts.clear()
	elf_node = null

func snap_to_grid(pos: Vector2) -> Vector2:
	var cell_x = floori((pos.x - build_zone_start.x) / GRID_SIZE)
	var cell_y = floori((pos.y - build_zone_start.y) / GRID_SIZE)
	var snapped_x = build_zone_start.x + cell_x * GRID_SIZE + GRID_SIZE / 2
	var snapped_y = build_zone_start.y + cell_y * GRID_SIZE + GRID_SIZE / 2
	return Vector2(snapped_x, snapped_y)

func is_in_build_zone(pos: Vector2) -> bool:
	var zone_end = build_zone_start + build_zone_size * GRID_SIZE
	return pos.x >= build_zone_start.x and pos.x < zone_end.x and \
		   pos.y >= build_zone_start.y and pos.y < zone_end.y

func is_position_occupied(pos: Vector2) -> bool:
	var snapped = snap_to_grid(pos)
	for part in placed_parts:
		if part.global_position.distance_to(snapped) < GRID_SIZE / 2:
			return true
	return false
