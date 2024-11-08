extends Camera2D

@export var target_path: NodePath
@export var smooth_speed: float = 0.15
@export var zoom_speed: float = 0.1
@export var min_zoom: float = 0.5
@export var max_zoom: float = 2.0
@export var deadzone_radius: float = 100.0
@export var base_resolution := Vector2(320, 180)  # Your game's base resolution

var target: Node2D
var target_position := Vector2.ZERO
var camera_center := Vector2.ZERO

func _ready() -> void:
	target = get_node(target_path)
	position = target.position if target else Vector2.ZERO
	camera_center = position
	
	# Pixel perfect settings
	position_smoothing_enabled = false  # We'll handle smoothing ourselves
	drag_horizontal_enabled = false
	drag_vertical_enabled = false
	
	# Critical for pixel perfectness
	set_process_mode(Node.PROCESS_MODE_ALWAYS)
	
	# Make sure the viewport is correctly configured
	get_tree().root.scaling_3d_scale = 1
	get_tree().root.content_scale_mode = Window.CONTENT_SCALE_MODE_VIEWPORT
	
	# Set the viewport's canvas items to nearest neighbor filtering
	RenderingServer.viewport_set_default_canvas_item_texture_filter(
		get_viewport().get_viewport_rid(),
		RenderingServer.CANVAS_ITEM_TEXTURE_FILTER_NEAREST
	)

# Round a vector to the nearest pixel
func snap_to_pixel(pos: Vector2) -> Vector2:
	var zoom_factor := zoom.x  # Assuming uniform zoom
	return (pos * zoom_factor).round() / zoom_factor

func is_outside_deadzone(target_pos: Vector2, center: Vector2) -> bool:
	return target_pos.distance_to(center) > deadzone_radius

func calculate_camera_position(current_center: Vector2, target_pos: Vector2) -> Vector2:
	if not is_outside_deadzone(target_pos, current_center):
		return current_center
		
	var direction := (target_pos - current_center).normalized()
	var deadzone_point := current_center + direction * deadzone_radius
	return current_center + (target_pos - deadzone_point)

func calculate_smooth_position(current: Vector2, target: Vector2, speed: float) -> Vector2:
	return current.lerp(target, speed)

func _physics_process(delta: float) -> void:
	if not target:
		return
		
	# Update target position
	target_position = target.position
	
	# Calculate new camera position considering deadzone
	var new_position := calculate_camera_position(camera_center, target_position)
	
	# Only update if we need to move
	if new_position != camera_center:
		# Apply smooth movement
		camera_center = calculate_smooth_position(
			camera_center,
			new_position,
			smooth_speed
		)
		# Snap the final position to pixel grid
		position = snap_to_pixel(camera_center)
	
	# Handle zoom input with pixel-perfect snapping
	var zoom_input := Input.get_axis("zoom_out", "zoom_in")
	if zoom_input != 0:
		var new_zoom_value := clampf(
			zoom.x + zoom_input * zoom_speed,
			min_zoom,
			max_zoom
		)
		# Round zoom to maintain pixel perfect scaling
		new_zoom_value = round(new_zoom_value * base_resolution.y) / base_resolution.y
		zoom = Vector2.ONE * new_zoom_value

func _draw() -> void:
	if Engine.is_editor_hint() or OS.is_debug_build():
		draw_circle(Vector2.ZERO, deadzone_radius, Color(1, 0, 0, 0.2))
