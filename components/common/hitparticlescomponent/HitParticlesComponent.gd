extends Node2D

## This component will emit particles when the target node is hit.
## Place this component above the sprites of the target node to make it more visible.
class_name HitPatriclesComponent

## This component is needed to know if the target node has been hit
@export var stats_synchronizer: StatsSynchronizerComponent

## The target node to which the component should act upon
var _target_node: Node = null

# The actual particles for this component
@onready var _particles: CPUParticles2D = $CPUParticles2D


func _ready():
	_target_node = get_parent()

	assert(_target_node.multiplayer_connection != null, "Target's multiplayer connection is null")

	# This component should not run on the server
	if _target_node.multiplayer_connection.is_server():
		set_physics_process(false)
		queue_free()
		return

	# The position is needed to calculate the angle of the particles
	if _target_node.get("position") == null:
		GodotLogger.error("_target_node does not have the position variable")
		return

	# Connect to the hurt signal to know when to emit particles
	stats_synchronizer.got_hurt.connect(_on_got_hurt)


func _on_got_hurt(from: String, _damage: int):
	# Fetch the attacker using the name
	var attacker = _target_node.multiplayer_connection.map.get_entity_by_name(from)

	# Only emit the particles if the attacker exist
	if attacker != null:
		# Face the attacker first
		_particles.look_at(attacker.position)

		# Rotate with PI (180 degrees)
		_particles.rotate(PI)

		# emit the particles
		_particles.emitting = true
