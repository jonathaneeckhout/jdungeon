extends GMFPlayerBody2D

var current_animation: String = "Idle"
var current_facing: String = "Down"


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


func _physics_process(delta):
	super(delta)

	if Gmf.is_server():
		return


func _on_state_changed(new_state: String):
	Gmf.logger.info("Player's new state=[%s]" % new_state)
