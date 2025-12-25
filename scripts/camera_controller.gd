extends Camera2D

# Camera settings
const SMOOTH_SPEED: float = 5.0
const ZOOM_SPEED: float = 5.0

var target_position: Vector2 = Vector2.ZERO
var target_zoom: Vector2 = Vector2(1, 1)

func _ready() -> void:
	# Enable smoothing if not already
	position_smoothing_enabled = true
	position_smoothing_speed = SMOOTH_SPEED
	
	# Set initial position based on build zone
	update_target()
	position = target_position

func _process(delta: float) -> void:
	update_target()
	
	# Smoothly move to target
	position = position.lerp(target_position, SMOOTH_SPEED * delta)
	zoom = zoom.lerp(target_zoom, ZOOM_SPEED * delta)

func update_target() -> void:
	if not GameManager:
		return
		
	if GameManager.current_state == GameManager.GameState.BUILD:
		# Special case for tutorial: keep camera fixed to avoid breaking UI highlights
		if LevelManager and LevelManager.current_level_id == "tutorial":
			target_position = Vector2(600, 300)
			target_zoom = Vector2(1, 1)
		else:
			# Center on build zone for other levels
			var zone_center = GameManager.build_zone_start + (GameManager.build_zone_size * GameManager.GRID_SIZE) / 2
			target_position = zone_center
			target_zoom = Vector2(1, 1)
		
	elif GameManager.current_state == GameManager.GameState.PLAY or GameManager.current_state == GameManager.GameState.COMPLETE:
		# Follow vehicle center
		if GameManager.placed_parts.size() > 0:
			var center = Vector2.ZERO
			var count = 0
			
			for part in GameManager.placed_parts:
				if is_instance_valid(part):
					center += part.global_position
					count += 1
			
			if count > 0:
				center /= count
				target_position = center
				# Optional: Slight zoom out during play?
				target_zoom = Vector2(1, 1)
		else:
			# Fallback if no parts valid
			target_position = GameManager.build_zone_start + (GameManager.build_zone_size * GameManager.GRID_SIZE) / 2
