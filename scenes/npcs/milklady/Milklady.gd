extends JNPCBody2D

@onready var animation_player = $AnimationPlayer
@onready var skeleton = $Skeleton
@onready var original_scale = $Skeleton.scale
@onready var avoidance_rays := $AvoidanceRays


func _init():
	super()

	npc_class = "MilkLady"
	is_vendor = true

	stats.movement_speed = 50


func _ready():
	synchronizer.loop_animation_changed.connect(_on_loop_animation_changed)
	animation_player.play(loop_animation)

	if J.is_server():
		var behavior: JWanderBehavior = JWanderBehavior.new()
		behavior.name = "WanderBehavior"
		behavior.actor = self

		add_child(behavior)

		shop.size = 36

		shop.add_item("HealthPotion", 100)

		shop.add_item("Axe", 300)
		shop.add_item("Sword", 300)
		shop.add_item("Club", 200)

		shop.add_item("LeatherHelm", 50)
		shop.add_item("LeatherBody", 100)
		shop.add_item("LeatherArms", 100)
		shop.add_item("LeatherLegs", 100)

		shop.add_item("ChainMailHelm", 100)
		shop.add_item("ChainMailBody", 200)
		shop.add_item("ChainMailArms", 200)
		shop.add_item("ChainMailLegs", 200)

		shop.add_item("PlateHelm", 100)
		shop.add_item("PlateBody", 200)
		shop.add_item("PlateArms", 120)
		shop.add_item("PlateLegs", 150)


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
