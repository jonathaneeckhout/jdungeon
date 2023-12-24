extends Node
class_name StatusEffectComponent

signal status_added(status: String)
## This includes removals due to timeout.
signal status_removed(status: String)

const TICK_INTERVAL:float = 0.1

@export_group("Node References")
@export var user: Node
@export var stats_component: StatsSynchronizerComponent

@export_group("Visuals")
@export var enable_drawing: bool = true:
	set(val):
		enable_drawing = val
		set_process(enable_drawing)
## When multiple statuses affect an entity, they will be drawn one besides the other in this direction.
@export var lineup_direction: Vector2i = Vector2i.RIGHT
## From where to start lining them.
@export var lineup_origin: Vector2
## The format is String:Dictionary
var status_effects_active: Dictionary

var status_tick_timer := Timer.new()

func _ready():
	if user.get("component_list") != null:
		user.component_list["status_effect_component"] = self
	
	status_tick_timer = Timer.new()
	status_tick_timer.name = "TickTimer"
	status_tick_timer.wait_time = TICK_INTERVAL
	status_tick_timer.autostart = true
	status_tick_timer.timeout.connect(process_statuses)
	add_child(status_tick_timer)

func draw_at_user():
	if not enable_drawing:
		return

func process_statuses():
	for status: String in status_effects_active:
		var startDuration: float = get_duration(status)
		var startStacks: int = get_stacks(status)
		var startResource: Resource = get_resource(status)
		
		# Run this status' effect
		startResource.effect_tick(user, get_status_effect_data(status))
		
		# Progress the duration
		set_duration(status, startDuration - TICK_INTERVAL)
		
		#If it timed out, reduce the amount of stacks and proc the timeout effect
		if get_duration(status) <= 0:
			set_stacks(status, (startStacks - (startStacks * startResource.stack_consumption_percent)) - startResource.stack_consumption_flat )
			startResource.effect_timeout(user, get_status_effect_data(status))
		
		#If any stacks remain, reset the duration. Otherwise remove this status.
		if get_stacks(status) > 0:
			set_duration(status, startDuration)
		else:
			remove_status(status)


func add_status_effect(status_class: String, applier: Node, stack_override: int = -1, duration_override: float = -1.0):
	var newStatus: StatusEffectResource = J.status_effect_resources[status_class].duplicate()
	var currDuration: float
	if duration_override >= 0:
		currDuration = duration_override
	else:
		currDuration = newStatus.default_duration
	
	var currStacks: int
	if stack_override >= 0:
		currStacks = stack_override
	else:
		currStacks = newStatus.default_stacks
	
	# If another of this class exists, combine it.
	if status_effects_active.has(newStatus.status_class):
		assert(status_effects_active[status_class].get("resource", false), "There's no resource set for this status effect")
		
		# If it can be stacked, add both togheter, otherwise, set duration to to highest of the two
		if newStatus.combine_stackable_duration:
			set_duration(status_class, currDuration)
		else:
			set_duration(status_class, max(get_duration(status_class), currDuration) )
		
		if newStatus.combine_stack_override:
			set_stacks(status_class, max(get_stacks(status_class), currStacks) )
		else:
			set_stacks(status_class, get_stacks(status_class) + currStacks )
	else:
		status_effects_active[status_class] = {}
		set_duration(status_class, currDuration)
		set_stacks(status_class, currStacks)
		set_resource(status_class, newStatus)
		set_applier(status_class, applier.get_name())
		assert(get_resource(status_class) is StatusEffectResource)
	
	get_resource(status_class).effect_applied(user, get_status_effect_data(status_class))
	
	status_added.emit(status_class)
	return newStatus


func remove_status(status_class: String):
	get_resource(status_class).effect_removed(user, get_status_effect_data(status_class))
	status_effects_active.erase(status_class)
	status_removed.emit(status_class)


func set_duration(status_class: String, dur: float):
	if not status_effects_active.has(status_class):
		return
	
	status_effects_active[status_class]["duration"] = dur


func get_duration(status_class: String) -> float:
	# Equivalent of return status_effects_active[status_class]["duration"]
	# But safe.
	return status_effects_active.get(status_class,{}).get("duration",0.0)


func set_stacks(status_class: String, sta: int):
	if not status_effects_active.has(status_class):
		return
		
	status_effects_active[status_class]["stacks"] = sta


func get_stacks(status_class: String) -> int:
	return status_effects_active.get(status_class,{}).get("stacks",0)
	

func set_resource(status_class: String, resource: StatusEffectResource):
	if not status_effects_active.has(status_class):
		return
		
	status_effects_active[status_class]["resource"] = resource


func get_resource(status_class: String) -> StatusEffectResource:
	return status_effects_active.get(status_class,{}).get("resource",null)


func set_applier(status_class: String, applier_name: String):
	if not status_effects_active.has(status_class):
		return
		
	status_effects_active[status_class]["applier"] = applier_name
	
func get_applier(status_class: String) -> String:
	return status_effects_active.get(status_class,{}).get("applier","")


func has_status_effect(status_class: String) -> bool:
	return status_effects_active.has(status_class)

	
#Called and ran on server
func sync_all(id: int):
	assert(G.is_server())
	G.sync_rpc.statuseffectcomponent_sync_all_response.rpc_id(id, user.get_name(), to_json())


func sync_all_response(data: Dictionary):
	from_json(data)
	
	
#Runs on server only
func sync_add_effect(id: int, status_effect: String):
	assert(G.is_server())
	assert(has_status_effect(status_effect))
	G.sync_rpc.statuseffectcomponent_sync_add_effect_response.rpc_id(id, status_effect, get_status_effect_data(status_effect, false))


func sync_effect_response(status_class: String, status_json: Dictionary):
	status_effects_active[status_class] = {
		"stacks" : status_json["stacks"],
		"duration" : status_json["duration"],
		"applier" : status_json["applier"],
		"resource" : J.status_effect_resources[status_class].duplicate(),
	}
	
	
## This function creates a Dictionary with the data from the status effect for sending over the network or for passing to a status' "_effect()" method.
## [param add_owner] is only necessary for the "_effect" methods.
func get_status_effect_data(status_class: String) -> Dictionary:
	if not status_effects_active.has(status_class):
		GodotLogger.error("This status is not present in this component.")
		return {}
		
	var output: Dictionary = {
		"stacks" : get_stacks(status_class),
		"duration" : get_duration(status_class),
		"applier" : get_applier(status_class)
	}
	
	return output
	

func to_json() -> Dictionary:
	var output: Dictionary
	for status_class: String in status_effects_active:
		output[status_class] = {
			"duration" : get_duration(status_class),
			"stacks" : get_stacks(status_class),
			"applier" : get_applier(status_class),
		}
	return output


func from_json(data: Dictionary):
	for status_class: String in data:
		
		if not data[status_class].has("stacks"):
			GodotLogger.error("Could not sync '{0}' status, missing 'stacks'".format([status_class]))
			
		if not data[status_class].has("duration"):
			GodotLogger.error("Could not sync '{0}' status, missing 'duration'".format([status_class]))
			
		if not data[status_class].has("applier"):
			GodotLogger.error("Could not sync '{0}' status, missing 'applier'".format([status_class]))
			
		status_effects_active[status_class] = {
			"stacks" : data[status_class]["stacks"], 
			"duration" : data[status_class]["duration"],
			"applier" : data[status_class]["applier"],
			"resource" : J.status_effect_resources[status_class].duplicate()
			}

