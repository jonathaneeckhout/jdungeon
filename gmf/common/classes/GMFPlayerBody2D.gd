extends CharacterBody2D

class_name GMFPlayerBody2D

const ARRIVAL_DISTANCE = 8
const SPEED = 300.0

signal state_changed(new_state: String)

@export var peer_id := 1:
	set(id):
		peer_id = id

var entity_type
var enable_input: bool = false

var username: String = ""

var state: String = "Idle"

var moving := false
var move_target := Vector2()

var server_synchronizer: Node2D


func _ready():
	entity_type = Gmf.ENTITY_TYPE.PLAYER
	set_process_input(enable_input)

	server_synchronizer = load("res://gmf/common/scripts/serverSynchronizer.gd").new()
	server_synchronizer.name = "ServerSynchronizer"
	add_child(server_synchronizer)

	if Gmf.is_server():
		Gmf.signals.server.player_moved.connect(_on_player_moved)


func _physics_process(delta):
	if Gmf.is_server():
		fsm(delta)
		reset_inputs()

		move_and_slide()


func fsm(_delta):
	match state:
		"Idle":
			if moving:
				set_new_state("Move")
			else:
				velocity = Vector2.ZERO
		"Move":
			_handle_move()


func set_new_state(new_state: String):
	state = new_state
	server_synchronizer.send_new_state(state)


func reset_inputs():
	moving = false


func move(pos: Vector2):
	server_synchronizer.move.rpc_id(1, pos)


func _handle_move():
	if position.distance_to(move_target) > ARRIVAL_DISTANCE:
		velocity = position.direction_to(move_target) * SPEED
	else:
		velocity = Vector2.ZERO
		set_new_state("Idle")


func _on_player_moved(id: int, pos: Vector2):
	if id != peer_id:
		return

	moving = true
	move_target = pos
