extends JEnemyBody2D

signal destination_reached
signal stuck

@onready var animation_player := $AnimationPlayer
@onready var floating_text_scene = preload("res://scenes/templates/JFloatingText/JFloatingText.tscn")
@onready var avoidance_rays := $AvoidanceRays
@onready var beehave_tree := $BeehaveTree
@onready var destination = self.global_position:
	set(new_destination):
		destination = new_destination
		enroute_to_destination = true
@onready var stuck_timer := $StuckTimer
@onready var sprite := $Sprite2D

var enroute_to_destination = false
var movement_multiplier := 1.0


func _init():
	super()
	enemy_class = "Sheep"
	stats.movement_speed = 50
	stats.hp_max = 20
	stats.hp = stats.hp_max
	stats.experience_worth = 10


func _ready():
	# Make sure to connect to all signals before super is called
	if not J.is_server() and J.client.player:
		stats.stats_changed.connect(_on_stats_changed)
	super()
	if J.is_server():
		beehave_tree.enabled = true
	synchronizer.loop_animation_changed.connect(_on_loop_animation_changed)
	synchronizer.got_hurt.connect(_on_got_hurt)
	synchronizer.died.connect(_on_died)
	stuck_timer.timeout.connect(_on_stuck_timer_timeout)
	animation_player.play(loop_animation)
	animation_player.animation_finished.connect(_on_animation_finished)
	$JInterface.display_name = enemy_class
	_add_loot()


func _add_loot():
	add_item_to_loottable("Gold", 1.0, 5)


func _physics_process(_delta):
	update_face_direction(velocity.x)
	if J.is_server():
		if position.distance_to(destination) > J.ARRIVAL_DISTANCE:
			velocity = position.direction_to(destination) * stats.movement_speed
			velocity = (
				avoidance_rays.find_avoidant_velocity(stats.movement_speed) * movement_multiplier
			)
			move_and_slide()
			send_new_loop_animation("Move")
			if get_slide_collision_count() > 0:
				if stuck_timer.is_stopped():
					stuck_timer.start()
			else:
				stuck_timer.stop()
		else:
			if enroute_to_destination:
				enroute_to_destination = false
				velocity = Vector2.ZERO
				send_new_loop_animation("Idle")
				destination_reached.emit()


func update_face_direction(direction: float):
	if direction < 0:
		sprite.flip_h = false
	if direction > 0:
		sprite.flip_h = true


func _on_animation_finished(_anim_name: String):
	if not is_dead:
		animation_player.play(loop_animation)


func _on_died():
	is_dead = true
	animation_player.stop()
	animation_player.play("Die")


func _on_got_hurt(_from: String, hp: int, damage: int):
	if not is_dead:
		animation_player.stop()
		animation_player.play("Hurt")
	$JInterface.update_hp_bar(hp, stats.hp_max)
	var text = floating_text_scene.instantiate()
	text.amount = damage
	text.type = text.TYPES.DAMAGE
	add_child(text)


func _on_loop_animation_changed(animation: String, direction: Vector2):
	if not is_dead:
		loop_animation = animation
		update_face_direction(direction.x)
		animation_player.play(animation)


func _on_stats_changed(type: JStats.TYPE):
	if type == JStats.TYPE.HP or type == JStats.TYPE.HP_MAX:
		$JInterface.update_hp_bar(stats.hp, stats.hp_max)


func _on_stuck_timer_timeout():
	stuck.emit()
