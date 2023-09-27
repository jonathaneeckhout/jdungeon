extends JNPCBody2D

@onready var animation_player = $AnimationPlayer
@onready var skeleton = $Skeleton
@onready var original_scale = $Skeleton.scale


func _ready():
	super()

	npc_class = "MilkLady"
	is_vendor = true

	stats.movement_speed = 50

	synchronizer.loop_animation_changed.connect(_on_loop_animation_changed)
	animation_player.play(loop_animation)

	var behavior: JWanderBehavior = JWanderBehavior.new()
	behavior.name = "WanderBehavior"
	behavior.actor = self

	add_child(behavior)


func update_face_direction(direction: float):
	if direction < 0:
		skeleton.scale = original_scale
		return
	if direction > 0:
		skeleton.scale = Vector2(original_scale.x * -1, original_scale.y)
		return


func _on_loop_animation_changed(animation: String, direction: Vector2):
	loop_animation = animation

	animation_player.play(loop_animation)

	update_face_direction(direction.x)
