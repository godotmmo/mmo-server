extends Node


func FetchSkillDamage(skill_name):
	var value = ServerData.skill_data[skill_name].value
	return value
