extends Node2D

class_name PlayerSynchronizer

## Signal emitted when a player interacts with a target.
## This signal is being sent on the client and server sides.
signal interacted(target: Node2D)

## Signal emitted when a player attacks in a certain direction.
## This signal is being sent on the client and server sides.
signal attacked(direction: Vector2)

## Signal emitted when a player uses a skill.
## This signal is being sent on the client and server sides.
signal skill_used(where: Vector2, skill_class: String)

## Name of the animation of when the player has the weapon in his/her right hand
const ATTACK_RIGHT_HAND_ANIMATION: String = "Attack_Right_Hand"
## Name of the animation of when the player has the weapon in his/her left hand
const ATTACK_LEFT_HAND_ANIMATIONS: Array[String] = [
	"Attack_Left_Hand", "Attack_Left_Hand_1", "Attack_Left_Hand_2"
]

@export var stats_component: StatsSynchronizerComponent
@export var interaction_component: PlayerInteractionComponent
@export var action_synchronizer: ActionSynchronizerComponent
@export var animation_player: AnimationPlayer
@export var skill_component: SkillComponent
@export var update_face: UpdateFaceComponent

## This variable stores the postion of the player's mouse. It is updated on client and server side.
var mouse_global_pos: Vector2 = Vector2.ZERO
## This is the current target which is under the cursor of the player
var current_target: Node2D

# This serves as the parent node on which the component will take effect.
var _target_node: Node
# This variable keeps track of which frame is currently handled
var _current_frame: int = 0
# Buffer to store all inputs received from the client
var _input_buffer: Array[Dictionary] = []
# This variable keeps track of the last frame received from the server
var _last_sync_frame: int = 0
# This variable keeps track of the last position received from the server
var _last_sync_position: Vector2 = Vector2.ZERO
# This variable keeps track of the last velocity received from the server
var _last_sync_velocity: Vector2 = Vector2.ZERO
# Query parameters used to query which target is under the mouse
var _point_params: PhysicsPointQueryParameters2D = null
# Timer to keep track of the timeout between two attacks
var _attack_timer: Timer
# Variable to keep track to which side the player was facing
var _original_direction: bool = true


func _ready():
	# Common-side logic

	# set the _target_node
	if not _init_target_node():
		GodotLogger.error("Failed to initialize _target_node")
		return

	# Create a new timer to keep track of the time between attacks
	_attack_timer = Timer.new()
	_attack_timer.name = "AttackTimer"
	_attack_timer.one_shot = true
	add_child(_attack_timer)

	# Server-side logic
	if G.is_server():
		set_process_input(false)

		# Connect to the interacted signal to handle interactions
		interacted.connect(_on_server_interacted)

	# Client-side logic
	else:
		# This component is only needed for your own player on the client-side, thus it can be deleted for the other players
		if not G.is_own_player(_target_node):
			set_physics_process(false)
			queue_free()
			return

		# Init the point params needed to query which entity is under the mouse when clicked
		_init_point_params()

		# Connect to the direction changes component to handle the correct weapon swapping to match the horizontal flip
		update_face.direction_changed.connect(_on_direction_changed)

		# Connect to the died signal to animate the died animation
		stats_component.died.connect(_on_died)

		# Connect to the interacted signal to handle interactions
		interacted.connect(_on_client_interacted)

		#When an instant cast ability is selected, it emulates using it at the player's position
		skill_component.skill_cast_on_select_selected.connect(_on_client_skill_instant_used)


func _init_target_node() -> bool:
	# Get the parent node
	_target_node = get_parent()

	if _target_node.get("peer_id") == null:
		GodotLogger.error("_target_node does not have the peer_id variable")
		return false

	if _target_node.get("position") == null:
		GodotLogger.error("_target_node does not have the position variable")
		return false

	if _target_node.get("velocity") == null:
		GodotLogger.error("_target_node does not have the velocity variable")
		return false

	# Register the component in the parent's component_list
	if _target_node.get("component_list") != null:
		_target_node.component_list["player_synchronizer"] = self

	return true


func _init_point_params():
	# Create a new point query paremeters2D object used for the physics query to check which entities are under the mouse
	_point_params = PhysicsPointQueryParameters2D.new()
	# Set parameters for point-casting (can use ShapeParameters instead if necessary)
	_point_params.collide_with_areas = true
	_point_params.collide_with_bodies = false
	# Currently the mouse click should interact with players, enemies, npcs and items
	_point_params.collision_mask = (
		J.PHYSICS_LAYER_PLAYERS
		+ J.PHYSICS_LAYER_ENEMIES
		+ J.PHYSICS_LAYER_NPCS
		+ J.PHYSICS_LAYER_ITEMS
	)


# Remember inputs are only handled on client-side
func _input(event: InputEvent):
	# Don't do anything when above ui
	if JUI.above_ui:
		return

	# Handle right mouse clicks
	if event.is_action_pressed("j_right_click"):
		_client_handle_right_click(_target_node.get_global_mouse_position())


func _physics_process(delta):
	# Common-side logic

	# Don't do anything when the player is dead
	if stats_component.is_dead:
		return

	# Server-side logic
	if G.is_server():
		# Handle the player's inputs
		_server_handle_inputs(delta)

		# Sync the position and velocity back to the player
		G.sync_rpc.playersynchronizer_sync_pos.rpc_id(
			_target_node.peer_id, _current_frame, _target_node.position, _target_node.velocity
		)
	# Client-side logic
	else:
		# Bump the current handled frame
		_current_frame += 1

		# Get the WSAD movement vector from the player
		var direction: Vector2 = Input.get_vector(
			"j_move_left", "j_move_right", "j_move_up", "j_move_down"
		)

		# Append this movement vector to the input buffer
		_input_buffer.append({"cf": _current_frame, "dir": direction})

		# Fetch the player's mouse position
		mouse_global_pos = _target_node.get_global_mouse_position()

		# Sync this input back to the server
		G.sync_rpc.playersynchronizer_sync_input.rpc_id(
			1, _current_frame, direction, delta, mouse_global_pos
		)

		# Remove any input that is older than the timestamp of the last synced frame
		while _input_buffer.size() > 0 and _input_buffer[0]["cf"] <= _last_sync_frame:
			_input_buffer.remove_at(0)

		# Set the current position and velocity the last synced values received from the server. These will be used for further client-side predictions
		_target_node.position = _last_sync_position
		_target_node.velocity = _last_sync_velocity

		# Perform you inputs on the last benchmark values to predict the player's position
		for input in _input_buffer:
			_perform_physics_step(input["dir"], 1.0)

		# Query which target is under the mouse, this is mainly used to update the cursor accordingly
		# Example: when hovering over an NPC the mouse will change to green with the text "hi"
		_client_query_targets_under_mouse(mouse_global_pos)

		# Update the player's animation accordingly to the new velocity
		_client_update_animation()


# This function handles the input received from the client
func _server_handle_inputs(delta: float):
	# Loop over all buffered inputs
	for input in _input_buffer:
		# The server runs on a slower tick rate than the client thus the speed needs to be lower to match the client's speed
		_perform_physics_step(input["dir"], input["dt"] / delta)

	# Empty the buffer
	_input_buffer.clear()


# This function allows to perform multple move_and_slide's in the same physics tick by fractioning the speed
# This is needed because the client sends inputs at a higher rate than the server physics server frame rate
func _perform_physics_step(direction: Vector2, fraction: float):
	# Calculate the fractioned velocity
	_target_node.velocity = direction * stats_component.movement_speed * fraction

	# Perform the actual move and collision checking
	_target_node.move_and_slide()


func _client_handle_right_click(click_global_pos: Vector2):
	# Don't handle inputs when dead
	if stats_component.is_dead:
		return

	# Fetch targets under the cursor
	_client_query_targets_under_mouse(click_global_pos)

	# Attempt to use a skill
	if skill_component.get_skill_current_class() != "":
		# Sync the skill usage to the server
		G.sync_rpc.playersynchronizer_sync_skill_use.rpc_id(
			1, click_global_pos, skill_component.get_skill_current_class()
		)

		skill_used.emit(click_global_pos, skill_component.get_skill_current_class())

	# Else, attempt to act on the target
	elif current_target != null:
		# Sync the interaction to the server
		G.sync_rpc.playersynchronizer_sync_interact.rpc_id(1, current_target.get_name())

		interacted.emit(current_target)
	# An interaction was attempted, but there was no target
	else:
		# Sync the interaction to the server
		G.sync_rpc.playersynchronizer_sync_interact.rpc_id(1, "")

		interacted.emit(null)


func _client_query_targets_under_mouse(at_global_point: Vector2):
	# Do not proceed if outside the tree
	if not is_inside_tree():
		return

	if JUI.above_ui:
		current_target = null
		return

	# Get the world's space
	var direct_space: PhysicsDirectSpaceState2D = get_world_2d().direct_space_state

	# Set the target position
	_point_params.position = at_global_point

	# Update collisions from point
	var collisions: Array[Dictionary] = direct_space.intersect_point(_point_params)

	if collisions.is_empty():
		current_target = null
	else:
		var target: Node2D = collisions.front().get("collider").get_parent()
		# Don't allow to target yourself
		if target != _target_node:
			current_target = target


# Handle the player's animation when moving or stopped
func _client_update_animation():
	# This line prevents the attack animation to be stopped by moving around
	if not _attack_timer.is_stopped():
		return

	# Player Idle when the player's movement is almost zero
	if _target_node.velocity.is_zero_approx():
		animation_player.play("Idle")
	else:
		animation_player.play("Move")


## Sync the position and velocity received from the server
func client_sync_pos(c: int, p: Vector2, v: Vector2):
	# Ignore older frames. This might happen due to the fact that network packets can be received in any order (udp)
	if c < _last_sync_frame:
		return

	# Buffer the values received in variables so they can be used in the next physics tick
	_last_sync_frame = c
	_last_sync_position = p
	_last_sync_velocity = v


## sync the player's inputs towards the server
func server_sync_input(frame: int, direction: Vector2, timestamp: float, mouse_pos: Vector2):
	# Ignore older frames
	if frame < _current_frame:
		return

	_current_frame = frame
	mouse_global_pos = mouse_pos

	# Store the inputs in a input buffer
	_input_buffer.append({"dir": direction, "dt": timestamp})


func server_sync_skill_use(target_location: Vector2, skill_class: String):
	if skill_component.is_skill_present(skill_class):
		skill_used.emit(target_location, skill_class)
	else:
		GodotLogger.warn(
			'This skill_component does not own a skill of class "{0)"'.format([skill_class])
		)


func server_sync_interact(target_name: String):
	# The player interacted with nothing
	if target_name == "":
		interacted.emit(null)
		return

	# Check if the target is a known enemy
	var target: Node2D = G.world.enemies.get_node_or_null(target_name)
	if target == null:
		# If not, check if the target is a known npcs
		target = G.world.npcs.get_node_or_null(target_name)
		if target == null:
			# If not, check if the target is a known item
			target = G.world.items.get_node_or_null(target_name)
			# Check if the player is in range to loot the item
			if target != null and interaction_component.items_in_loot_range.has(target):
				# Loot the item
				target.loot(_target_node)
		else:
			# Check if the player is in interaction range of the the npc
			if interaction_component.npcs_in_interact_range.has(target):
				# Interact with npc
				target.interact(_target_node)

	interacted.emit(target)


# Emulate a right click when a skill is instantly used when selected
func _on_client_skill_instant_used(_skill: SkillComponentResource):
	_client_handle_right_click(_target_node.global_position)


func _on_died():
	# When died, you play the die animation
	animation_player.play("Die")


func _on_direction_changed(original: bool):
	# update the previous with the current
	_original_direction = original

	# This piece of code makes sure that the attack animation stays in sync with the face direction
	if (
		animation_player.is_playing()
		and (
			animation_player.current_animation == ATTACK_RIGHT_HAND_ANIMATION
			or ATTACK_LEFT_HAND_ANIMATIONS.has(animation_player.current_animation)
		)
	):
		# Keep track of how far the current animation is playing
		var current_animation_position: float = animation_player.current_animation_position

		# Stop the current animation
		animation_player.stop()

		# Play the animation according to the direction the player is facing
		if original:
			animation_player.play(ATTACK_RIGHT_HAND_ANIMATION)
		else:
			var random_index = randi() % ATTACK_LEFT_HAND_ANIMATIONS.size()
			animation_player.play(ATTACK_LEFT_HAND_ANIMATIONS[random_index])

		# Set the animation back to the offset of where it was stopped
		animation_player.seek(current_animation_position)


func _on_server_interacted(target: Node2D):
	# Only handle the case of you hitting air (null) or the target is an enemy
	# The case to hit air allows you to miss hits or just perform swings around you
	if target != null and target.entity_type != J.ENTITY_TYPE.ENEMY:
		return

	# Don't do anything if the attack timer is running, this means your attack is still on timeout
	if !_attack_timer.is_stopped():
		return

	# Check which enemy the player managed to hit
	for enemy in interaction_component.enemies_in_attack_range:
		# The dead shall not be touched again
		if enemy.stats.is_dead:
			continue

		# Generate a random damage between the player's min and max attack power
		var damage: int = randi_range(
			stats_component.attack_power_min, stats_component.attack_power_max
		)

		# This is the call that actually hurts the enemy
		enemy.stats.hurt(_target_node, damage)

	# Synchronize to other players that the player attacked
	action_synchronizer.attack(_target_node.position.direction_to(mouse_global_pos))

	# Emit the signal that the player attacked
	attacked.emit(_target_node.position.direction_to(mouse_global_pos))

	# Start the timer so that the player needs to wait for this timer to stop before performing another attack
	_attack_timer.start(stats_component.attack_speed)


func _on_client_interacted(target: Node2D):
	# Only handle the case of you hitting air (null) or the target is an enemy
	# The case to hit air allows you to miss hits or just perform swings around you
	if target != null and target.entity_type != J.ENTITY_TYPE.ENEMY:
		return

	# Don't do anything if the attack timer is running, this means your attack is still on timeout
	if !_attack_timer.is_stopped():
		return

	# check which direction the player is facing and play the accordingly attack animation
	if _original_direction:
		animation_player.play(ATTACK_RIGHT_HAND_ANIMATION)
	else:
		var random_index = randi() % ATTACK_LEFT_HAND_ANIMATIONS.size()
		animation_player.play(ATTACK_LEFT_HAND_ANIMATIONS[random_index])

	# Emit the signal that the player attacked
	attacked.emit(_target_node.position.direction_to(mouse_global_pos))

	# Start the timer so that the player needs to wait for this timer to stop before performing another attack
	_attack_timer.start(stats_component.attack_speed)
