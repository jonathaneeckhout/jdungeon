extends Node2D
class_name StatusEffectComponent

const COMPONENT_NAME: String = "status_effect_component"
const TICK_INTERVAL: float = 0.2
const NUMBER_FONT: Font = preload("res://assets/fonts/fenwick-woodtype/FenwickWoodtype.ttf")

@export_group("Node References")
@export var user: Node2D
@export var stats_component: StatsSynchronizerComponent

@export_group("Visuals")
## If false, this node will node draw any status effects
@export var drawing_enabled: bool = true
## A rectangular space where the icons may be drawn.
@export var drawing_space: Rect2 = Rect2(0, 0, 128, 128)
## Extra space added after every icon.
@export var drawing_margin: Vector2 = Vector2(4, 4)
## The size of each icon for each status effect. The size includes height and width.
@export var drawing_icon_size: Vector2i = Vector2i.ONE * 32

## The format is String:Dictionary
var status_effects_active: Dictionary

var status_tick_timer := Timer.new()


func _ready():
	if user.get("component_list") != null:
		user.component_list[COMPONENT_NAME] = self

	stats_component.died.connect(clear_status)

	status_tick_timer = Timer.new()
	status_tick_timer.name = "TickTimer"
	status_tick_timer.wait_time = TICK_INTERVAL
	status_tick_timer.autostart = true
	# If it is the server, use the timer to process statuses, otherwise use it for drawing.
	if G.is_server():
		status_tick_timer.timeout.connect(process_statuses)
	else:
		status_tick_timer.timeout.connect(queue_redraw)
	add_child(status_tick_timer)


func _draw() -> void:
	if not drawing_enabled:
		return

	var nextStatusPos: Vector2 = drawing_space.position

	for status_class: String in status_effects_active:
		draw_status(status_class, nextStatusPos)

		#Set the position for the next icon
		nextStatusPos.x += drawing_icon_size.x + drawing_margin.x
		#If out of bounds of the box, shift down.
		if nextStatusPos.x > drawing_space.size.x:
			nextStatusPos.x = drawing_space.position.x
			nextStatusPos.y += drawing_icon_size.y + drawing_margin.y


func draw_status(status_class: String, pos: Vector2):
	draw_texture_rect(get_resource(status_class).get_icon(), Rect2(pos, drawing_icon_size), false)

	draw_string(NUMBER_FONT, pos + (Vector2(drawing_icon_size) / 2), str(get_stacks(status_class)))


#Server only
func process_statuses():
	for status: String in status_effects_active:
		var startDuration: float = get_duration(status)
		var startStacks: int = get_stacks(status)
		var startResource: StatusEffectResource = get_resource(status)

		# Run this status' effect
		startResource.effect_tick(user, get_status_effect_data(status))

		# Progress the duration
		set_duration(status, startDuration - TICK_INTERVAL)

		#If it timed out, reduce the amount of stacks and proc the timeout effect
		if get_duration(status) <= 0:
			startResource.effect_timeout(user, get_status_effect_data(status))
			set_stacks(
				status,
				(
					(startStacks - (startStacks * startResource.timeout_stack_consumption_percent))
					- startResource.timeout_satck_consumption_flat
				)
			)

			#If any stacks remain, reset the duration. Otherwise remove this status.
			if get_stacks(status) > 0:
				set_duration(status, startResource.default_duration)
			else:
				remove_status(status)

		if user.get("peer_id"):
			sync_effect(user.peer_id, status)


## Server only
func add_status_effect(
	status_class: String, applier: Node, stack_override: int = -1, duration_override: float = -1.0
):
	var newStatus: StatusEffectResource = J.status_effect_resources[status_class].duplicate()
	var currDuration: float
	if duration_override >= 0:
		currDuration = duration_override
		newStatus.default_duration = duration_override
	else:
		currDuration = newStatus.default_duration

	var currStacks: int
	if stack_override >= 0:
		currStacks = stack_override
		newStatus.default_stacks = stack_override
	else:
		currStacks = newStatus.default_stacks

	# If another of this class exists, combine it.
	if status_effects_active.has(newStatus.status_class):
		assert(
			status_effects_active[status_class].get("resource", false),
			"There's no resource set for this status effect"
		)

		# If it can be stacked, add both togheter, otherwise, set duration to to highest of the two
		if newStatus.combine_stackable_duration:
			set_duration(status_class, currDuration)
		else:
			set_duration(status_class, max(get_duration(status_class), currDuration))

		if newStatus.combine_stack_override:
			set_stacks(status_class, max(get_stacks(status_class), currStacks))
		else:
			set_stacks(status_class, get_stacks(status_class) + currStacks)
	else:
		status_effects_active[status_class] = {}
		set_duration(status_class, currDuration)
		set_stacks(status_class, currStacks)
		set_resource(status_class, newStatus)
		set_applier(status_class, applier.get_name())
		assert(get_resource(status_class) is StatusEffectResource)

	get_resource(status_class).effect_applied(user, get_status_effect_data(status_class))
	if Global.debug_mode:
		GodotLogger.info(
			"Added status effect '{0}' with {1} stacks and {2} duration.".format(
				[status_class, get_stacks(status_class), get_duration(status_class)]
			)
		)


## Server only
func remove_status(status_class: String):
	get_resource(status_class).effect_removed(user, get_status_effect_data(status_class))
	status_effects_active.erase(status_class)


func clear_status():
	for status: String in status_effects_active:
		remove_status(status)


func set_duration(status_class: String, dur: float):
	if not status_effects_active.has(status_class):
		GodotLogger.error("This status is not present in this component.")
		return

	status_effects_active[status_class]["duration"] = dur


func get_duration(status_class: String) -> float:
	# Equivalent of return status_effects_active[status_class]["duration"]
	# But safe.
	return status_effects_active.get(status_class, {}).get("duration", 0.0)


## If [param trigger_effect] is true, _effect_stack_changed() is called on the status.
func set_stacks(status_class: String, sta: int, trigger_effect: bool = false):
	if not status_effects_active.has(status_class):
		GodotLogger.error("This status is not present in this component.")
		return

	status_effects_active[status_class]["stacks"] = sta
	if trigger_effect:
		get_resource(status_class)._effect_stack_change(user, get_status_effect_data(status_class))


func get_stacks(status_class: String) -> int:
	return status_effects_active.get(status_class, {}).get("stacks", 0)


func set_resource(status_class: String, resource: StatusEffectResource):
	if not status_effects_active.has(status_class):
		GodotLogger.error("This status is not present in this component.")
		return

	status_effects_active[status_class]["resource"] = resource


func get_resource(status_class: String) -> StatusEffectResource:
	return status_effects_active.get(status_class, {}).get("resource", null)


func set_applier(status_class: String, applier_name: String):
	if not status_effects_active.has(status_class):
		GodotLogger.error("This status is not present in this component.")
		return

	status_effects_active[status_class]["applier"] = applier_name


func get_applier(status_class: String) -> String:
	return status_effects_active.get(status_class, {}).get("applier", "")


func has_status_effect(status_class: String) -> bool:
	return status_effects_active.has(status_class)


#Called and ran on server
func sync_all(id: int):
	assert(G.is_server())
	G.sync_rpc.statuseffectcomponent_sync_all_response.rpc_id(id, user.get_name(), to_json())


func sync_all_response(data: Dictionary):
	from_json(data)


#Runs on server only
func sync_effect(id: int, status_class: String):
	assert(G.is_server())
	if has_status_effect(status_class):
		G.sync_rpc.statuseffectcomponent_sync_effect_response.rpc_id(
			id, user.get_name(), status_class, get_status_effect_data(status_class), false
		)
	else:
		G.sync_rpc.statuseffectcomponent_sync_effect_response.rpc_id(
			id, user.get_name(), status_class, get_status_effect_data(status_class), true
		)


func sync_effect_response(status_class: String, status_json: Dictionary, remove: bool):
	if remove:
		status_effects_active.erase(status_class)
	else:
		status_effects_active[status_class] = {
			"stacks": status_json["stacks"],
			"duration": status_json["duration"],
			"applier": status_json["applier"],
			"resource": J.status_effect_resources[status_class].duplicate(),
		}


## This function creates a Dictionary with the data from the status effect for sending over the network or for passing to a status' "_effect()" method.
func get_status_effect_data(status_class: String) -> Dictionary:
	if not status_effects_active.has(status_class):
		GodotLogger.error("This status is not present in this component.")
		return {}

	var output: Dictionary = {
		"stacks": get_stacks(status_class),
		"duration": get_duration(status_class),
		"applier": get_applier(status_class)
	}

	return output


func to_json() -> Dictionary:
	var output: Dictionary = {}
	for status_class: String in status_effects_active:
		output[status_class] = {
			"duration": get_duration(status_class),
			"stacks": get_stacks(status_class),
			"applier": get_applier(status_class),
		}
	return output


func from_json(data: Dictionary):
	for status_class: String in data:
		if not data[status_class].has("stacks"):
			GodotLogger.error(
				"Could not sync '{0}' status, missing 'stacks'".format([status_class])
			)

		if not data[status_class].has("duration"):
			GodotLogger.error(
				"Could not sync '{0}' status, missing 'duration'".format([status_class])
			)

		if not data[status_class].has("applier"):
			GodotLogger.error(
				"Could not sync '{0}' status, missing 'applier'".format([status_class])
			)

		status_effects_active[status_class] = {
			"stacks": data[status_class]["stacks"],
			"duration": data[status_class]["duration"],
			"applier": data[status_class]["applier"],
			"resource": J.status_effect_resources[status_class].duplicate()
		}


## Used by server to synch signals with the client
func _on_signal_emitted(status_class: String, signa: String):
	assert(G.is_server())
	G.sync_rpc.statuseffectcomponent_sync_signal(user.get_name(), signa, status_class)
