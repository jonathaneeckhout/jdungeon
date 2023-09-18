extends CharacterBody2D

class_name GMFPlayerBody2D

enum STATE { IDLE, MOVE, INTERACT, ATTACK, LOOT, NPC }
enum INTERACT_TYPE { ENEMY, NPC, ITEM }

const ARRIVAL_DISTANCE = 8
const SPEED = 300.0

signal state_changed(new_state: String)

@export var peer_id := 1:
	set(id):
		peer_id = id

var entity_type

var username: String = ""

var state: STATE = STATE.IDLE

var server_synchronizer: Node2D

var mouse_area: Area2D

var moving := false
var move_target := Vector2()

var interacting := false
var interact_target = ""
var interact_type = INTERACT_TYPE.ENEMY

var enemies_in_attack_range = []


func _input(event):
	if event.is_action_pressed("gmf_right_click"):
		# move(get_global_mouse_position())
		_handle_right_click()


func _ready():
	entity_type = Gmf.ENTITY_TYPE.PLAYER

	collision_layer = Gmf.PHYSICS_LAYER_WORLD + Gmf.PHYSICS_LAYER_PLAYERS

	if Gmf.is_server():
		collision_mask = Gmf.PHYSICS_LAYER_WORLD
	else:
		# Don't handle physics on client side
		collision_mask = 0

	server_synchronizer = load("res://gmf/common/scripts/serverSynchronizer.gd").new()
	server_synchronizer.name = "ServerSynchronizer"
	add_child(server_synchronizer)

	if Gmf.is_server():
		# Don't handle input on server side
		set_process_input(false)

		var attack_area = Area2D.new()
		attack_area.name = "AttackArea"
		attack_area.collision_layer = 0
		attack_area.collision_mask = Gmf.PHYSICS_LAYER_ENEMIES

		var cs_attack_area = CollisionShape2D.new()
		cs_attack_area.name = "AttackAreaCollisionShape2D"
		attack_area.add_child(cs_attack_area)

		var cs_attack_area_circle = CircleShape2D.new()

		cs_attack_area_circle.radius = 64.0
		cs_attack_area.shape = cs_attack_area_circle

		add_child(attack_area)

		attack_area.body_entered.connect(_on_attack_area_body_entered)
		attack_area.body_exited.connect(_on_attack_area_body_exited)

		Gmf.signals.server.player_moved.connect(_on_player_moved)
		Gmf.signals.server.player_interacted.connect(_on_player_interacted)
	else:
		mouse_area = Area2D.new()
		mouse_area.name = "MouseArea"
		mouse_area.collision_layer = 0
		mouse_area.collision_mask = (
			Gmf.PHYSICS_LAYER_PLAYERS
			+ Gmf.PHYSICS_LAYER_ENEMIES
			+ Gmf.PHYSICS_LAYER_NPCS
			+ Gmf.PHYSICS_LAYER_ITEMS
		)
		var cs_mouse_area = CollisionShape2D.new()
		cs_mouse_area.name = "MouseAreaCollisionShape2D"
		mouse_area.add_child(cs_mouse_area)

		var cs_mouse_area_circle = CircleShape2D.new()

		cs_mouse_area_circle.radius = 1.0
		cs_mouse_area.shape = cs_mouse_area_circle

		add_child(mouse_area)


func _physics_process(delta):
	if Gmf.is_server():
		fsm(delta)
		reset_inputs()

		move_and_slide()


func fsm(_delta):
	match state:
		STATE.IDLE:
			if moving:
				set_new_state(STATE.MOVE)
			elif interacting:
				set_new_state(STATE.INTERACT)
			else:
				velocity = Vector2.ZERO
		STATE.MOVE:
			_handle_move()
		STATE.INTERACT:
			_handle_interact()
		STATE.ATTACK:
			_handle_attack()
		STATE.NPC:
			_handle_npc()
		STATE.LOOT:
			_handle_loot()


func set_new_state(new_state: STATE):
	state = new_state
	server_synchronizer.send_new_state(state)


func reset_inputs():
	moving = false
	interacting = false


func move(pos: Vector2):
	server_synchronizer.move.rpc_id(1, pos)


func interact(target: String):
	print(target)
	server_synchronizer.interact.rpc_id(1, target)


func _handle_move():
	if position.distance_to(move_target) > ARRIVAL_DISTANCE:
		velocity = position.direction_to(move_target) * SPEED
	else:
		velocity = Vector2.ZERO
		set_new_state(STATE.IDLE)


func _handle_interact():
	match interact_type:
		INTERACT_TYPE.ENEMY:
			set_new_state(STATE.ATTACK)
		INTERACT_TYPE.NPC:
			set_new_state(STATE.NPC)
		INTERACT_TYPE.ITEM:
			set_new_state(STATE.LOOT)


func _handle_attack():
	if not is_instance_valid(interact_target):
		set_new_state(STATE.IDLE)
		return


func _handle_npc():
	pass


func _handle_loot():
	pass


func _handle_right_click():
	mouse_area.set_global_position(get_global_mouse_position())

	#The following awaits ensure that the collision cycle has occurred before calling
	#the get_overlapping_bodies function
	await get_tree().physics_frame
	await get_tree().physics_frame

	#Get the bodies under the mouse area
	var bodies = mouse_area.get_overlapping_bodies()

	#Move if nothing is under the mouse area
	if bodies.is_empty():
		move(get_global_mouse_position())
	else:
		#TODO: not sure if this needs to be improved, just take the first
		var target = bodies[0]
		if target != self:
			interact(target.name)


func _on_attack_area_body_entered(body):
	if not enemies_in_attack_range.has(body):
		enemies_in_attack_range.append(body)


func _on_attack_area_body_exited(body):
	if enemies_in_attack_range.has(body):
		enemies_in_attack_range.erase(body)


func _on_player_moved(id: int, pos: Vector2):
	if id != peer_id:
		return

	moving = true
	move_target = pos


func _on_player_interacted(id: int, target: String):
	if id != peer_id:
		return

	if Gmf.world.enemies.has_node(target):
		interacting = true
		interact_target = Gmf.world.enemies.get_node(target)
		interact_type = INTERACT_TYPE.ENEMY
		return

	if Gmf.world.npcs.has_node(target):
		interacting = true
		interact_target = Gmf.world.npcs.get_node(target)
		interact_type = INTERACT_TYPE.NPC
		return

	if Gmf.world.items.has_node(target):
		interacting = true
		interact_target = Gmf.world.items.get_node(target)
		interact_type = INTERACT_TYPE.ITEM
		return
