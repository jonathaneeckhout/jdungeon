extends Control
class_name SkillSelectionUI

const SKILL_SLOT_BUTTON_GROUP: String = "SkillSelectionUI_SkillSlotButtonGroup"
const PACKED_SCENE: PackedScene = preload(
	"res://scripts/components/player/skillcomponent/SkillSelection.tscn"
)
const FEEDBACK_MESSAGES: Dictionary = {
	NO_DUPLICATE = "Cannot assign duplicate skills.",
	AWAITING_SLOT = "Select a slot in which to put the skill.",
	DESELECTED = "Aborted change.",
	SLOT_TO_SLOT_TRANSFER = "Your skill was moved to the new slot.",
	CLASS_TO_SLOT_TRANSFER = "Your skill has been assigned."
}

@export var skill_class_container: Container
@export var skill_slot_container: Container

@export var feedback_duration_default: float = 3

@onready var confirm_button: Button = $Confirm
@onready var close_button: Button = $Close
@onready var feedback_label: Label = $Feedback
@onready var selected_label: Label = $SelectedSkill

var char_class_component: CharacterClassComponent
var skill_component: SkillComponent

var selected_button: SkillButton:
	set(val):
		#If one was already selected
		if selected_button is SkillButton:
			selected_button.modulate = Color.WHITE
			selected_button.update_visual()

		selected_button = val

		#If a new one was selected (instead of setting to null)
		if selected_button is SkillButton:
			selected_label.text = selected_button.skill_name
			selected_button.modulate = Color.GREEN
			selected_button.update_visual()

var feedbackFadeTimer := Timer.new()


func _ready() -> void:
	close_button.pressed.connect(close)
	confirm_button.pressed.connect(save_selection)

	add_child(feedbackFadeTimer)
	feedbackFadeTimer.timeout.connect(set_text_feedback.bind(""))

	var tween := feedback_label.create_tween().set_parallel(false).set_loops()
	tween.tween_property(feedback_label, "modulate", Color(0.7, 0.7, 0.7, 1), 1)
	tween.tween_property(feedback_label, "modulate", Color.WHITE, 1)
	tween.play()


func select_target(player: Node):
	char_class_component = G.world.get_entity_component_by_name(
		player.get_name(), CharacterClassComponent.COMPONENT_NAME
	)
	skill_component = G.world.get_entity_component_by_name(
		player.get_name(), SkillComponent.COMPONENT_NAME
	)


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
	var horizontalContOwned := HBoxContainer.new()
	horizontalContOwned.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	horizontalContOwned.size_flags_vertical = Control.SIZE_EXPAND_FILL
	skill_slot_container.add_child(horizontalContOwned)
	populate_container(horizontalContOwned, skill_component.get_skills_classes(), true)


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
		container.add_child(button)

	#If this was a slots container
	if slots:
		#Fill any remaining slots.
		while container.get_child_count() < SkillBarUI.DEFAULT_MAX_SKILL_COUNT:
			var button := SkillButton.new("", true)
			container.add_child(button)


func save_selection():
	skill_component.clear_skills()
	for button: SkillButton in get_tree().get_nodes_in_group(SKILL_SLOT_BUTTON_GROUP):
		assert(button.is_slot)
		#Skip if it has no skill
		if button.skill_class == "":
			continue

		skill_component.add_skill(button.skill_class)


func close():
	if is_inside_tree():
		get_parent().remove_child(self)


func _on_skill_button_pressed(skill_button: SkillButton):
	#A button was already selected
	if selected_button:
		#If a slot was clicked and the selected_button is not a slot, assign the skill IF not already owned.
		if skill_button.is_slot and not selected_button.is_slot:
			#Cancel if it is already present
			if is_skill_already_owned(selected_button.skill_class):
				set_text_feedback(FEEDBACK_MESSAGES.NO_DUPLICATE, feedback_duration_default)
				selected_button = null

			else:
				set_text_feedback(
					FEEDBACK_MESSAGES.CLASS_TO_SLOT_TRANSFER, feedback_duration_default
				)
				skill_button.skill_class = selected_button.skill_class
				selected_button = null

		#If another slot was the selected_button, remove the skill it had after transfering it.
		elif selected_button.is_slot and skill_button.is_slot:
			set_text_feedback(FEEDBACK_MESSAGES.SLOT_TO_SLOT_TRANSFER, feedback_duration_default)
			var skillToMove: String = selected_button.skill_class
			var skillToReplace: String = skill_button.skill_class

			skill_button.skill_class = skillToMove
			selected_button.skill_class = skillToReplace
			selected_button = null

	#If no button had been selected yet, do so.
	elif not selected_button:
		set_text_feedback(FEEDBACK_MESSAGES.AWAITING_SLOT)
		selected_button = skill_button

	#If the same button was pressed, deselect it.
	elif selected_button == skill_button:
		set_text_feedback(FEEDBACK_MESSAGES.DESELECTED, feedback_duration_default)
		selected_button = null

	#selected_button gets it's update in its setter
	skill_button.update_visual()


func is_skill_already_owned(skill_class: String) -> bool:
	if not get_tree():
		GodotLogger.error("Cannot run this from outside the tree.")
		return false

	for button: SkillButton in get_tree().get_nodes_in_group(SKILL_SLOT_BUTTON_GROUP):
		if button.skill_class == skill_class:
			return true

	return false


func set_text_feedback(text: String, duration: float = -1):
	feedback_label.text = text
	if duration > 0:
		feedbackFadeTimer.start(duration)


class SkillButton:
	extends Button

	signal self_pressed(selfRef: SkillButton)

	var is_slot: bool = false

	var skill_class: String = ""

	var skill_name: String

	var name_label := Label.new()

	func _init(_skill_class: String, _is_slot: bool) -> void:
		is_slot = _is_slot
		skill_class = _skill_class

	func _ready() -> void:
		assert(
			J.skill_resources.has(skill_class) or is_slot, "Non-slots MUST have a valid skill_class"
		)
		icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		expand_icon = true

		name_label.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
		name_label.add_theme_font_size_override("font_size", 32)
		name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		add_child(name_label)

		if is_slot:
			add_to_group(SKILL_SLOT_BUTTON_GROUP)
		update_visual()

	func update_visual():
		if not get_parent() is Control:
			return

		custom_minimum_size.x = min(
			get_parent().size.x / SkillBarUI.DEFAULT_MAX_SKILL_COUNT, get_parent().size.y
		)
		custom_minimum_size.y = custom_minimum_size.x
		if skill_class in J.skill_resources:
			var res: SkillComponentResource = J.skill_resources[skill_class].duplicate()
			icon = res.get_icon()
			skill_name = res.displayed_name
			tooltip_text = res.get_description()
			name_label.text = skill_name
		else:
			icon = SkillComponentResource.FAILSAFE_TEXTURE

	func _pressed() -> void:
		self_pressed.emit(self)
