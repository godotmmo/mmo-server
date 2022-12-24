extends Node

@onready var main_interface = get_parent()
@onready var player_container_scene = preload("res://Scenes/Instances/PlayerContainer.tscn")

var awaiting_verification = {}

func start(player_id):
	awaiting_verification[player_id] = {"Timestamp": int(Time.get_unix_time_from_system())}
	main_interface.FetchToken(player_id)


func Verify(player_id, token):
	print("Verifying token")
	var token_verification = false
	print("Unix time: " + str(int(Time.get_unix_time_from_system())) + " token time: " + str(int(token.right(10))))
	while int(Time.get_unix_time_from_system()) - int(token.right(10)) <= 30:
		if main_interface.expected_tokens.has(token):
			token_verification = true
			CreatePlayerContainer(player_id)
			print("Container created")
			awaiting_verification.erase(player_id)
			main_interface.expected_tokens.erase(token)
			break
		else:
			await get_tree().create_timer(2).timeout
	main_interface.ReturnTokenVerificationResults(player_id, token_verification)
	if token_verification == false: # this is to make sure people are disconnected
		awaiting_verification.erase(player_id)
		main_interface.network.disconnect_peer(player_id)


func CreatePlayerContainer(player_id):
	var new_player_container = player_container_scene.instantiate()
	new_player_container.name = str(player_id)
	get_parent().add_child(new_player_container, true)
	var player_container = get_node("../" + str(player_id))
	print(player_container)
	FillPlayerContainer(player_container)


func FillPlayerContainer(player_container):
	player_container.player_data = ServerData.test_data.stats


func _on_verification_expiration_timeout() -> void:
	var current_time = Time.get_unix_time_from_system()
	var start_time
	if awaiting_verification == {}:
		pass
	else:
		for key in awaiting_verification.keys():
			start_time = awaiting_verification[key].Timestamp
			if current_time - start_time >= 10:
				awaiting_verification.erase(key)
				var connected_peers = Array(multiplayer.get_peers())
				if connected_peers.has(key):
					main_interface.ReturnTokenVerificationResults(key, false)
					main_interface.network.disconnect_peer(key)
	print("Awaiting Verification")
	print(awaiting_verification)
