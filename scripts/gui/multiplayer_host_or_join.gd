extends Control

func _ready() -> void:
	self.show()
	Steam.lobby_created.connect(_on_lobby_created)
	Steam.lobby_joined.connect(_on_lobby_joined)
	
func _process(_delta):
	pass
	
func _on_host_pressed() -> void:
	if SteamManager.is_steam_running:
		# Create a lobby (Type 2 = Friends Only)
		Steam.createLobby(Steam.LOBBY_TYPE_FRIENDS_ONLY, 4)
		print("Lobby request sent to Steam...")
	#Global.game_controller.change_gui_scene("res://scenes/menus/select_character.tscn")
	
func _on_join_pressed() -> void:
	# Assuming your LineEdit is named 'JoinInput'
	var input_id = $VBoxContainer/JoinInput.text 
	
	if input_id.is_valid_int():
		var lobby_id = int(input_id)
		print("Attempting to join lobby: ", lobby_id)
		Steam.joinLobby(lobby_id)
	else:
		print("Invalid Lobby ID format!")

func _on_settings_pressed() -> void:
	pass # Replace with function body.

func _on_quit_pressed() -> void:
	Global.is_multiplayer = false
	Global.game_controller.change_gui_scene("res://scenes/menus/main_menu.tscn")
	
func _on_lobby_created(connect_result: int, lobby_id: int) -> void:
	if connect_result == 1: # For Lobby signals, 1 usually means success
		print("Lobby Created! ID: ", lobby_id)
		
		# 1. Store your world seed in the lobby
		var my_seed = "0" # Use your actual seed variable here
		Steam.setLobbyData(lobby_id, "seed", str(my_seed))
		SteamManager.current_lobby_id = lobby_id
		# 2. Set up the networking peer
		var peer = SteamMultiplayerPeer.new()
		peer.create_host(0)
		multiplayer.multiplayer_peer = peer
		
		# 3. Load your game world
		print("Hosting started with seed: ", my_seed)
		Global.is_multiplayer = true
		Global.game_controller.change_gui_scene("res://scenes/menus/select_character.tscn")

func _on_lobby_joined(lobby_id: int, _permissions: int, _locked: bool, response: int) -> void:
	if Steam.getLobbyOwner(lobby_id) == Steam.getSteamID():
		print("Lobby owner joined their own lobby. Skipping client setup.")
		return
	if response == 1: # 1 = Success
		print("Successfully joined lobby: ", lobby_id)
		
		# 1. Sync the world seed from the host
		var joined_seed = Steam.getLobbyData(lobby_id, "seed")
		if joined_seed != "":
			Global.world_data.seed = joined_seed.to_int()
			print("World seed synced: ", Global.world_data.seed)
		
		# 2. Setup the networking as a client
		var peer = SteamMultiplayerPeer.new()
		# Use the lobby owner's Steam ID to connect
		var host_id = Steam.getLobbyOwner(lobby_id)
		peer.create_client(host_id, 0)
		multiplayer.multiplayer_peer = peer
		
		# 3. Transition to the next scene
		Global.is_multiplayer = true
		Global.game_controller.change_gui_scene("res://scenes/game/game.tscn")
	else:
		print("Failed to join lobby. Error code: ", response)
