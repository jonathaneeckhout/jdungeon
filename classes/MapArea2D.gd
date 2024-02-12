extends Area2D
class_name MapArea2D
## A way to define special functionality in certain parts of the map.
## These are intended to be on the client side as well.
## Other objects may use

#TODO: Allow creating and removing areas during runtime

enum Rules {
	PVP = 1, # Not implemented. Players cannot damage other players under any circumstances.
	SAFE = 2,# The player may regenerate health and perform other "downtime" activities.
	NO_ENEMY_PATH = 4,# Not implemented. Enemies may not enter this area under any circumstances.
}

@export_flags(
	"Allow PVP:1",
	"Safe Zone:2",
	"Enemy Cannot Path:4"
	) var rules: int = 2

## These may be used as metadata for the area and are safe to be set by other objects.
@export var flags: Dictionary

static var world: World2D

func _init() -> void:
	collision_layer = J.PHYSICS_LAYER_MAP_AREA
	collision_mask = 0
	modulate.a = 0.2
	
	
func _ready() -> void:	
	if not world is World2D:
		world = get_world_2d()
	
	print(get_rules_as_text())
		

func is_rule_active(rule: Rules)->bool:
	return rule & rules

	
func get_rules_as_text() -> String:
	var output: String = ""
	for rule: String in Rules:
		output += rule + " active? " + str(is_rule_active(Rules[rule])) + "\n"
	
	return output


func set_flag(flag: String, state: bool):
	flags[flag] = state


func remove_flag(flag: String):
	flags.erase(flag)
	

static func get_default_point_parameters() -> PhysicsPointQueryParameters2D:
	var parameters := PhysicsPointQueryParameters2D.new()
	parameters.collide_with_bodies = false
	parameters.collide_with_areas = true
	parameters.collision_mask = J.PHYSICS_LAYER_MAP_AREA
	
	return parameters


static func get_areas_at_point(global_pos: Vector2)->Array[MapArea2D]:
	var areas_found: Array[MapArea2D] = []
	var direct_space: PhysicsDirectSpaceState2D = world.direct_space_state
	
	var parameters: PhysicsPointQueryParameters2D = get_default_point_parameters()
	parameters.position = global_pos
	
	var results: Array[Dictionary] = direct_space.intersect_point(parameters)
	for result: Dictionary in results:
		if result["collider"] is MapArea2D:
			areas_found.append(result["collider"])
		else:
			GodotLogger.warn("Found non-MapArea2D in MAP_AREA layer with path '{0}'".format([result["collider"].get_path()]))
	
	return areas_found
	
	
static func is_rule_active_at(global_pos: Vector2, rule_to_check: Rules) -> bool:
	var areas: Array[MapArea2D] = get_areas_at_point(global_pos)		
	for area: MapArea2D in areas:
		if area.is_rule_active(rule_to_check):
			return true
				
	return false


static func get_flags_at(global_pos: Vector2) -> Array[String]:
	var output: Array[String]
	var areas: Array[MapArea2D] = get_areas_at_point(global_pos)		
	for area: MapArea2D in areas:
		output += area.flags.values()
	
	return output
