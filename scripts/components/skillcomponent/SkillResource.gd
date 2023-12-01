extends Resource
class_name SkillComponentResource

const ENTITY_TYPES := J.ENTITY_TYPE

@export var skill_class: String

@export var displayed_name: String = "Skidadle Skidoodle"  #Failsafe name

@export var energy_usage: int = 0

@export var icon: Texture = load("res://icon.svg")

@export_flags_2d_physics var collision_mask: int = (
	J.PHYSICS_LAYER_PLAYERS + J.PHYSICS_LAYER_ENEMIES + J.PHYSICS_LAYER_NPCS + J.PHYSICS_LAYER_ITEMS
)

@export var valid_entities: Array[ENTITY_TYPES] = [ENTITY_TYPES.ENEMY]

@export var cooldown: float = 0

#Instantly uses the ability upon selection using the user's position as a target.
@export var cast_on_select: bool

@export var damage: int = 0

## Use a single point to create a circle using the single point as radius, use more than 3 points to create a polygon
@export var hitbox_shape: PackedVector2Array = [
	#Example of a rhombus hitbox: Vector2.LEFT * 5, Vector2.DOWN * 5, Vector2.RIGHT * 5, Vector2.UP * 5
	Vector2.RIGHT * 50
]

#This prevents the hitbox from detecting the user, does not prevent effects that directly reference it.
@export var hitbox_hits_user: bool = false

#If true, the shape rotates to face where the player does
@export var hitbox_rotate_shape: bool = false

#Skills cannot be used past this range
@export var hit_range: float = 100

@export_multiline var description: String = "This does something, right? ...right?"


func effect(information: SkillComponent.UseInfo):
	#Filter targets to make sure they are valid ones
	var filteredTargets: Array[Node] = []
	for target in information.targets:
		if target.get("entity_type") is int and target.get("entity_type") in valid_entities:
			filteredTargets.append(target)
	information.targets = filteredTargets

	if damage > 0:
		for stats in information.get_target_stats_all():
			stats.hurt(information.user, damage)

	_effect(information)


func _target_filter(_target: Node) -> bool:
	return true


func _effect(_info: SkillComponent.UseInfo):
	pass


## Can be used for custom descriptions
func get_description() -> String:
	return description


## This function is meant for rich text versions of the description, for the future tooltip system.
func get_description_rich() -> String:
	GodotLogger.warn("No rich description has been defined for skill {0}.".format([skill_class]))
	return description
