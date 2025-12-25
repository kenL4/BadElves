extends PartBase
class_name Elf

## The Elf - Must survive and reach the chimney!

signal elf_reached_goal
signal elf_died

var is_alive: bool = true

func _ready() -> void:
	super._ready()
	part_name = "Elf"
	part_color = Color(0.2, 0.8, 0.2)  # Christmas green
	mass = 0.5
	
	# Connect area detection for goal/hazards
	var area = Area2D.new()
	area.name = "DetectionArea"
	var collision = CollisionShape2D.new()
	var shape = CircleShape2D.new()
	shape.radius = 20
	collision.shape = shape
	area.add_child(collision)
	add_child(area)
	area.body_entered.connect(_on_body_entered)
	# area_entered no longer needed for goal (handled by base)

func get_part_type() -> String:
	return "elf"

func _on_body_entered(body: Node2D) -> void:
	# Check for hazards
	if body.is_in_group("hazard"):
		die()



func reach_goal() -> void:
	if not is_alive:
		return
	elf_reached_goal.emit()
	if GameManager:
		GameManager.complete_level()

func die() -> void:
	is_alive = true  # Can be set to false for death mechanic
	elf_died.emit()

func get_attachment_points() -> Array[Vector2]:
	# Elf can attach from bottom (sits on things)
	return [Vector2(0, 16)]

func start_physics() -> void:
	super.start_physics()
	is_alive = true

func stop_physics() -> void:
	super.stop_physics()
	is_alive = true
