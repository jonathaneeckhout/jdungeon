# Skill system

## Overview:
This system uses SkillComponentResource to define new skills that a player can use. Which are then handled by the SkillComponent node.  
Each `SkillComponent` can hold an arbitrary amount of skills. Despite holding a direct reference to said skills, this system relies mostly on the `SkillComponentResource.skill_class` (of `String` type) property to identify skills over the network.   

## Networking side:  
If a skill has been selected and the action button is pressed, `PlayerSynchronizer._handle_right_click()` sends the class of the chosen skill to the server, as well as a global position of where it was used. The server, after running checks like distance to target or if the player even owns said skill. It then uses the `SkillComponentResource.skill_class` received to load the correct skill resource and runs `SkillComponentResource.effect()` in the desired location.  

## `SkillComponent.UseInfo`  
This object is used to carry information about how the skill was used and is created by `SkillComponent` before being passed onto the selected skill, `SkillComponentResource` has NO reason to modify this object as doing so won't have any effect.   
It contains some methods to retrieve information like the `StatsSynchronizerComponent` of all targets about to be affected by the skill.  
Check the `SkillComponent` script to see all of the information it holds.

## Creating your own skills:
Unless the skill's only purpose is to deal damage or heal (by modifying it's "damage" property to be positive or negative). You will need a new script.  
The script can be added by first creating a regular SkillComponentResource resource file. Then in the inspector, navigating to the bottom to the "script" property, where you can add a new one. You may load an existing .gd file or create it right in the field as an internal Script resource. The script must extend `SkillComponentResource`.  
  
From there, the script must override the `_effect(usageInformation: SkillComponent.UseInfo)` function to implement your own functionality. As an example, here is the script for the "HealSelf" spell which heals the user by 20 HP.

```
extends SkillComponentResource

func _effect(info: SkillComponent.UseInfo):
	info.get_user_stats().heal(info.user.get_name(), 20)```


