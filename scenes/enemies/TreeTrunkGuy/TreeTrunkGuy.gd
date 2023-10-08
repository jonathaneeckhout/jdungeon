extends JEnemyBody2D

@onready var animation_player = $AnimationPlayer

@onready var skeleton = $Skeleton
@onready var original_scale = $Skeleton.scale
@onready var avoidance_rays := $AvoidanceRays
@onready var floating_text_scene = preload("res://scenes/templates/JFloatingText/JFloatingText.tscn")
var is_dead: bool = false


func _init():
	super()

	enemy_class = "TreeTrunkGuy"

	stats.movement_speed = 150


func _ready():
	# Make sure to connect to all signals before super is called
	if not J.is_server() and J.client.player:
		stats.synced.connect(_on_stats_synced)

	super()

	synchronizer.loop_animation_changed.connect(_on_loop_animation_changed)
	synchronizer.got_hurt.connect(_on_got_hurt)
	synchronizer.died.connect(_on_died)

	animation_player.play(loop_animation)

	animation_player.animation_finished.connect(_on_animation_finished)

	$JInterface.display_name = enemy_class

	var behavior: JWanderBehavior = load("res://scripts/classes/behaviors/JWanderBehavior.gd").new()
	behavior.name = "WanderBehavior"
	behavior.actor = self

	add_child(behavior)

	add_item_to_loottable("Gold", 1.0, 100)
	add_item_to_loottable("HealthPotion", 1.0, 1)


func _physics_process(_delta):
	if loop_animation == "Move":
		update_face_direction(velocity.x)


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


func _on_got_hurt(_from: String, hp: int, max_hp: int, damage: int):
	if not is_dead:
		animation_player.stop()
		animation_player.play("Hurt")

	$JInterface.update_hp_bar(hp, max_hp)

	var text = floating_text_scene.instantiate()
	text.amount = damage
	text.type = text.TYPES.DAMAGE
	add_child(text)


func _on_animation_finished(_anim_name: String):
	if not is_dead:
		animation_player.play(loop_animation)


func _on_died():
	is_dead = true
	animation_player.stop()
	animation_player.play("Die")


func _on_stats_synced():
	$JInterface.update_hp_bar(stats.hp, stats.max_hp)
