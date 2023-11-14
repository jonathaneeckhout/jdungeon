extends HBoxContainer

@export var skill_component: SkillComponent

@export var max_skills: int = 5

var displays: Array[SkillDisplay]
var display_selected: SkillDisplay

const EMPTY_ICON: Texture = preload("res://assets/images/enemies/flower/Flower.png")

func _ready() -> void:
	skill_component.skills_changed.connect(update_icons)
	update_displays()
			

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
		display.skill_component = skill_component
		#If a skill is selected, tell the displays
		skill_component.skill_selected.connect(display._on_skill_selected)
		
		var nullSkill := func(variant, display: SkillDisplay):
			display._on_skill_selected(null)
		skill_component.skill_cast_on_select_selected.connect(nullSkill.bind(display))
		
		
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
			
			skill_component.skill_cooldown_started.connect(
				currentDisplay._on_skill_cooldown_change.bind(true)
				)
			skill_component.skill_cooldown_ended.connect(
				currentDisplay._on_skill_cooldown_change.bind(false)
				)
		else:
			currentDisplay.texture = EMPTY_ICON
	

func get_skills()->Array[SkillComponentResource]:
	return skill_component.skills

class SkillDisplay extends TextureRect:
		
	#Used to reference certain methods
	var skill_component: SkillComponent
		
	var skill_class: String	
	

	@onready var currentTween := create_tween()
	var cooldownText := Label.new()
	var selectionTexture := TextureRect.new()
	
	func _ready():
		currentTween.tween_property(self, "modulate", Color.WHITE * 0.6, 1)
		currentTween.tween_property(self, "modulate", Color.WHITE, 1)
		currentTween.set_loops()
		expand_mode = TextureRect.EXPAND_FIT_WIDTH
		
		selectionTexture.set_anchors_preset(Control.PRESET_FULL_RECT)
		selectionTexture.texture = load("res://assets/images/varia/logo/Logo_NoBG.png")
		selectionTexture.mouse_filter = Control.MOUSE_FILTER_IGNORE
		selectionTexture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		selectionTexture.hide()
		add_child(selectionTexture)
		
		cooldownText.set_anchors_preset(Control.PRESET_FULL_RECT)
		cooldownText.mouse_filter = Control.MOUSE_FILTER_IGNORE
		cooldownText.modulate = Color.RED
		cooldownText.add_theme_font_size_override("font_size", 42)
		cooldownText.add_theme_constant_override("outline_size", 10)
		cooldownText.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		cooldownText.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		cooldownText.hide()
		add_child(cooldownText)
	
	#Only runs while a skill is in cooldown	
	func _process(delta: float) -> void:
		cooldownText.text = str(skill_component.cooldown_get_time_left(skill_class))
	
	func select():
		currentTween.play()
		selectionTexture.show()
		
	func deselect():
		currentTween.stop()
		modulate = Color.WHITE
		selectionTexture.hide()
		
	func _on_skill_selected(skill: SkillComponentResource):
		#Null deactivates all displays
		if skill == null:
			print_debug("Deselected due to null")
			deselect()
		#If it is the skill from this display, activate
		elif skill.skill_class == skill_class:
			select()
		#If it isn't, deactivate
		else: 
			deselect()

	
	
	#If not "started", it means it ended.
	func _on_skill_cooldown_change(skillClass: String, started: bool):
		if skillClass == skill_class:
			cooldownText.visible = started
			set_process(started)
		
