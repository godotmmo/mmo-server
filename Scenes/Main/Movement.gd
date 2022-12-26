extends Node


func FetchSkillDamage(skill_name: String) -> String:
	var value = ServerData.skill_data[skill_name].value
	return value
