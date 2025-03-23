extends CharacterBody3D
@onready var head: Node3D = $Head
@onready var ray_cast_3d: RayCast3D = $Head/Camera3D/RayCast3D
@onready var prompt: Label = $Head/Camera3D/RayCast3D/Prompt

@export var mouse_sensitivity_h := 0.15
@export var mouse_sensitivity_v := 0.15
@export var max_interact_distance := 3.0

const SPEED = 5.0
const JUMP_VELOCITY = 4.5

var mouse_relative := Vector2()
var interacted_object = null

signal mouse_interact(mouse_relative: Vector2)

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		mouse_relative = event.relative
		
		if not interacted_object:
			rotation_degrees.y -= mouse_relative.x * mouse_sensitivity_h
			head.rotation_degrees.x -= mouse_relative.y * mouse_sensitivity_v
			head.rotation_degrees.x = clamp(head.rotation_degrees.x, -80, 90)
		
@warning_ignore("unused_parameter")
func _process(delta: float) -> void:
	if Input.is_action_just_pressed("quit"):
		get_tree().quit()
	
	if interacted_object:
		if Input.mouse_mode != Input.MOUSE_MODE_CONFINED:
			Input.mouse_mode = Input.MOUSE_MODE_CONFINED
	else:
		if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _physics_process(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Handle jump.
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)

	move_and_slide()


#-------------------------------------------------------------
	if ray_cast_3d.is_colliding():
		var collider = ray_cast_3d.get_collider()
		if collider.get("interactable"):
			if collider.has_method("get_prompt"):
				prompt.text = collider.get_prompt()
			if Input.is_action_pressed("LMB"):
				interacted_object = collider
				interacted_object.interact(true)
				prompt.text = interacted_object.get_prompt()
	else:
		if not interacted_object:
			prompt.text = ""
	
	if interacted_object:
		var player_position = global_transform.origin
		var object_position = interacted_object.global_transform.origin
		
		var distance_to_object = player_position.distance_to(object_position)
		if distance_to_object > max_interact_distance:
			interacted_object.interact(false)
			interacted_object = null
			return
		
		if Input.is_action_just_released("LMB"):
			interacted_object.interact(false)
			interacted_object = null
			return
		
		# according the position of player and object(door) to adjust the mouse motion input
		var object_forward = interacted_object.global_transform.basis.z.normalized()
		var object_right = interacted_object.global_transform.basis.x.normalized()
		var direction_to_object = (player_position - object_position).normalized()
		var dot_forward = floor(direction_to_object.dot(object_forward) * 10) / 10
		var dot_right = floor(direction_to_object.dot(object_right) * 10) / 10
		
		var mouse_FB_influence := 0.0
		var mouse_LR_influence := 0.0
		var interact_relative := Vector2.ZERO
		
		if abs(dot_forward) >= 0.9:
			mouse_FB_influence = -dot_forward
		elif abs(dot_right) >= 0.9:
			mouse_LR_influence = dot_right
		else:
			mouse_FB_influence = -dot_forward
			mouse_LR_influence = dot_right
		
		interact_relative = Vector2(mouse_relative.x * mouse_LR_influence, mouse_relative.y * mouse_FB_influence)
		mouse_interact.emit(interact_relative)
