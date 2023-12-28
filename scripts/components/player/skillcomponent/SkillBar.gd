extends Control
class_name SkillBarUI

const DEFAULT_MAX_SKILL_COUNT: int = 5

@export var skill_component: SkillComponent

@export var max_skills: int = DEFAULT_MAX_SKILL_COUNT

var displays: Array[SkillDisplay]
var display_selected: SkillDisplay

@onready var skill_container: HBoxContainer = $HBoxContainer

const EMPTY_ICON: Texture = preload("res://assets/images/ui/Empty.tres")


func _ready() -> void:
	skill_component.skills_changed.connect(update_icons)
	update_displays()


## Only creates/removes the amount of displays, it's not necessary if the amount has not changed.
func update_displays():
	#Delete existing ones
	for child in skill_container.get_children():
		child.queue_free()
	displays.clear()

	#Add new ones
	for index in max_skills:
		var display := SkillDisplay.new()

		display.texture = EMPTY_ICON
		display.skill_component = skill_component

		#If a skill is selected, tell the displays
		skill_component.skill_selected.connect(display._on_skill_selected)
		skill_component.skill_cast_on_select_selected.connect(
			display._on_skill_cast_on_select_selected
		)
		skill_component.skill_cooldown_updated.connect(display._on_skill_cooldown_updated)

		displays.append(display)
		skill_container.add_child(display)

	update_icons()


## Should be called anytime that the user's available skills change
func update_icons():
	var skillList: Array[SkillComponentResource] = get_skills()

	for index in max_skills:
		var currentDisplay: SkillDisplay = displays[index]

		#If it is a skill, show it's icon and store it's class
		if index < skillList.size() and skillList[index] is SkillComponentResource:
			currentDisplay.texture = skillList[index].get_icon()
			currentDisplay.skill_class = skillList[index].skill_class
			currentDisplay.tooltip_text = (
				skillList[index].displayed_name + "\n" + skillList[index].get_description()
			)
			currentDisplay.skill_component = skill_component

			assert(
				skill_component.skill_cooldown_updated.is_connected(
					currentDisplay._on_skill_cooldown_updated
				)
			)

		else:
			currentDisplay.texture = EMPTY_ICON


func get_skills() -> Array[SkillComponentResource]:
	return skill_component.skills


class SkillDisplay:
	extends TextureRect

	#Used to reference certain methods
	var skill_component: SkillComponent
	var skill_class: String:
		set(val):
			skill_class = val
			set_process(skill_class != "")

	var cooldownText := Label.new()
	var selectionTexture := TextureRect.new()

	func _ready():
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

		skill_class = skill_class
		assert(skill_component.skill_cooldown_updated.is_connected(_on_skill_cooldown_updated))

	func select():
		selectionTexture.show()

	func deselect():
		selectionTexture.hide()

	func _on_skill_cast_on_select_selected(_skill: SkillComponentResource):
		_on_skill_selected(null)

	func _on_skill_selected(skill: SkillComponentResource):
		#Null deactivates all displays
		if skill == null:
			deselect()

		#If it is the skill from this display, activate
		elif skill.skill_class == skill_class:
			select()

		#If it isn't, deactivate
		else:
			deselect()

	func _on_skill_cooldown_updated(skillClass: String, time: float):
		if skillClass == skill_class:
			cooldownText.text = str(time)

			if time <= 0:
				cooldownText.hide()
			else:
				cooldownText.show()
