extends Node

var network: ENetMultiplayerPeer = ENetMultiplayerPeer.new()
var port = 24597
var max_players = 100

var peer_list_exists = false

var expected_tokens = ["ab59723152488aa349627e22d72c9459c7b27245a4e0fe90fle2993d06dd7ea31702936807",
						"ab59723152488aa349627e22d72c9459c7b27245a4e0fe90fie2993d06dd7ea31702936807",
						"ab59723152488aa349627e22d72c9459c7b27245a4e0fe90fle2993d06dd7ea31602936807"]

@onready var player_verification_process = get_node("PlayerVerification")


func _ready():
	StartServer()


func StartServer():
	network.create_server(port, max_players)
	multiplayer.set_multiplayer_peer(network)
	print("Server started")
	
	network.peer_connected.connect(_Peer_Connected)
	network.peer_disconnected.connect(_Peer_Disconnected)


func _Peer_Connected(player_id):
	print("User " + str(player_id) + " Connected")
	player_verification_process.start(player_id)


func _Peer_Disconnected(player_id):
	print("User " + str(player_id) + " Disconnected")
	get_node(str(player_id)).queue_free()


@rpc(any_peer)
func FetchSkillData(skill_name, requester):
	var player_id = multiplayer.get_remote_sender_id()
	var skill_data = ServerData.skill_data[skill_name].value
	rpc_id(player_id, "ReturnSkillData", skill_data, skill_name, requester)
	print("Sending " + str(skill_data) +"," + skill_name + " To Player " + str(player_id)) 


@rpc
func ReturnSkillData(skill_data, skill_name, requester):
	instance_from_id(requester).SetAbilityValue(skill_data, skill_name)


@rpc(any_peer)
func FetchPlayerData():
	var player_id = multiplayer.get_remote_sender_id()
	var player_data = get_node(str(player_id)).player_data
	rpc_id(player_id, "ReturnPlayerData", player_data)


@rpc
func ReturnPlayerData(player_data, requester):
	instance_from_id(requester).SetAbilityValue(player_data)


func _on_token_expiration_timeout():
	var current_time = Time.get_unix_time_from_system()
	var token_time
	if expected_tokens == []:
		pass
	else: 	
		for i in range(expected_tokens.size() -1, -1, -1):
			token_time = int(expected_tokens[i].right(10))
			if current_time - token_time >= 30:
				expected_tokens.remove_at(i)


@rpc(call_remote)
func FetchToken(player_id):
	print("Fetching token from player: " + str(player_id))
	while multiplayer.get_peers().is_empty():
		await get_tree().create_timer(1).timeout
	rpc_id(player_id, "FetchToken")


@rpc(call_remote)
func ReturnToken(token):
	var player_id = multiplayer.get_remote_sender_id()
	player_verification_process.Verify(player_id, token)


@rpc(call_local)
func ReturnTokenVerificationResults(player_id, result):
	rpc(player_id, "ReturnTokenVerificationResults", result)


