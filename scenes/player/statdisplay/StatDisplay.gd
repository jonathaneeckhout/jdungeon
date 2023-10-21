extends Control

@export var user: JBody2D
@export var targetContainer: Container

func _ready() -> void:
	if user and targetContainer:
		renew_displays()
	else:
		push_error("This StatDisplay has no user")

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("j_toggle_stats"):
		visible = !visible
		

func renew_displays():
	for child in targetContainer.get_children():
		child.queue_free()
		
	for statName in user.stats.Keys.values():
		add_single_stat(statName, statName)

func add_single_stat(statName:String, statKeyUsed:NodePath):
	var newStat := SingleStat.new(user.stats, statName, statKeyUsed)

	targetContainer.add_child(newStat)
	
class SingleStat extends HSplitContainer:
	
	var statsObject: JStats
	var statKeyUsed: NodePath
	var statName: String
	
	var labelStatName := Label.new()
	var labelStatValue := Label.new()
	
	func _init(i_statsObject:Node, i_statName:String, i_statKeyUsed:NodePath) -> void:
		statsObject = i_statsObject
		statKeyUsed = i_statKeyUsed
		statName = i_statName
		
		statsObject.stat_changed.connect( _on_stat_changed )
		dragger_visibility = SplitContainer.DRAGGER_HIDDEN
		
	func _ready() -> void:
		set_name(statName)
		
		labelStatName.text = tr(statName)
		labelStatName.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		add_child(labelStatName)
		
		labelStatValue.text = str( statsObject.stat_get(statName) )
		labelStatValue.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		add_child(labelStatValue)
		
		for stat in JStats.Keys.values():
			_on_stat_changed(stat)
		
	func _on_stat_changed(statKey: String):
		if NodePath(statKey) == statKeyUsed:
			labelStatValue.text = str( statsObject.stat_get(statKey) )

