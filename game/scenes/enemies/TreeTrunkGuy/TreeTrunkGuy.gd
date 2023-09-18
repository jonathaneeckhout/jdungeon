extends GMFEnemyBody2D

var current_state: String = "Idle"

@onready var animaiton_player = $AnimationPlayer

@onready var skeleton = $Skeleton
@onready var original_scale = $Skeleton.scale


func _ready():
	super()
	entity_type = Gmf.ENTITY_TYPE.ENEMY
	enemy_class = "TreeTrunkGuy"

	if Gmf.is_server():
		return

	state_changed.connect(_on_state_changed)

	animaiton_player.play(current_state)


func update_face_direction():
	if velocity.x < 0:
		skeleton.scale = original_scale
	else:
		skeleton.scale = Vector2(original_scale.x * -1, original_scale.y)


func _on_state_changed(new_state: String):
	current_state = new_state
