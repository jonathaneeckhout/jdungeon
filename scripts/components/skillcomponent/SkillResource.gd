extends Resource
class_name SkillComponentResource

@export var skill_class: String

@export var displayed_name: String = "Skidadle Skidoodle" #Failsafe name

@export var energy_usage: int = 0

@export var icon: Texture = load("res://icon.svg")

@export_flags_2d_physics var collision_mask: int = J.ENTITY_TYPE.ENEMY

@export var cooldown: float = 0

#Instantly uses the ability upon selection using the user's position as a target.
@export var cast_on_select: bool

@export var damage: int = 0

## Use a single point to create a circle using the single point as radius, use more than 3 points to create a polygon
@export var hitbox_shape: PackedVector2Array = [Vector2.LEFT*5, Vector2.DOWN*5, Vector2.RIGHT*5, Vector2.UP*5]

#This prevents the hitbox from detecting the user, does not prevent effects that directly reference it.
@export var hitbox_hits_user: bool = false

#If true, the shape rotates to face where the player does
@export var hitbox_rotate_shape: bool

#Skills cannot be used past this range
@export var hit_range: float = 100

#Time remaining on it's cooldown.
var cooldown_time_left: float:
	get:
		if cooldownTimerHolder is SceneTreeTimer:
			return cooldownTimerHolder.time_left
		else:
			return 0

var cooldownTimerHolder: SceneTreeTimer

func effect(information: SkillComponent.UseInfo):
	if damage > 0:
		for stats in information.get_target_stats_all():
			stats.hurt(information.user, damage)
	
	_effect(information)


func _target_filter(_target: Node)->bool:
	return true

func _effect(_info: SkillComponent.UseInfo):
	
	pass
	

