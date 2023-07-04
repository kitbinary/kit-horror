extends CharacterBody3D

enum STATES {
	patrol,
	chasing,
	hunting,
	waiting
}

@export var waypoints : Array[Marker3D]
@export var speed_patrol = 2
@export var speed_chase = 3

@onready var timer : Timer = $PatrolTimer
@onready var nav_agent : NavigationAgent3D = $EnemyNavAgent

var player

var waypoint_index : int 
var current_state : STATES

var object_heard_far : bool
var object_heard_close : bool
var object_seen_far : bool
var object_seen_close : bool

func _ready():
	current_state = STATES.patrol
	player = get_tree().get_nodes_in_group("character")[0]
	nav_agent.set_target_position(waypoints[0].global_position)


func _process(delta):
	match current_state:
		STATES.patrol:
			# checks to see if the current nav is done and to wait
			if(nav_agent.is_navigation_finished()):
				current_state = STATES.waiting
				timer.start()
				return
			
			locate_point(delta, speed_patrol)
		
		STATES.chasing:
			if nav_agent.is_navigation_finished():
				timer.start()
				current_state = STATES.waiting
			nav_agent.set_target_position(player.global_position)
			
			locate_point(delta, speed_chase)
		
		STATES.hunting:
			if nav_agent.is_navigation_finished():
				timer.start()
				current_state = STATES.waiting
			
			locate_point(delta, speed_patrol)
		
		STATES.waiting:
			pass


func locate_point(delta, speed):
	# finds the next pos and moves toward it
	var target_pos = nav_agent.get_next_path_position()
	var nav_dir = global_position.direction_to(target_pos)
	face_dir(target_pos)
	velocity = nav_dir * speed
	move_and_slide()
	
	if object_heard_far:
		check_object()


func check_object():
	var space_state = get_world_3d().direct_space_state
	var result = space_state.intersect_ray(PhysicsRayQueryParameters3D.create($Face.global_position, 
		player.get_node("Camera3D").global_position, 1, [self.get_rid()]))
	if result.size() > 0:
		if (result["collider"].is_in_group("audible")) or (result["collider"].is_in_group("visible")):
			if object_heard_close:
				if !result["collider"].crouched:
					current_state = STATES.chasing
			
			if object_heard_far:
				if !result["collider"].crouched:
					current_state = STATES.hunting
					nav_agent.set_target_position(player.global_position)
			
			if object_seen_close:
				if !result["collider"].crouched:
					current_state = STATES.chasing
			
			if object_seen_far:
				if !result["collider"].crouched:
					current_state = STATES.hunting
					nav_agent.set_target_position(player.global_position)
				

func face_dir(dir : Vector3):
	look_at(Vector3(dir.x, global_position.y, dir.z),  Vector3.UP)
	

func _on_patrol_timer_timeout():
	# resets state then finds next waypoint to locate to
	current_state = STATES.patrol
	waypoint_index += 1
	if waypoint_index > (waypoints.size() - 1):
		waypoint_index = 0
	nav_agent.set_target_position(waypoints[waypoint_index].global_position)


func _on_hearing_far_body_entered(body):
	if body.is_in_group("audible"):
		object_heard_far = true
		print("Far noise heard")


func _on_hearing_far_body_exited(body):
	if body.is_in_group("audible"):
		object_heard_far = false
		print("Far noise no longer heard")


func _on_hearing_close_body_entered(body):
	if body.is_in_group("audible"):
		object_heard_close = true
		print("Close noise heard")


func _on_hearing_close_body_exited(body):
	if body.is_in_group("audible"):
		object_heard_close = false
		print("Close noise no longer heard")


func _on_sight_far_body_entered(body):
	if body.is_in_group("visible"):
		object_seen_far = true
		print("Far object seen")


func _on_sight_far_body_exited(body):
	if body.is_in_group("visible"):
		object_seen_far = false
		print("Far object no longer seen")


func _on_sight_close_body_entered(body):
	if body.is_in_group("visible"):
		object_seen_close = true
		print("Close object seen")


func _on_sight_close_body_exited(body):
	if body.is_in_group("visible"):
		object_seen_close = false
		print("Close object no longer seen")
