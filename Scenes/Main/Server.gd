extends Node

var network = ENetMultiplayerPeer.new()
var port = 24597
var max_players = 100

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
