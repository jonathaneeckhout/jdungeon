extends GMFEnemyBody2D

@onready var animation_player = $AnimationPlayer

@onready var skeleton = $Skeleton
@onready var original_scale = $Skeleton.scale

@onready var floating_text_scene = preload("res://gmf/common/scenes/GMFFloatingText/GMFFloatingText.tscn")


func _ready():
	super()

	enemy_class = "TreeTrunkGuy"

	synchronizer.got_hurt.connect(_on_got_hurt)

	animation_player.play(loop_animation)

	animation_player.animation_finished.connect(_on_animation_finished)

	$GMFInterface.display_name = enemy_class


func _on_got_hurt(_from: String, hp: int, max_hp: int, damage: int):
	animation_player.stop()
	animation_player.play("Hurt")

	$GMFInterface.update_hp_bar(hp, max_hp)

	var text = floating_text_scene.instantiate()
	text.amount = damage
	text.type = text.TYPES.DAMAGE
	add_child(text)


func _on_animation_finished(_anim_name: String):
	animation_player.play(loop_animation)
