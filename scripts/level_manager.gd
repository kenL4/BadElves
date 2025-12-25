extends Node

## Level Manager - Autoload singleton for level/save management

signal level_changed(level_id: String)
signal level_completed(level_id: String)

const SAVE_PATH = "user://save.dat"

# Level definitions with build zone info
var levels: Array[Dictionary] = [
	{
		"id": "tutorial",
		"name": "Tutorial",
		"scene": "res://scenes/levels/level_tutorial.tscn",
		"parts": ["gift_box", "wheel", "elf"],
		"unlocked": true,
		"build_zone_start": Vector2(200, 200),
		"build_zone_size": Vector2(6, 4)
	},
	{
		"id": "level_01",
		"name": "First Delivery",
		"scene": "res://scenes/levels/level_01.tscn",
		"parts": ["gift_box", "wheel", "elf"],
		"unlocked": false,
		"build_zone_start": Vector2(200, 200),
		"build_zone_size": Vector2(6, 4)
	},
	{
		"id": "level_02",
		"name": "Steep Hill",
		"scene": "res://scenes/levels/level_02.tscn",
		"parts": ["gift_box", "wheel", "elf"],
		"unlocked": false,
		"build_zone_start": Vector2(150, 264),
		"build_zone_size": Vector2(6, 3)
	},
	{
		"id": "level_03",
		"name": "Mind the Gap",
		"scene": "res://scenes/levels/level_03.tscn",
		"parts": ["gift_box", "wheel", "elf"],
		"unlocked": false,
		"build_zone_start": Vector2(100, 214),
		"build_zone_size": Vector2(6, 3)
	},
	{
		"id": "level_04",
		"name": "Rocky Road",
		"scene": "res://scenes/levels/level_04.tscn",
		"parts": ["gift_box", "wheel", "elf"],
		"unlocked": false,
		"build_zone_start": Vector2(150, 264),
		"build_zone_size": Vector2(6, 3)
	}
]

var current_level_id: String = ""
var completed_levels: Array[String] = []

func _ready() -> void:
	load_progress()

func get_level(level_id: String) -> Dictionary:
	for level in levels:
		if level.id == level_id:
			return level
	return {}

func get_current_level() -> Dictionary:
	return get_level(current_level_id)

func is_level_unlocked(level_id: String) -> bool:
	var level = get_level(level_id)
	if level.is_empty():
		return false
	return level.unlocked or completed_levels.has(level_id)

func is_level_completed(level_id: String) -> bool:
	return completed_levels.has(level_id)

func is_last_level(level_id: String) -> bool:
	for i in range(levels.size()):
		if levels[i].id == level_id:
			return i == levels.size() - 1
	return false

func complete_current_level() -> void:
	if current_level_id.is_empty():
		return
	
	if not completed_levels.has(current_level_id):
		completed_levels.append(current_level_id)
		level_completed.emit(current_level_id)
		unlock_next_level()
		save_progress()

func unlock_next_level() -> void:
	var found_current = false
	for level in levels:
		if found_current:
			level.unlocked = true
			print("Unlocked level: ", level.name)
			break
		if level.id == current_level_id:
			found_current = true

func load_level(level_id: String) -> void:
	var level = get_level(level_id)
	if level.is_empty():
		push_error("Level not found: " + level_id)
		return
	
	if not is_level_unlocked(level_id):
		push_error("Level is locked: " + level_id)
		return
	
	current_level_id = level_id
	level_changed.emit(level_id)
	get_tree().change_scene_to_file("res://scenes/main.tscn")

func get_current_level_scene() -> String:
	var level = get_level(current_level_id)
	if level.is_empty():
		return ""
	return level.scene

func go_to_level_select() -> void:
	current_level_id = ""
	get_tree().change_scene_to_file("res://scenes/level_select.tscn")

func go_to_main_menu() -> void:
	current_level_id = ""
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")

func save_progress() -> void:
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		var data = {
			"completed": completed_levels,
			"unlocked": []
		}
		for level in levels:
			if level.unlocked:
				data.unlocked.append(level.id)
		file.store_string(JSON.stringify(data))
		file.close()

func load_progress() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	
	var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file:
		var json = JSON.new()
		var result = json.parse(file.get_as_text())
		file.close()
		
		if result == OK:
			var data = json.data
			if data.has("completed"):
				completed_levels = Array(data.completed, TYPE_STRING, "", null)
			if data.has("unlocked"):
				for level_id in data.unlocked:
					var level = get_level(level_id)
					if not level.is_empty():
						level.unlocked = true
						
			# Auto-correction: Ensure next levels are unlocked if previous is complete
			for i in range(levels.size() - 1):
				if completed_levels.has(levels[i].id):
					levels[i+1].unlocked = true

func reset_progress() -> void:
	completed_levels.clear()
	for level in levels:
		level.unlocked = (level.id == "tutorial")
	save_progress()
