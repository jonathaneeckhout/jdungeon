extends JEnemyBody2D

@onready var sprite := $Sprite2D
@onready var anim_player := $AnimationPlayer
@onready var floating_text_scene = preload("res://scenes/templates/JFloatingText/JFloatingText.tscn")

var is_dead: bool = false

func _ready():
	super()
	enemy_class = "Sheep"
	stats.movement_speed = 50
	stats.max_hp = 30

	synchronizer.loop_animation_changed.connect(_on_loop_animation_changed)
	synchronizer.got_hurt.connect(_on_got_hurt)
	synchronizer.died.connect(_on_died)

	$JInterface.display_name = enemy_class

	var behavior: JWanderBehavior = load("res://scripts/classes/behaviors/JWanderBehavior.gd").new()
	behavior.name = "WanderBehavior"
	behavior.actor = self

	add_child(behavior)

	add_item_to_loottable("Gold", 1.0, 5)


func _physics_process(_delta):
	if loop_animation == "Move":
		update_face_direction(velocity.x)


func update_face_direction(direction: float):
	if direction < 0:
		sprite.flip_h = false
	if direction > 0:
		sprite.flip_h = true

func _on_loop_animation_changed(animation: String, direction: Vector2):
	loop_animation = animation
	anim_player.play(loop_animation)
	update_face_direction(direction.x)


func _on_got_hurt(_from: String, hp: int, max_hp: int, damage: int):
	if not is_dead:
		anim_player.stop()
		anim_player.play("Hurt")

	$JInterface.update_hp_bar(hp, max_hp)

	var text = floating_text_scene.instantiate()
	text.amount = damage
	text.type = text.TYPES.DAMAGE
	add_child(text)

func _on_died():
	is_dead = true
	anim_player.stop()
	anim_player.play("Die")
