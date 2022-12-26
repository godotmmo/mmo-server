extends Node

var gateway_client = ENetMultiplayerPeer.new()
var gateway: MultiplayerAPI = MultiplayerAPI.create_default_interface()
var ip: String = "safe-asbestos.at.ply.gg"
var port: int = 52839

@onready var gameserver: Node = get_node("/root/Server")

func _ready() -> void:
	ConnectToServer()
	
func _process(_delta: float) -> void:
	if !gateway.has_multiplayer_peer():
		return
	else:
		gateway.poll()
		
	
	
func ConnectToServer() -> void:
	gateway_client.create_client(ip, port)
	
	# This creates a new multiplayer api instance on the current path and allows
	# for a secondary connection
	get_tree().set_multiplayer(gateway, get_path())
	gateway.set_multiplayer_peer(gateway_client)
	
	gateway_client.peer_disconnected.connect(_OnConnectionDisconnected)
	
	gateway.connection_failed.connect(_OnConnectionFailed)
	gateway.connected_to_server.connect(_OnConnectionSucceeded)
	
	
func _OnConnectionFailed(server_id: int) -> void:
	print(str(server_id) + "Failed to connect to Game Server Hub")
	
func _OnConnectionDisconnected(server_id: int) -> void:
	print(str(server_id) + "Disconnected")
	
	
func _OnConnectionSucceeded() -> void:
	print("Succesfully connected to Game Server Hub")
	

@rpc(any_peer)
func ReceiveLoginToken(token: String) -> void:
	gameserver.expected_tokens.append(token)
