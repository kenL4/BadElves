extends PartBase
class_name GiftBox

## Gift Box - Basic structural building block

func _ready() -> void:
	super._ready()
	part_name = "Gift Box"
	part_color = Color(0.8, 0.2, 0.2)  # Christmas red
	mass = 2.0

func get_part_type() -> String:
	return "gift_box"

func should_connect_to(other_part: PartBase) -> bool:
	# Gift boxes connect to everything nearby
	return true
