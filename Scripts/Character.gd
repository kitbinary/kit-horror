extends CharacterBody3D

const CROUCHSPEED = 2.0
const SPEED = 5.0
const JUMP_VELOCITY = 4.5
@export var sensitivity = 2

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

var crouched : bool
var torch_on : bool

func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _physics_process(delta):
	# Add the gravity.
	if not is_on_floor():
		velocity.y -= gravity * delta

	# Handle Jump.
	if Input.is_action_just_pressed("move_jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	var speed = SPEED
	
	print(crouched)
	
	if Input.is_action_pressed("move_crouch"):
		speed = CROUCHSPEED
		if !crouched:
			$AnimationPlayer.play("crouch")
			crouched = true
	else:
		if crouched:
			var space_state = get_world_3d().direct_space_state
			var result = space_state.intersect_ray(PhysicsRayQueryParameters3D.create(position, position + Vector3(0,2,0), 1, [self.get_rid()]))
			if result.size() == 0:
				$AnimationPlayer.play_backwards("crouch")
				crouched = false
	
	if Input.is_action_just_pressed("player_torch"):
		if torch_on:
			$AnimationPlayer.play("torch")
		else:
			$AnimationPlayer.play_backwards("torch")
			
		torch_on = !torch_on
			
	if direction:
		velocity.x = direction.x * speed
		velocity.z = direction.z * speed
	else:
		velocity.x = move_toward(velocity.x, 0, speed)
		velocity.z = move_toward(velocity.z, 0, speed)

	move_and_slide()


func _input(event):
	if(event is InputEventMouseMotion):
		rotation.y -= event.relative.x / 1000 * sensitivity
		$Camera3D.rotation.x -= event.relative.y / 1000 * sensitivity
		rotation.x = clamp(rotation.x, PI/-2, PI/2)
		
		$Camera3D.rotation.x = clamp($Camera3D.rotation.x, -2, 2)
