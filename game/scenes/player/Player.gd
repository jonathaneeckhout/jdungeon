extends GMFPlayerBody2D

var current_state: String = "Idle"

@onready var animaiton_player = $AnimationPlayer

@onready var skeleton = $Skeleton
@onready var original_scale = $Skeleton.scale


func _input(event):
	# Don't handle input on server side
	if Gmf.is_server():
		return

	if event.is_action_pressed("gmf_right_click"):
		move(get_global_mouse_position())


func _ready():
	super()

	if Gmf.is_server():
		return

	state_changed.connect(_on_state_changed)

	animaiton_player.play(current_state)


func _physics_process(delta):
	super(delta)

	if Gmf.is_server():
		return

	if current_state == "Move":
		update_face_direction()


func update_face_direction():
	if velocity.x < 0:
		skeleton.scale = original_scale
	else:
		skeleton.scale = Vector2(original_scale.x * -1, original_scale.y)


func _on_state_changed(new_state: String):
	Gmf.logger.info("Player's new state=[%s]" % new_state)
	current_state = new_state
	animaiton_player.play(new_state)
