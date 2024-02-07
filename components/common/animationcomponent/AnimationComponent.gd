extends Node

class_name AnimationComponent

@export var animation_player: AnimationPlayer
@export var stats: StatsSynchronizerComponent
@export var action_synchronizer: ActionSynchronizerComponent
@export var update_face: UpdateFaceComponent

@export var idle_animation: String = "Idle"
@export var move_animation: String = "Move"
@export var attack_animation: String = "Attack"

@export var attack_right_hand_animation: String = "Attack_Right_Hand"
@export var attack_left_hand_animation: String = "Attack_Left_Hand"

@export var hurt_animation: String = "Hurt"
@export var die_animation: String = "Die"

var target_node: Node

var loop_animation: String = idle_animation
var wait_to_finish: bool = false
var dead: bool = false

var dual_direction_attack: bool = false
var original_direction: bool = true


func _ready():
	target_node = get_parent()

	assert(target_node.multiplayer_connection != null, "Target's multiplayer connection is null")

	if target_node.multiplayer_connection.is_server():
		queue_free()
		return

	# This component only handles other players
	if (
		target_node.get("peer_id") != null
		and target_node.multiplayer_connection.is_own_player(target_node)
	):
		queue_free()
		return

	if target_node.get("velocity") == null:
		GodotLogger.error("target_node does not have the position variable")
		return

	stats.got_hurt.connect(_on_got_hurt)
	stats.died.connect(_on_died)
	stats.respawned.connect(_on_respawned)

	if (
		animation_player.has_animation(attack_right_hand_animation)
		and animation_player.has_animation(attack_left_hand_animation)
	):
		dual_direction_attack = true

	if action_synchronizer:
		action_synchronizer.attacked.connect(_on_attacked)

	if update_face:
		update_face.direction_changed.connect(_on_direction_changed)

	animation_player.animation_finished.connect(_on_animation_finished)


func _physics_process(_delta):
	if wait_to_finish or dead:
		return

	if target_node.velocity.is_zero_approx():
		if (
			animation_player.current_animation != idle_animation
			and animation_player.has_animation(idle_animation)
		):
			loop_animation = idle_animation
			animation_player.play(idle_animation)
	else:
		if (
			animation_player.current_animation != move_animation
			and animation_player.has_animation(move_animation)
		):
			loop_animation = move_animation
			animation_player.play(move_animation)


func _on_got_hurt(_from: String, _damage: int):
	if dead:
		return

	if animation_player.has_animation(hurt_animation):
		animation_player.stop()
		animation_player.play(hurt_animation)
		wait_to_finish = true


func _on_died():
	dead = true

	if animation_player.has_animation(die_animation):
		animation_player.stop()
		animation_player.play(die_animation)

	if target_node is CollisionObject2D:
		target_node.collision_layer = J.PHYSICS_LAYER_PASSABLE_ENTITIES
		target_node.collision_mask = 0


func _on_respawned():
	dead = false


func _on_attacked(_direction: Vector2):
	if dead:
		return

	if animation_player.is_playing():
		animation_player.stop()

	if dual_direction_attack:
		if original_direction:
			animation_player.play(attack_right_hand_animation)
		else:
			animation_player.play(attack_left_hand_animation)
	else:
		if animation_player.has_animation(attack_animation):
			animation_player.play(attack_animation)

	wait_to_finish = true


func _on_animation_finished(_anim_name: String):
	wait_to_finish = false


func _on_direction_changed(original: bool):
	original_direction = original
	if (
		dual_direction_attack
		and animation_player.is_playing()
		and (
			animation_player.current_animation == attack_right_hand_animation
			or animation_player.current_animation == attack_left_hand_animation
		)
	):
		var current_animation_position: float = animation_player.current_animation_position
		animation_player.stop()
		if original:
			animation_player.play(attack_right_hand_animation)
		else:
			animation_player.play(attack_left_hand_animation)
		animation_player.seek(current_animation_position)
