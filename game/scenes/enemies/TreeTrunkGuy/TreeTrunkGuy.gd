extends GMFEnemyBody2D

@onready var animation_player = $AnimationPlayer

@onready var skeleton = $Skeleton
@onready var original_scale = $Skeleton.scale


func _ready():
	super()

	enemy_class = "TreeTrunkGuy"

	synchronizer.got_hurt.connect(_on_got_hurt)

	animation_player.play(loop_animation)

	animation_player.animation_finished.connect(_on_animation_finished)


func _on_got_hurt(_from: String, _hp: int, _damage: int):
	animation_player.stop()
	animation_player.play("Hurt")


func _on_animation_finished(_anim_name: String):
	animation_player.play(loop_animation)
