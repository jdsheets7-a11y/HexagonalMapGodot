extends Control

const PORT := 9999

var peer := ENetMultiplayerPeer.new()


func _ready() -> void:
	multiplayer.peer_connected.connect(_player_connected)
	multiplayer.connected_to_server.connect(_connected_to_server)
	multiplayer.connection_failed.connect(_connection_failed)



func _on_host_button_pressed() -> void:
	var error = peer.create_server(PORT)
	
	if error != OK:
		print("Could not host.")
		return
	
	multiplayer.multiplayer_peer = peer
	$VBoxContainer/StatusLabel.text = "Hosting..."



func _on_join_button_pressed() -> void:
	var ip = $VBoxContainer/HBoxContainer/IPAddress.text
	
	var error = peer.create_client(ip, PORT)
	
	if error != OK:
		print("Could not connect.")
		return
	
	multiplayer.multiplayer_peer = peer
	
	$VBoxContainer/StatusLabel.text = "Connecting..."


func _player_connected(id):
	print("Player connected: ", id)
	if multiplayer.is_server():
		GameManager.start_game.rpc()

func _connected_to_server():
	print("Connected!")
	$VBoxContainer/StatusLabel.text = "Connected!"


func _connection_failed():
	print("Connection failed")
	$VBoxContainer/StatusLabel.text = "Connection failed"
