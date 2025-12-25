extends RigidBody2D
class_name PartBase

## Base class for all building parts

@export var part_name: String = "Part"
@export var part_color: Color = Color.WHITE

var build_position: Vector2
var build_rotation: float
var is_placed: bool = false
var is_being_dragged: bool = false
var connected_parts: Array[PartBase] = []
var joints: Array[Joint2D] = []
var visual_joints_map: Dictionary = {} # Map<PartBase, Node2D>

func _ready() -> void:
	# Start in build mode (frozen)
	freeze = true
	input_pickable = true
	
	# Connect to game manager signals
	if GameManager:
		GameManager.state_changed.connect(_on_state_changed)
	
	# Setup goal detection for dynamic parts
	call_deferred("_setup_goal_detection")

func get_part_type() -> String:
	return "base"

func _on_state_changed(new_state: int) -> void:
	pass  # Override in subclasses

func start_physics() -> void:
	# Store build position for reset
	if build_position == Vector2.ZERO:
		build_position = global_position
		build_rotation = rotation
	# Enable physics
	freeze = false
	input_pickable = false  # Disable picking during play

func stop_physics() -> void:
	# Disable physics first
	freeze = true
	sleeping = true  # Force sleep
	
	linear_velocity = Vector2.ZERO
	angular_velocity = 0
	constant_force = Vector2.ZERO
	constant_torque = 0
	
	# Reset to build position
	global_position = build_position
	rotation = build_rotation
	
	# Force update physics server to match visual immediately
	# This prevents "memory" of old position/velocity when unfreezing
	PhysicsServer2D.body_set_state(get_rid(), PhysicsServer2D.BODY_STATE_TRANSFORM, global_transform)
	PhysicsServer2D.body_set_state(get_rid(), PhysicsServer2D.BODY_STATE_LINEAR_VELOCITY, Vector2.ZERO)
	PhysicsServer2D.body_set_state(get_rid(), PhysicsServer2D.BODY_STATE_ANGULAR_VELOCITY, 0.0)
	
	input_pickable = true  # Re-enable picking in build mode

func place_at(pos: Vector2) -> void:
	global_position = pos
	build_position = pos
	build_rotation = 0
	rotation = 0
	is_placed = true
	if GameManager:
		GameManager.register_part(self)

func remove() -> void:
	print("Removing part: ", part_name)
	# Remove all joints
	for joint in joints:
		if is_instance_valid(joint):
			joint.queue_free()
	joints.clear()
	
	# Remove from connected parts using safe callback
	for other in connected_parts:
		if is_instance_valid(other):
			other.on_neighbor_removed(self)
	connected_parts.clear()
	
	if GameManager:
		GameManager.unregister_part(self)
	queue_free()

func on_neighbor_removed(neighbor: PartBase) -> void:
	# Clean up logic when a neighbor is deleted
	if connected_parts.has(neighbor):
		connected_parts.erase(neighbor)
	
	# Remove any visual joint connecting to this neighbor
	if visual_joints_map.has(neighbor):
		var visual = visual_joints_map[neighbor]
		if is_instance_valid(visual):
			visual.queue_free()
		visual_joints_map.erase(neighbor)

func _input_event(_viewport: Viewport, event: InputEvent, _shape_idx: int) -> void:
	if GameManager and GameManager.current_state != GameManager.GameState.BUILD:
		return
	
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			print("Right-click detected on: ", part_name)
			remove()

func get_attachment_points() -> Array[Vector2]:
	# Override in subclasses - returns local positions where other parts can attach
	return [
		Vector2(-32, 0),  # Left
		Vector2(32, 0),   # Right
		Vector2(0, -32),  # Top
		Vector2(0, 32)    # Bottom
	]

func can_rotate_freely() -> bool:
	# Override in wheel to return true
	return false

func should_connect_to(other_part: PartBase) -> bool:
	# Override in subclasses to restrict connections
	# Default: connect to anything nearby
	return true

func create_connection_to(other_part: PartBase) -> void:
	if connected_parts.has(other_part):
		return
	
	# Check if both parts want to connect to each other
	if not should_connect_to(other_part) or not other_part.should_connect_to(self):
		print("Skipping connection between ", part_name, " and ", other_part.part_name)
		return
	
	# Determine which part should be the "axle" (the one that rotates)
	var rotating_part: PartBase = null
	var fixed_part: PartBase = null
	
	if can_rotate_freely():
		rotating_part = self
		fixed_part = other_part
	elif other_part.can_rotate_freely():
		rotating_part = other_part
		fixed_part = self
	
	if rotating_part:
		# Single joint for wheel - allows free rotation around axle
		var joint = PinJoint2D.new()
		joint.node_a = rotating_part.get_path()
		joint.node_b = fixed_part.get_path()
		joint.position = Vector2.ZERO  # Center of wheel
		joint.softness = 0.0  # Tight connection
		rotating_part.add_child(joint)
		rotating_part.joints.append(joint)
		
		# VISUAL STRUT FOR WHEEL
		# We attach the visual to the FIXED part (chassis) so it doesn't spin.
		# We place it at the center of the wheel (relative to the chassis).
		var wheel_center_local = fixed_part.to_local(rotating_part.global_position)
		fixed_part.add_wheel_strut(rotating_part, wheel_center_local)
		
	else:
		# RIGID connection - use TWO joints to prevent rotation
		# This locks both position AND rotation between the parts
		var offset = (other_part.global_position - global_position).normalized() * 20
		
		# First joint
		var joint1 = PinJoint2D.new()
		joint1.node_a = get_path()
		joint1.node_b = other_part.get_path()
		joint1.position = offset
		joint1.softness = 0.0
		add_child(joint1)
		joints.append(joint1)
		
		# Second joint at a different position to lock rotation
		var joint2 = PinJoint2D.new()
		joint2.node_a = get_path()
		joint2.node_b = other_part.get_path()
		joint2.position = -offset
		joint2.softness = 0.0
		add_child(joint2)
		joints.append(joint2)
		
		# Create visual Bolt/Joint on SELF (Owner)
		add_visual_joint(other_part, to_local((global_position + other_part.global_position) / 2.0))
	
	connected_parts.append(other_part)
	other_part.connected_parts.append(self)

func add_visual_joint(neighbor: PartBase, local_pos: Vector2) -> void:
	# Create a bolt/connector visual
	var bolt = Node2D.new()
	bolt.position = local_pos
	bolt.name = "VisualJoint"
	bolt.z_index = 20 # High Z-index to ensure visibility over wheels
	
	# Metal plate
	var plate = Polygon2D.new()
	plate.color = Color(0.6, 0.6, 0.65, 1.0) # Light steel
	plate.polygon = PackedVector2Array([
		Vector2(-6, -12), Vector2(6, -12), 
		Vector2(6, 12), Vector2(-6, 12)
	])
	
	# Rotate plate if connection is horizontal vs vertical
	# Since local_pos is relative to the part center (0,0):
	# Vertical connection (Top/Bottom): x is small, y is large (~32).
	# Horizontal connection (Left/Right): x is large (~32), y is small.
	if abs(local_pos.x) > abs(local_pos.y):
		plate.rotation_degrees = 90
		
	bolt.add_child(plate)
	
	# Bolt head (Hexagon)
	var head = Polygon2D.new()
	head.color = Color(0.8, 0.8, 0.85, 1.0) # Shiny bolt
	# Hexagon points approx
	head.polygon = PackedVector2Array([
		Vector2(-3, -5), Vector2(3, -5), Vector2(6, 0), 
		Vector2(3, 5), Vector2(-3, 5), Vector2(-6, 0)
	])
	bolt.add_child(head)
	
	add_child(bolt)
	
	# Track it for cleanup
	visual_joints_map[neighbor] = bolt

func add_wheel_strut(neighbor: PartBase, target_pos: Vector2) -> void:
	# Create a strut/suspension arm for wheels
	var strut = Node2D.new()
	strut.position = Vector2.ZERO # We draw from 0 (chassis) to target
	strut.name = "VisualStrut"
	strut.z_index = 15 # Below visual bolt (20) but above parts
	
	# Calculate arm geometry
	# Start point is roughly the edge of the chassis (halfway to wheel center)
	var start_pos = target_pos * 0.5
	var end_pos = target_pos
	var dir = (end_pos - start_pos).normalized()
	var perp = Vector2(-dir.y, dir.x)
	
	# Draw Arm (Trapezoid from chassis edge to wheel center)
	var arm = Polygon2D.new()
	arm.color = Color(0.5, 0.55, 0.6, 1.0) # Steel arm
	arm.polygon = PackedVector2Array([
		start_pos + perp * 6,
		start_pos - perp * 6,
		end_pos - perp * 4,
		end_pos + perp * 4
	])
	strut.add_child(arm)
	
	# Axle mount (at wheel center)
	var mount = Polygon2D.new()
	mount.color = Color(0.4, 0.45, 0.5, 1.0) # Darker mount
	mount.polygon = PackedVector2Array([
		end_pos + Vector2(-8, -8),
		end_pos + Vector2(8, -8),
		end_pos + Vector2(8, 8),
		end_pos + Vector2(-8, 8)
	])
	strut.add_child(mount)
	
	# Add Bolt on top (High Z)
	var bolt = Node2D.new()
	bolt.position = end_pos
	bolt.z_index = 21 # Above everything
	var head = Polygon2D.new()
	head.color = Color(0.9, 0.9, 0.95, 1.0) # Bright capped nut
	head.polygon = PackedVector2Array([
		Vector2(-4, -4), Vector2(4, -4), Vector2(4, 4), Vector2(-4, 4)
	])
	bolt.add_child(head)
	strut.add_child(bolt)
	
	add_child(strut)
	visual_joints_map[neighbor] = strut

func _setup_goal_detection() -> void:
	# Create an Area2D to detect the goal
	# We duplicate the existing collision shape(s) for this area
	var area = Area2D.new()
	area.name = "GoalDetector"
	# We want this area to detect the 'goal' group
	area.monitorable = false
	area.monitoring = true
	
	# Find our collision shapes
	for child in get_children():
		if child is CollisionShape2D or child is CollisionPolygon2D:
			var new_collision = child.duplicate()
			area.add_child(new_collision)
	
	add_child(area)
	area.area_entered.connect(_on_goal_entered)

func _on_goal_entered(area: Area2D) -> void:
	if area.is_in_group("goal"):
		print(part_name, " reached the goal!")
		if GameManager:
			GameManager.complete_level()

