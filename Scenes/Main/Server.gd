extends Node

var network: ENetMultiplayerPeer = ENetMultiplayerPeer.new()
var port: int = 24597
var max_players: int = 100

var peer_list_exists: bool = false

var expected_tokens: Array = []
var player_state_collection: Dictionary = {}

@onready var player_verification_process: Node = get_node("PlayerVerification")


func _ready():
	StartServer()


func StartServer() -> void:
	network.create_server(port, max_players)
	multiplayer.set_multiplayer_peer(network)
	print("Server started")
	
	network.peer_connected.connect(_Peer_Connected)
	network.peer_disconnected.connect(_Peer_Disconnected)


func _Peer_Connected(player_id: int) -> void:
	print("User " + str(player_id) + " Connected")
	player_verification_process.start(player_id)


func _Peer_Disconnected(player_id: int) -> void:
	print("User " + str(player_id) + " Disconnected")
	if has_node(str(player_id)):
		rpc_id(0, "DespawnPlayer", str(player_id))
		player_state_collection.erase(player_id)
		get_node(str(player_id)).queue_free()


@rpc("any_peer")
func FetchSkillData(skill_name: String, requester: int) -> void:
	var player_id: int = multiplayer.get_remote_sender_id()
	var skill_data: String = ServerData.skill_data[skill_name].value
	rpc_id(player_id, "ReturnSkillData", skill_data, skill_name, requester)
	print("Sending " + str(skill_data) +"," + skill_name + " To Player " + str(player_id)) 


@rpc("any_peer")
func FetchPlayerData() -> void:
	var player_id: int = multiplayer.get_remote_sender_id()
	var player_data: String = get_node(str(player_id)).player_data
	rpc_id(player_id, "ReturnPlayerData", player_data)


@rpc
func ReturnPlayerData(player_data: String, requester: int) -> void:
	instance_from_id(requester).SetAbilityValue(player_data)


func _on_token_expiration_timeout() -> void:
	var current_time: int = int(Time.get_unix_time_from_system())
	var token_time: int
	if expected_tokens == []:
		pass
	else: 	
		for i in range(expected_tokens.size() -1, -1, -1):
			token_time = int(expected_tokens[i].right(10))
			if current_time - token_time >= 30:
				expected_tokens.remove_at(i)


@rpc("call_remote")
func FetchToken(player_id: int) -> void:
	print("Fetching token from player: " + str(player_id))
	while not multiplayer.get_peers().has(player_id):
		await get_tree().create_timer(1).timeout
	rpc_id(player_id, "FetchToken", player_id)


@rpc("any_peer")
func ReturnToken(token: String) -> void:
	var player_id: int = multiplayer.get_remote_sender_id()
	player_verification_process.Verify(player_id, token)


@rpc("call_local")
func ReturnTokenVerificationResults(player_id: int, result: bool) -> void:
	print("Returning Token Verification Result to: " + str(player_id))
	rpc_id(player_id, "ReturnTokenVerificationResults", player_id, result)
	if result == true:
		rpc_id(0, "SpawnNewPlayer", player_id, Vector3(0,10,0))


@rpc("any_peer")
func ReceivePlayerState(player_state: Dictionary) -> void:
	var player_id: int = multiplayer.get_remote_sender_id()
	if player_state_collection.has(player_id): # Check if player is known in the current collection
		if player_state_collection[player_id]["T"] < player_state["T"]: # Check if player_state is the latest
			player_state_collection[player_id] = player_state # Replace player_state in the collection
	else:
		player_state_collection[player_id] = player_state # Add player_state in the collection


@rpc("unreliable")
func SendWorldState(world_state: Dictionary) -> void: # In case of maps or chunks you will want to track player collection and send accordingly
	rpc_id(0, "ReceiveWorldState", world_state)


@rpc("any_peer")
func FetchServerTime(client_time_msecs: int) -> void:
	var player_id: int = multiplayer.get_remote_sender_id()
	print("Returning server time to player: " + str(player_id))
	rpc_id(player_id, "ReturnServerTime", int(Time.get_unix_time_from_system() * 1000), client_time_msecs)


@rpc("any_peer")
func DetermineLatency(client_time_msecs: int) -> void:
	var player_id: int = multiplayer.get_remote_sender_id()
	rpc_id(player_id, "ReturnLatency", client_time_msecs)


###################################################################################################
#							All functions below are used for									  #
#								rpc checksums													  #
###################################################################################################

@rpc("call_local")
func ReturnSkillData(_skill_data, _skill_name, _requester):
	# used for rpc checksum
	pass


@rpc
func SpawnNewPlayer(_player_id, _spawn_position):
	# used for rpc checksum
	pass


@rpc
func DespawnPlayer(_player_id):
	# used for rpc checksum
	pass


@rpc("unreliable")
func SendPlayerState(_player_state):
	# used for rpc checksum
	pass


@rpc("unreliable")
func ReceiveWorldState(_world_state):
	# used for rpc checksum
	pass


@rpc
func ReturnServerTime(_server_time_msecs, _client_time_msecs):
	# used for rpc checksum
	pass


@rpc
func ReturnLatency(_client_time_msecs):
	# used for rpc checksum
	pass
