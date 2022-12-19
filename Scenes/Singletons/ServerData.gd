extends Node

var skill_data

var test_data = {
	"stats": {
		"health": 100,
		"mana": 100,
		"stamina": 100
	}
}

func _ready():
	var skill_data_file = FileAccess.open("res://Data/SkillData/skill-data.json", FileAccess.READ)
	var skill_data_json = JSON.parse_string(skill_data_file.get_as_text())
	skill_data = skill_data_json
