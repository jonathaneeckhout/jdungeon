extends Node
class_name SkillComponent

@export var user: CharacterBody2D:
	set(val):
		user = val
		directSpace = user.get_world_2d().direct_space_state
@export var stats: StatsSynchronizerComponent

@export var skills: Array[SkillComponentResource]
@export var skill_current: SkillComponentResource

var directSpace: PhysicsDirectSpaceState2D
var shapeParameters := PhysicsShapeQueryParameters2D.new()

func skill_select_by_index(index: int):
	#Array supports negative values to select from the end of the Array
	if not abs(index) < abs(skills.size()):
		J.logger.error("Skill index out of range.")
		return
		
	skill_current = skills[index]
	pass

func use_at(globalPoint: Vector2):
	var targets: Array[CollisionObject2D] = get_targets(globalPoint)
	skill_current.effect(targets)
	
	
func get_targets(where: Vector2)->Array[CollisionObject2D]:
	update_collision_parameters()
	
	var collisions: Array[Dictionary] = directSpace.intersect_shape(shapeParameters)
	var targets: Array[CollisionObject2D] = []
	for coll in collisions:
		targets.append(coll.get("collider"))
	
	return targets

func get_user_facing()->Vector2:
	return Vector2.RIGHT
	pass
	
func update_collision_parameters():
	var shape := ConvexPolygonShape2D.new()
	shape.points = skill_current.hitbox_shape
	shapeParameters.shape = shape
