extends HBoxContainer

@export var skill_component: SkillComponent

@export var max_skills: int = 5

var displays: Array[SkillDisplay]
var display_selected: SkillDisplay

const EMPTY_ICON: Texture = preload("res://assets/images/enemies/flower/Flower.png")

func _ready() -> void:
	skill_component.skill_index_selected.connect(_on_skill_selected)
	update_displays()
	

func _on_skill_selected(index: int):
	var displaySelected: SkillDisplay = displays[index]
	var skillSelected: SkillComponentResource = skill_component.skills[index]
	
	#Ensure that the index corresponds to the shown skill
	if displaySelected.skill_class != skillSelected.skill_class:
		J.logger.error('The selected skill and the button used do not have the same "skill_class".')
		return
	
	#Deselect the current one and select the new one
	if display_selected:
		display_selected.deselect()
		
	display_selected = displaySelected
	display_selected.select()
		

#Only creates/removes the amount of displays, it's not necessary if the amount has not changed.
func update_displays():
	#Delete existing ones
	for child in get_children():
		child.queue_free()
	displays.clear()
		
	#Add new ones
	for index in max_skills:
		var display := SkillDisplay.new()
		display.texture = EMPTY_ICON
		display.index = index
		displays.append(display)
		add_child(display)
		
	update_icons()
	
#Should be called anytime that the user's available skills change
func update_icons():
	var skillList: Array[SkillComponentResource] = get_skills()
	
	for index in max_skills:
		var currentDisplay: SkillDisplay = displays[index]
		
		#If it is a skill, show it's icon and store it's class
		if index < skillList.size() and skillList[index] is SkillComponentResource:
			currentDisplay.texture = skillList[index].icon
			currentDisplay.skill_class = skillList[index].skill_class
		else:
			currentDisplay.texture = EMPTY_ICON
	

func get_skills()->Array[SkillComponentResource]:
	return skill_component.skills

class SkillDisplay extends TextureRect:
	
	@onready var currentTween := create_tween()
	var skill_class: String
	var index: int
	
	func _ready():
		currentTween.tween_property(self, "modulate", Color.WHITE * 0.6, 1)
		currentTween.tween_property(self, "modulate", Color.WHITE, 1)
		expand_mode = TextureRect.EXPAND_FIT_WIDTH
		
	
	func select():
		currentTween.play()

	func deselect():
		currentTween.stop()
		modulate = Color.WHITE
		
