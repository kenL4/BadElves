extends PartBase
class_name Wheel

## Candy Cane Wheel - Motor-driven wheel

@export var motor_speed: float = 25.0 # Controllable speed
@export var motor_torque: float = 110000.0 # Extra torque for climbing

var motor_direction: float = 0.0
var snow_trail: CPUParticles2D = null

func _ready() -> void:
	super._ready()
	part_name = "Wheel"
	part_color = Color(1.0, 1.0, 1.0)
	mass = 1.0  # Heavier wheel keeps Center of Mass low
	angular_damp = 5.0 # Smoothens acceleration prevents instant flips
	physics_material_override = PhysicsMaterial.new()
	physics_material_override.friction = 50.0  # Keep the grip
	physics_material_override.bounce = 0.0
	
	contact_monitor = true
	max_contacts_reported = 1
	create_snow_trail()

func get_part_type() -> String:
	return "wheel"

func can_rotate_freely() -> bool:
	# Wheels should rotate freely around their axle
	return true

func should_connect_to(other_part: PartBase) -> bool:
	# Wheels can ONLY connect to Gift Boxes
	if other_part.get_part_type() != "gift_box":
		return false
		
	# Allow connection in ANY direction (Up, Down, Left, Right)
	# The base class handles distance checks
	return true

func _physics_process(_delta: float) -> void:
	if not GameManager:
		return
	
	if GameManager.current_state != GameManager.GameState.PLAY:
		return
	
	if freeze:
		return
	
	# Check for motor input
	motor_direction = 0.0
	if Input.is_action_pressed("move_right"):
		motor_direction = 1.0
	elif Input.is_action_pressed("move_left"):
		motor_direction = -1.0
	
	if motor_direction != 0.0:
		# Apply torque to spin the wheel
		apply_torque(motor_torque * motor_direction)
		
		# Limit max angular velocity
		if abs(angular_velocity) > motor_speed:
			angular_velocity = sign(angular_velocity) * motor_speed
	
	# Trail Logic
	if snow_trail:
		# Lock trail emitter to bottom of wheel in WORLD space (ignore wheel rotation)
		# Assuming gravity is down, contact point is roughly (0, 32) below center
		snow_trail.global_position = global_position + Vector2(0, 32)
		snow_trail.global_rotation = 0.0
		
		# Emit if spinning fast, touching ground, AND NOT in build zone (platform)
		var on_ground = get_contact_count() > 0
		var outside_platform = not GameManager.is_in_build_zone(global_position)
		
		if abs(angular_velocity) > 5.0 and on_ground and outside_platform:
			snow_trail.emitting = true
		else:
			snow_trail.emitting = false

func create_snow_trail() -> void:
	snow_trail = CPUParticles2D.new()
	snow_trail.amount = 40 # More particles
	snow_trail.lifetime = 0.6
	snow_trail.texture = null # Use default square
	snow_trail.local_coords = false # World space trails
	snow_trail.emission_shape = CPUParticles2D.EMISSION_SHAPE_POINT
	snow_trail.direction = Vector2(-1, -1) # Kicks back and up
	snow_trail.spread = 45.0
	snow_trail.gravity = Vector2(0, 700) # Heavy snow
	snow_trail.initial_velocity_min = 150.0 # Kick harder!
	snow_trail.initial_velocity_max = 300.0
	snow_trail.scale_amount_min = 5.0 # Bigger chunks
	snow_trail.scale_amount_max = 10.0
	snow_trail.color = Color(0.75, 0.85, 1.0, 0.9) # Visible blue-ish tint
	snow_trail.emitting = false
	add_child(snow_trail)
	# Position at bottom of wheel (approx radius 30-32)
	snow_trail.position = Vector2(0, 32)

func get_attachment_points() -> Array[Vector2]:
	# Wheel only attaches from above (center point for axle)
	return [Vector2(0, 0)]
