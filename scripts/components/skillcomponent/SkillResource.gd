extends Resource
class_name SkillComponentResource

enum ControlType {TARGETABLE, INSTANT}

@export var displayed_name: String = "Skidadle Skidoodle" #Failsafe name

@export var energy_usage: int = 0

@export var cooldown: float = 0

## Use a single point to create a circle using the single point as radius, use more than 3 points to create a polygon
@export var hitbox_shape: PackedVector2Array = [Vector2.LEFT*5, Vector2.DOWN*5, Vector2.RIGHT*5, Vector2.UP*5]

#Skills cannot be used past this range
@export var hit_range: float = 25

@export var controlType: ControlType = ControlType.TARGETABLE


func effect(targets: Array[Node]):
	for target in targets:
		_effect(target)


func _target_filter(target: Node)->bool:
	return true

func _effect(target: Node):
	pass
	
