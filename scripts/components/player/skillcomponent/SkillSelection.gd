extends Control
class_name SkillSelectionUI

const PACKED_SCENE: PackedScene = preload("res://scripts/components/player/skillcomponent/SkillSelection.tscn")

@export var skill_class_container: Container
@export var skill_slot_container: Container

@onready var confirm_button: Button = $Confirm
@onready var close_button: Button = $Close

var char_class_component: CharacterClassComponent
var skill_component: SkillComponent

var selected_button: SkillButton:
	set(val):
		#If one was already selected, deselect it visually.
		if selected_button is SkillButton:
			selected_button.set_pressed_no_signal(false)
			selected_button.update_visual()
			
		selected_button = val
		
		#If a new one was selected, press it visually
		if selected_button is SkillButton:
			selected_button.set_pressed_no_signal(true)
			selected_button.update_visual()			


func _ready() -> void:
	close_button.pressed.connect(close)
	confirm_button.pressed.connect(save_selection)


func select_target(player: Node):
	char_class_component = G.world.get_entity_component_by_name(player.get_name(), CharacterClassComponent.COMPONENT_NAME)
	skill_component = G.world.get_entity_component_by_name(player.get_name(), SkillComponent.COMPONENT_NAME)


## Sets the buttons for both skill classes and player owned classes.
func populate_ui():
	#Clear both main containers
	for child: Node in skill_class_container.get_children() + skill_slot_container.get_children():
		child.queue_free()
		
	#Show class related skills
	for charClass: CharacterClassResource in char_class_component.classes:
		var horizontalCont := HBoxContainer.new()
		horizontalCont.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		horizontalCont.size_flags_vertical = Control.SIZE_EXPAND_FILL
		skill_class_container.add_child(horizontalCont)
		
		var classIcon := TextureRect.new()
		classIcon.texture = charClass.get_icon()
		classIcon.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		horizontalCont.add_child(classIcon)
		
		populate_container(horizontalCont, charClass.available_skills, false)
	
	#Show player owned skills
	var horizontalCont := HBoxContainer.new()
	horizontalCont.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	horizontalCont.size_flags_vertical = Control.SIZE_EXPAND_FILL
	skill_slot_container.add_child(horizontalCont)
	populate_container(horizontalCont, skill_component.get_skills_classes(), true)
		

func populate_container(container: Container, skill_resources: Array[String], slots: bool):
	for child: Node in container.get_children():
		child.queue_free()
	
	for skill_class: String in skill_resources:
		
		var skillRes: SkillComponentResource = J.skill_resources[skill_class].duplicate()
		
		#Skip if an empty index is found and these are not slots.
		if not slots and not skillRes is SkillComponentResource:
			continue
			
		var button := SkillButton.new(skillRes.skill_class, slots)
		button.self_pressed.connect(_on_skill_button_pressed)
		skill_slot_container.add_child(button)
	
	#If this was a slots container
	if slots:
		#Fill any remaining slots.
		while container.get_child_count() < SkillBarUI.DEFAULT_MAX_SKILL_COUNT:
			var button := SkillButton.new("", true)
			container.add_child(button)
					

func save_selection():
	skill_component.clear_skills()
	for button: SkillButton in skill_slot_container.get_children():
		assert(button.is_slot)
		#Skip if it has no skill
		if button.skill_class == "":
			continue
			
		skill_component.add_skill(button.skill_class)
		
		
func close():
	if is_inside_tree():
		get_parent().remove_child(self)
		
	
func _on_skill_button_pressed(skill_button: SkillButton):
	#A slot button has been pressed and another button was already selected
	if skill_button.is_slot and selected_button:
		skill_button.skill_class = selected_button.skill_class
		
		#If another slot was selected, remove the skill it had as to transfer it.
		if selected_button.is_slot:
			selected_button.skill_class = ""
		
		#Deselect the previously selected button
		selected_button = null
	
	elif not selected_button:
		selected_button = skill_button
	
	#If a button is still selected.
	skill_button.update_visual()
	
	
class SkillButton extends Button:
	
	signal self_pressed(selfRef: SkillButton)
	
	var is_slot: bool = false
	
	var skill_class: String = ""
	
	func _init(_skill_class: String, _is_slot: bool) -> void:
		is_slot = _is_slot
		skill_class = _skill_class
		
	func _ready() -> void:
		assert(J.skill_resources.has(skill_class) or is_slot, "Non-slots MUST have a valid skill_class")
		set_anchors_preset(Control.PRESET_FULL_RECT)
		size_flags_vertical = Control.SIZE_EXPAND_FILL
		update_visual()

	func update_visual():
		custom_minimum_size.x = size.y
		if not skill_class:
			return
			
		var res: SkillComponentResource = J.skill_resources[skill_class].duplicate()
		icon = res.get_icon()
	
	func _pressed() -> void:
		self_pressed.emit(self)
		
