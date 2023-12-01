extends Node2D

class_name PlayerSynchronizer

signal interacted(target: Node2D)
signal attacked(direction: Vector2)
signal skill_used(where: Vector2, skill_class: String)

const ATTACK_RIGHT_HAND_ANIMATION: String = "Attack_Right_Hand"
const ATTACK_LEFT_HAND_ANIMATION: String = "Attack_Left_Hand"

@export var stats_component: StatsSynchronizerComponent
@export var interaction_component: PlayerInteractionComponent
@export var action_synchronizer: ActionSynchronizerComponent
@export var animation_player: AnimationPlayer
@export var skill_component: SkillComponent
@export var update_face: UpdateFaceComponent

var target_node: Node

var is_local: bool = false
var current_frame: int = 0
var input_buffer: Array[Dictionary] = []
var last_sync_frame: int = 0
var last_sync_position: Vector2 = Vector2.ZERO
var last_sync_velocity: Vector2 = Vector2.ZERO

var point_params := PhysicsPointQueryParameters2D.new()

var mouse_global_pos: Vector2 = Vector2.ZERO
var current_target: Node2D

var attack_timer: Timer
var original_direction: bool = true


func _ready():
	target_node = get_parent()

	if target_node.get("component_list") != null:
		target_node.component_list["player_synchronizer"] = self

	if target_node.get("peer_id") == null:
		GodotLogger.error("target_node does not have the peer_id variable")
		return

	if target_node.get("position") == null:
		GodotLogger.error("target_node does not have the position variable")
		return

	if target_node.get("velocity") == null:
		GodotLogger.error("target_node does not have the velocity variable")
		return

	is_local = target_node.peer_id == multiplayer.get_unique_id()

	if G.is_server():
		set_process_input(false)
	else:
		if not is_local:
			set_physics_process(false)
			queue_free()
			return
		else:
			#Set parameters for point-casting (can use ShapeParameters instead if necessary)
			point_params.collide_with_areas = false
			point_params.collide_with_bodies = true
			point_params.collision_mask = (
				J.PHYSICS_LAYER_PLAYERS
				+ J.PHYSICS_LAYER_ENEMIES
				+ J.PHYSICS_LAYER_NPCS
				+ J.PHYSICS_LAYER_ITEMS
			)
			update_face.direction_changed.connect(_on_direction_changed)

		stats_component.died.connect(_on_died)

	interacted.connect(_on_interacted)
	skill_used.connect(_on_skill_used)

	#When an instant cast ability is selected, it emulates using it at the player's position
	skill_component.skill_cast_on_select_selected.connect(_on_skill_instant_used)

	attack_timer = Timer.new()
	attack_timer.name = "AttackTimer"
	attack_timer.one_shot = true
	add_child(attack_timer)


func _input(event: InputEvent):
	# Don't do anything when above ui
	if JUI.above_ui:
		return

	if event.is_action_pressed("j_right_click"):
		_handle_right_click(target_node.get_global_mouse_position())


func _physics_process(delta):
	if stats_component.is_dead:
		return

	if G.is_server():
		for input in input_buffer:
			# The server runs on a slower tick rate than the client thus the speed needs to be lower to match the client's speed
			step_physics(input["dir"], input["dt"] / delta)

		input_buffer = []
		G.sync_rpc.playersynchronizer_sync_pos.rpc_id(
			target_node.peer_id, current_frame, target_node.position, target_node.velocity
		)
	elif is_local:
		current_frame += 1

		var direction: Vector2 = Input.get_vector(
			"j_move_left", "j_move_right", "j_move_up", "j_move_down"
		)
		input_buffer.append({"cf": current_frame, "dir": direction})

		mouse_global_pos = target_node.get_global_mouse_position()

		G.sync_rpc.playersynchronizer_sync_input.rpc_id(
			1, current_frame, direction, delta, mouse_global_pos
		)

		while input_buffer.size() > 0 and input_buffer[0]["cf"] <= last_sync_frame:
			input_buffer.remove_at(0)

		target_node.position = last_sync_position
		target_node.velocity = last_sync_velocity

		for input in input_buffer:
			step_physics(input["dir"], 1.0)

		#This update is frame based as to update the cursor visually on the client
		update_target(target_node.get_global_mouse_position())

		update_animation()


func step_physics(direction: Vector2, fraction: float):
	target_node.velocity = direction * stats_component.movement_speed * fraction

	target_node.move_and_slide()


func _handle_right_click(click_global_pos: Vector2):
	if stats_component.is_dead:
		return

	#Fetch targets under the cursor
	update_target(click_global_pos)

	#Attempt to use a skill
	if skill_component.get_skill_current_class() != "":
		G.sync_rpc.playersynchronizer_sync_skill_use.rpc_id(
			1, click_global_pos, skill_component.get_skill_current_class()
		)
		skill_used.emit(click_global_pos, skill_component.get_skill_current_class())

	#Else, attempt to act on the target
	elif current_target != null:
		G.sync_rpc.playersynchronizer_sync_interact.rpc_id(1, current_target.get_name())
		interacted.emit(current_target)
	#An interaction was attempted, but there was no target
	else:
		G.sync_rpc.playersynchronizer_sync_interact.rpc_id(1, "")
		interacted.emit(null)


func update_target(at_global_point: Vector2):
	#Do not proceed if outside the tree
	if not is_inside_tree():
		return

	if JUI.above_ui:
		current_target = null
		return

	#Get the world's space
	var direct_space: PhysicsDirectSpaceState2D = get_world_2d().direct_space_state

	#Set the target position
	point_params.position = at_global_point

	#Update collisions from point
	var collisions: Array[Dictionary] = direct_space.intersect_point(point_params)

	if collisions.is_empty():
		current_target = null
	else:
		var target: Node2D = collisions.front().get("collider")
		if target != target_node:
			current_target = target


func update_animation():
	if attack_timer.is_stopped():
		if target_node.velocity.is_zero_approx():
			animation_player.play("Idle")
		else:
			animation_player.play("Move")


func _on_interacted(target: Node2D):
	if target == null or target.entity_type == J.ENTITY_TYPE.ENEMY:
		if attack_timer.is_stopped():
			if G.is_server():
				for enemy in interaction_component.enemies_in_attack_range:
					if enemy.stats.is_dead:
						continue

					var damage = randi_range(
						stats_component.attack_power_min, stats_component.attack_power_max
					)

					enemy.stats.hurt(target_node, damage)

				action_synchronizer.attack(target_node.position.direction_to(mouse_global_pos))
			else:
				if original_direction:
					animation_player.play(ATTACK_RIGHT_HAND_ANIMATION)
				else:
					animation_player.play(ATTACK_LEFT_HAND_ANIMATION)

			attacked.emit(target_node.position.direction_to(mouse_global_pos))

			attack_timer.start(stats_component.attack_speed)


func _on_skill_used(where: Vector2, skillClass: String):
	skill_component.skill_use_at(where, skillClass)


#Intermediary
func _on_skill_instant_used(_skill: SkillComponentResource):
	_handle_right_click(target_node.global_position)


func _on_died():
	animation_player.play("Die")


func sync_pos(c: int, p: Vector2, v: Vector2):
	if not is_local:
		return

	if c < last_sync_frame:
		return

	last_sync_frame = c
	last_sync_position = p
	last_sync_velocity = v


func sync_input(c: int, d: Vector2, t: float, m: Vector2):
	if c < current_frame:
		return

	current_frame = c
	mouse_global_pos = m
	input_buffer.append({"dir": d, "dt": t})


func sync_skill_use(target_location: Vector2, skill_class: String):
	if not G.is_server():
		return

	var id = multiplayer.get_remote_sender_id()

	# Only allow logged in players
	if not G.is_user_logged_in(id):
		return

	if id == target_node.peer_id:
		if skill_component.is_skill_present(skill_class):
			skill_used.emit(target_location, skill_class)
		else:
			GodotLogger.warn(
				'This skill_component does not own a skill of class "{0)"'.format([skill_class])
			)


func sync_interact(target_name: String):
	if not G.is_server():
		return

	var id = multiplayer.get_remote_sender_id()

	# Only allow logged in players
	if not G.is_user_logged_in(id):
		return

	if id == target_node.peer_id:
		if target_name == "":
			interacted.emit(null)

		var target: Node2D = null

		target = G.world.enemies.get_node_or_null(target_name)
		if target == null:
			target = G.world.npcs.get_node_or_null(target_name)
			if target == null:
				target = G.world.items.get_node_or_null(target_name)
				if target != null and interaction_component.items_in_loot_range.has(target):
					target.loot(target_node)
			else:
				if interaction_component.npcs_in_interact_range.has(target):
					target.interact(target_node)

		interacted.emit(target)


func _on_direction_changed(original: bool):
	original_direction = original

	# This piece of code makes sure that the attack animation stays in sync with the face direction
	if (
		animation_player.is_playing()
		and (
			animation_player.current_animation == ATTACK_RIGHT_HAND_ANIMATION
			or animation_player.current_animation == ATTACK_LEFT_HAND_ANIMATION
		)
	):
		var current_animation_position: float = animation_player.current_animation_position
		animation_player.stop()
		if original:
			animation_player.play(ATTACK_RIGHT_HAND_ANIMATION)
		else:
			animation_player.play(ATTACK_LEFT_HAND_ANIMATION)
		animation_player.seek(current_animation_position)
