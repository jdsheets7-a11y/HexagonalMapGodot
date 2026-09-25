extends Camera3D

class_name CAMERA


@export_category("Movement")
@export var movespeed := 30.0
@export var zoomspeed := 3.0

@export_category("Camera")
@export var default_distance := 20.0
@export var default_pitch: float = -45

@export var default_position = Vector3(0, 0, 10)
@export var default_rotation: float = 0

@export var default_position2 = Vector3(0, 0, -10)
@export var default_rotation2: float = 180

@export var min_distance := 5.0
@export var max_distance := 40.0
@export var rotate_sensitivity := 0.004
@export var min_pitch := -80.0
@export var max_pitch := -10.0

var camera_parent: Node3D
var camera_pitch: Node3D

var rotating_camera := false

var pitch: float = deg_to_rad(default_pitch)
var camera_distance: float



func _ready() -> void:
	GameManager.camera = self
	camera_pitch = get_parent()
	camera_parent = camera_pitch.get_parent()
	set_default_camera()


func _process(delta: float) -> void:
	move_camera(delta)


func set_default_camera():
	if GameManager.local_team == Unit.TeamStatus.TEAM_1:
		move_camera_to(default_position, default_rotation, default_pitch, default_distance)
	else:
		move_camera_to(default_position2, default_rotation2, default_pitch, default_distance)


func move_camera_to(
	target_position: Vector3,
	target_rotation: float,
	target_pitch: float,
	target_distance: float,
	duration: float = 1.5
):
	var tween = create_tween()
	tween.set_parallel(true)
	
	# Position
	tween.tween_property(
		camera_parent,
		"position",
		target_position,
		duration
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	
	# Rotation
	var current_rotation = camera_parent.rotation.y
	var target_rotation_rad = deg_to_rad(target_rotation)
	target_rotation_rad = current_rotation + angle_difference(
		current_rotation,
		target_rotation_rad
	)
	tween.tween_property(
		camera_parent,
		"rotation:y",
		target_rotation_rad,
		duration
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	
	# Pitch
	tween.tween_property(
		camera_pitch,
		"rotation:x",
		deg_to_rad(target_pitch),
		duration
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	
	# Zoom
	tween.tween_property(
		self,
		"position:z",
		target_distance,
		duration
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	
	camera_distance = target_distance
	pitch = deg_to_rad(target_pitch)


func move_camera(delta: float) -> void:
	var move_vector := Vector3.ZERO
	if Input.is_action_pressed("MoveForward"):
		move_vector += -camera_parent.transform.basis.z
	if Input.is_action_pressed("MoveBackwards"):
		move_vector += camera_parent.transform.basis.z
	if Input.is_action_pressed("MoveLeft"):
		move_vector += -camera_parent.transform.basis.x
	if Input.is_action_pressed("MoveRight"):
		move_vector += camera_parent.transform.basis.x
	if Input.is_action_just_pressed("ResetCamera"):
		set_default_camera()
	if Input.is_action_just_pressed("SetCamera"):
		set_new_camera()
		
	if move_vector != Vector3.ZERO:
		move_vector.y = 0
		move_vector = move_vector.normalized()
		camera_parent.position += move_vector * movespeed * delta


func _input(event: InputEvent) -> void:
	# Right mouse button controls camera orbit
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_RIGHT:
			rotating_camera = event.pressed
		# Zoom
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			camera_distance -= zoomspeed
			camera_distance = clamp(
				camera_distance,
				min_distance,
				max_distance
			)
			update_camera_distance()
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			camera_distance += zoomspeed
			camera_distance = clamp(
				camera_distance,
				min_distance,
				max_distance
			)
			update_camera_distance()
	# Camera orbit
	if event is InputEventMouseMotion and rotating_camera:
		# Horizontal orbit
		camera_parent.rotate_y(-event.relative.x * rotate_sensitivity)
		# Vertical orbit
		pitch -= event.relative.y * rotate_sensitivity
		pitch = clamp(
			pitch,
			deg_to_rad(min_pitch),
			deg_to_rad(max_pitch)
		)
		camera_pitch.rotation.x = pitch


func update_camera_distance() -> void:
	position.z = camera_distance


func set_new_camera():
	default_distance = camera_distance
	default_pitch = rad_to_deg(camera_pitch.rotation.x)
	if GameManager.local_team == Unit.TeamStatus.TEAM_1:
		default_position = camera_parent.position
		default_rotation = rad_to_deg(camera_parent.rotation.y)
	else:
		default_position2 = camera_parent.position
		default_rotation2 = rad_to_deg(camera_parent.rotation.y)


func camera_to_unit(tile_spot):
	var x = tile_spot.x
	var y = tile_spot.y
	var z = tile_spot.z
	if GameManager.local_team == Unit.TeamStatus.TEAM_1:
		x += 0
		y += 0
		z += 10
		var pos = Vector3(x, y, z)
		move_camera_to(pos, 0, -45, 5)
	else:
		x += 0
		y += 0
		z += -10
		var pos = Vector3(x, y, z)
		move_camera_to(pos, 180, -45, 5)
