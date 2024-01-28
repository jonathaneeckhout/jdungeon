extends Area2D
class_name MapArea2D

const COMPONENT_NAME: String = "map_area_component"

@export var target_node: Node = get_parent()

@export_group("Rule", "rule")
@export var rule_safe_zone: int

static var world: World2D



func _init() -> void:
	collision_layer = J.PHYSICS_LAYER_MAP_AREA
	collision_mask = 0
	
	
func _ready() -> void:
	if target_node.get("component_list"):
		target_node.component_list[COMPONENT_NAME] = self
	
	if not world is World2D:
		world = get_world_2d()
	

static func get_default_point_parameters() -> PhysicsPointQueryParameters2D:
	var parameters := PhysicsPointQueryParameters2D.new()
	parameters.collide_with_bodies = false
	parameters.collide_with_areas = true
	
	return parameters


static func get_areas_at_point(global_pos: Vector2)->Array[MapArea2D]:
	var areas_found: Array[MapArea2D]
	var direct_space: PhysicsDirectSpaceState2D = world.direct_space_state
	
	var parameters: PhysicsPointQueryParameters2D = get_default_point_parameters()
	parameters.position = global_pos
	
	var results: Array[Dictionary] = direct_space.intersect_point(parameters)
	for result: Dictionary in results:
		if result["collider"] is MapArea2D:
			areas_found.append(result["collider"])
		else:
			GodotLogger.warn("Found non-MapArea2D in MAP_AREA layer with path '{0}'".format([result["collider"].get_node_path()]))
	
	return areas_found
	
	
