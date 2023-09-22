extends GMFPlayerBody2D

var current_animation: String = "Idle"

@onready var animaiton_player = $AnimationPlayer

@onready var skeleton = $Skeleton
@onready var original_scale = $Skeleton.scale


func _ready():
	super()

	if Gmf.is_server():
		return

	state_changed.connect(_on_state_changed)
	attacked.connect(_on_attacked)

	animaiton_player.play(current_animation)


func _physics_process(delta):
	super(delta)

	if Gmf.is_server():
		return

	if state == STATE.MOVE:
		update_face_direction()


func update_face_direction():
	if velocity.x < 0:
		skeleton.scale = original_scale
		return
	if velocity.x > 0:
		skeleton.scale = Vector2(original_scale.x * -1, original_scale.y)
		return


func _on_state_changed(new_state: STATE, _direction: Vector2, _duration: float):
	state = new_state

	match new_state:
		STATE.IDLE:
			animaiton_player.play("Idle")
		STATE.MOVE:
			animaiton_player.play("Move")
		STATE.ATTACK:
			pass


func _on_attacked(_target: String, _damage: int):
	animaiton_player.stop()
	animaiton_player.play("Attack")
