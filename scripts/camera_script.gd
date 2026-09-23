extends Camera3D

@export_category("Movement")
@export var movespeed := 30.0
@export var zoomspeed := 3.0

@export_category("Camera")
@export var default_distance := 20.0
@export var min_distance := -10.0
@export var max_distance := 40.0
@export var rotate_sensitivity := 0.004
@export var min_pitch := -80.0
@export var max_pitch := -10.0

var camera_parent: Node3D
var camera_pitch: Node3D

var rotating_camera := false
var pitch := deg_to_rad(-45.0)
var camera_distance: float


func _ready() -> void:
	camera_pitch = get_parent()
	camera_parent = camera_pitch.get_parent()
	set_default_camera()


func _process(delta: float) -> void:
	move_camera(delta)

func set_default_camera():
	camera_distance = default_distance
	position = Vector3(0, 0, camera_distance)
	camera_pitch.rotation.x = pitch


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
