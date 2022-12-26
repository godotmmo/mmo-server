extends Node

var world_state: Dictionary = {}


func _physics_process(_delta: float):
	if not get_parent().player_state_collection.is_empty():
		world_state = get_parent().player_state_collection.duplicate(true)
		for player in world_state.keys():
			world_state[player].erase("T")
		world_state["T"] = int(Time.get_unix_time_from_system() * 1000)
		# Verification
		# Anti-Cheat
		# Cuts (chunking/maps)
		# Physic checks
		get_parent().SendWorldState(world_state)
