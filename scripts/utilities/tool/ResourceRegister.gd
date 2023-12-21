@tool
extends Node
class_name ToolScriptResourceRegistryHelper

@export var generate: bool:
	set(val):
		generate = false
		generate_files()



# Folder paths should start with res://
@export var output_folder: String = "res://scripts/utilities/tool/output"
@export var register_function: String = "register_resources"

@export_group("Dialogues")
@export var dialogue_folder: String = "res://scenes/ui/dialogue/Dialogues/"
@export var dialogue_individual_register_function: String = "register_dialogue_resource"

@export_group("Character Classes")
@export var charClass_folder: String = "res://scripts/components/player/charclasscomponent/classes/"
@export var charClass_individual_register_function: String = "register_class_resource"


func get_path_to_output() -> String:
	var wantedPath: String = output_folder
	print(wantedPath)
	DirAccess.make_dir_recursive_absolute(wantedPath)
	return wantedPath

func generate_files():
	var path: String = get_path_to_output()+"/ResourceRegisterScriptOutput.gd"
	print(path)
	var outputFile := FileAccess.open(path, FileAccess.WRITE_READ)
	outputFile.store_string("func {0}():\n".format([register_function]))
	outputFile.store_string( get_dialogue_register_script() )
	outputFile.store_string("\n")
	outputFile.store_string( get_charClass_register_script() )

func get_dialogue_register_script() -> String:
	var output: String
	var dir := DirAccess.open(dialogue_folder)
	
	#Dialogue files
	for fileName: String in dir.get_files():
		var res: Resource = load(dir.get_current_dir()+"/"+fileName)
		if res is DialogueResource:
			output += get_call_script(res.dialogue_identifier, dir.get_current_dir() + fileName, dialogue_individual_register_function)
			
	output.indent("\t")
	return output
	
func get_charClass_register_script() -> String:
	var output: String
	var dir := DirAccess.open(charClass_folder)
	
	#Dialogue files
	for fileName: String in dir.get_files():
		var res: Resource = load(dir.get_current_dir()+"/"+fileName)
		if res is CharacterClassResource:
			output += get_call_script(res.class_registered, dir.get_current_dir() + fileName, charClass_individual_register_function)
			
	output.indent("\t")
	return output
	
func get_call_script(objClass: String, objPath: String, individualRegisterFunction: String) -> String:
	return "\t" + "J.{0}(\"{1}\", \"{2}\")\n".format([individualRegisterFunction, objClass, objPath])
