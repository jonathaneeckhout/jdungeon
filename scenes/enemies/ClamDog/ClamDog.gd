extends Enemy

signal destination_reached
signal stuck




@onready var action_synchronizer: ActionSynchronizerComponent = $ActionSynchronizerComponent
@onready var avoidance_rays := $AvoidanceRays
@onready var destination = self.global_position:
	set(new_destination):
		destination = new_destination
		enroute_to_destination = true
@onready var stuck_timer := $StuckTimer
@onready var beehave_tree := $BeehaveTree
@onready var loot: LootComponent = $LootComponent

var enroute_to_destination = false
var movement_multiplier := 1.0


func _init():
	super()
	enemy_class = "ClamDog"


func _ready():
	if J.is_server():
		beehave_tree.enabled = true
		stuck_timer.timeout.connect(_on_stuck_timer_timeout)

		_add_loot()
	else:
		avoidance_rays.queue_free()
		beehave_tree.queue_free()
		stuck_timer.queue_free()
		$Blackboard.queue_free()
		$AggroRadius.queue_free()

	$InterfaceComponent.display_name = enemy_class


func _add_loot():
	loot.add_item_to_loottable("Gold", 0.75, 100)
	loot.add_item_to_loottable("HealthPotion", 0.5, 1)


func _physics_process(_delta):
	if J.is_server():
		if position.distance_to(destination) > J.ARRIVAL_DISTANCE:
			velocity = position.direction_to(destination) * stats.movement_speed
			velocity = (
				avoidance_rays.find_avoidant_velocity(stats.movement_speed) * movement_multiplier
			)
			move_and_slide()
			if get_slide_collision_count() > 0:
				if stuck_timer.is_stopped():
					stuck_timer.start()
			else:
				stuck_timer.stop()
		else:
			if enroute_to_destination:
				enroute_to_destination = false
				velocity = Vector2.ZERO
				destination_reached.emit()


func attack(target: CharacterBody2D):
	var damage = randi_range(stats.attack_power_min, stats.attack_power_max)

	if target.get("stats"):
		target.stats.hurt(name, damage)
		action_synchronizer.attack(target.name, damage)


func _on_stuck_timer_timeout():
	stuck.emit()
