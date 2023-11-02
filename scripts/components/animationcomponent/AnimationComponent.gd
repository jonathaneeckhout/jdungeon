extends Node

class_name AnimationComponent

@export var animation_player: AnimationPlayer
@export var stats: StatsSynchronizerComponent
@export var action_synchronizer: ActionSynchronizerComponent

@export var idle_animation: String = "Idle"
@export var move_animation: String = "Move"
@export var attack_animation: String = "Attack"
@export var hurt_animation: String = "Hurt"
@export var die_animation: String = "Die"

var target_node: Node

var loop_animation: String = idle_animation
var wait_to_finish = false
var dead = false


func _ready():
	target_node = get_parent()

	if J.is_server():
		return

	if target_node.get("velocity") == null:
		J.logger.error("target_node does not have the position variable")
		return

	stats.got_hurt.connect(_on_got_hurt)
	stats.died.connect(_on_died)
	stats.respawned.connect(_on_respawned)

	if action_synchronizer:
		action_synchronizer.attacked.connect(_on_attacked)

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
	if animation_player.has_animation(hurt_animation):
		animation_player.stop()
		animation_player.play(hurt_animation)
		wait_to_finish = true


func _on_died():
	dead = true

	if animation_player.has_animation(die_animation):
		animation_player.stop()
		animation_player.play(die_animation)


func _on_respawned():
	dead = false


func _on_attacked(_target: String, _damage: int):
	if animation_player.has_animation(attack_animation):
		animation_player.stop()
		animation_player.play(attack_animation)
		wait_to_finish = true


func _on_animation_finished(_anim_name: String):
	wait_to_finish = false
