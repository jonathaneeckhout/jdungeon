extends Node
class_name StatusEffectComponent

const TICK_INTERVAL:float = 0.1

@export_group("Node References")
@export var user: Node
@export var stats_component: StatsSynchronizerComponent

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

func process_statuses():
	for status: String in status_effects_active:
		var startDuration: float = get_duration(status)
		var startStacks: int = get_stacks(status)
		var startResource: Resource = get_resource(status)
		
		# Run this status' effect
		startResource._effect_tick(user, status_effect_to_json_data(status, true))
		
		# Progress the duration
		set_duration(status, startDuration - TICK_INTERVAL)
		
		#If it timed out, reduce the amount of stacks and proc the timeout effect
		if get_duration(status) <= 0:
			set_stacks(status, (startStacks - (startStacks * startResource.stack_consumption_percent)) - startResource.stack_consumption_flat )
			startResource._effect_timeout(user, status_effect_to_json_data(status, true))
		
		#If any stacks remain, reset the duration. Otherwise remove this status.
		if get_stacks(status) > 0:
			set_duration(status, startDuration)
		else:
			remove_status(status)


func add_status_effect(status_class: String, stack_override: int = -1, duration_override: float = -1.0):
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
	
	var res: StatusEffectResource = get_resource(status_class)
	if res is StatusEffectResource:
		res._effect_applied(user, status_effect_to_json_data(status_class, true))
	else:
		GodotLogger.error("This status effects' resource wasn't properly set.")
	return newStatus


func remove_status(status_class: String):
	status_effects_active.erase(status_class)


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
	return status_effects_active.get(status_class,{}).get("stacks",0.0)
	

func set_resource(status_class: String, resource: StatusEffectResource):
	if not status_effects_active.has(status_class):
		return
		
	status_effects_active[status_class]["resource"] = resource


func get_resource(status_class: String) -> StatusEffectResource:
	return status_effects_active.get(status_class,{}).get("resource",null)


func has_status_effect(status_effect: String) -> bool:
	return status_effects_active.has(status_effect)

func status_effect_to_json_data(status_class: String, include_owner: bool) -> Dictionary:
	if not status_effects_active.has(status_class):
		GodotLogger.error("This status is not present at this time.")
		return {}
		
	var output: Dictionary = status_effects_active.get(status_class)
	if include_owner:
		output["owner"] = user.get_name()
	return output
	
func sync_all(id: int):
	G.sync_rpc.
	
#Runs on server only
func sync_add_effect(id: int, status_effect: String):
	assert(G.is_server())
	assert(has_status_effect(status_effect))
	G.sync_rpc.statuseffectcomponent_sync_add_effect_response.rpc_id(id, status_effect, status_effect_to_json_data(status_effect, false))


func sync_add_effect_response(status_effect: String, status_json: Dictionary):
	add_status_effect(status_effect, status_json["stacks"], status_json["duration"])
	

func to_json() -> Dictionary:
	var output: Dictionary
	for status_class: String in status_effects_active:
		output[status_class] = {
			"duration":get_duration(status_class),
			"stacks":get_stacks(status_class),
		}
	return output


func from_json(data: Dictionary):
	for status_class: String in data:
		assert(data[status_class].size() == 2)
		add_status_effect(status_class, data[status_class]["stacks"], data[status_class]["duration"])

