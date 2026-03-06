extends Node

var is_steam_running: bool = false
var current_lobby_id: int = 0  # <--- Add this

func _init() -> void:
	# Set the App ID before initializing
	OS.set_environment("SteamAppId", str(480))
	OS.set_environment("SteamGameId", str(480))

func _ready() -> void:
	_initialize_steam()

func _initialize_steam() -> void:
	var response: Dictionary = Steam.steamInitEx()
	print("Steam Init Response: ", response)
	
	if response["status"] == 0:
		is_steam_running = true
		print("Steam is active. Hello, ", Steam.getPersonaName())
	else:
		print("Steam failed to initialize: ", response["verbal"])

func _process(_delta: float) -> void:
	# Important! Steam needs to run callbacks every frame to process signals
	Steam.run_callbacks()
