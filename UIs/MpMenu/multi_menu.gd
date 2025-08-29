extends Control

#---------------------------------------------#
#             Global variables                #
#---------------------------------------------#
#------------------------------------------------------------------------------#

var Address = "127.0.0.1"
var port = 8910
var peer
var code
var connected_successfully = false

# panels
var pnl_start
var pnl_players
var pnl_game
var pnl_join
var pnl_info

# Players labels
var host_player
var peer_player

# Message label
var message_label

#---------------------------------------------#
#                  Signals                    #
#---------------------------------------------#
#------------------------------------------------------------------------------#


signal return_to_main
signal obtained_ip(success)
signal host_starts

#---------------------------------------------#
#               Ready method                  #
#---------------------------------------------#
#------------------------------------------------------------------------------#



# Called when the node enters the scene tree for the first time.
func _ready():
	# Setting panels to variables for easy access
	pnl_start = $vbox/start_panel
	pnl_players = $vbox/mid_hbox/players_panel
	pnl_game = $vbox/under_hbox/game_panel
	pnl_join = $vbox/under_hbox/join_panel
	pnl_info = $vbox/under_hbox/game_panel_clients
	
	# Setting player labels for easy access
	host_player = $vbox/mid_hbox/players_panel/players_margin/players_vbox/host_lbl_hbox/host_player
	peer_player = $vbox/mid_hbox/players_panel/players_margin/players_vbox/peer_lbl_hbox/peer_player
	message_label = $vbox/message_label
	
	print("Componenet aliases set...")
	
	# Hiding panels not needed at the start
	pnl_players.visible = false
	$vbox/under_hbox.visible = false
	$vbox/mid_hbox.visible = false
	pnl_game.visible = false
	pnl_join.visible = false
	pnl_info.visible = false
	message_label.visible = false
	$vbox/disconnect_button.visible = false
	$vbox/abort_button.visible = false
	$vbox/back_button2.visible = false
	
	print("Hidden panels...")
	
	# setting up multiplayer connections
	multiplayer.peer_connected.connect(on_peer_connected)
	multiplayer.peer_disconnected.connect(on_peer_disconnected)
	multiplayer.connected_to_server.connect(on_server_connect)
	multiplayer.connection_failed.connect(on_connection_failed)
	multiplayer.server_disconnected.connect(on_server_disconnect)
	print("Multiplayer signals connected...")
	print("Ready")
	print()


#---------------------------------------------#
#               Multiplay Menu                #
#---------------------------------------------#
#------------------------------------------------------------------------------#


# A player chooses to return to the main menu
func _on_back_button_pressed():
	return_to_main.emit()


#---------------------------------------------#
#               Hosting: Basis                #
#---------------------------------------------#
#------------------------------------------------------------------------------#


# Host sets up the game
func _on_host_pressed():
	# Fetch public IP using an external API
	var http_request = HTTPRequest.new()
	add_child(http_request)
	http_request.request_completed.connect(_on_request_completed)
	var url = "https://api.ipify.org"  # Public IP API
	http_request.request(url)
	print("Waiting to receive IP...")
		
	var success = await obtained_ip
	if not success:
		show_message("Could not find device ip")
		return
		
	# If this point has been reached, the online IP has been
	# Successfully retreived.
	
	# Setting up a multiplayer connection
	peer = ENetMultiplayerPeer.new()
	# Creating a server, and checking for success.
	# The 2 is the maximum number of players, including host.
	var error = peer.create_server(port, 2)
	if error != OK:
		show_message("CANNOT HOST: " + str(error))
		return

	# We have successfully established hosting.
	show_message("HOSTING GAME. PRESS START WHEN ALL PLAYERS ARE READY")
		
	# Compressions
	#	multiple enums, can go check what they mean
	#	Helps with bandwiddth usage
	peer.get_host().compress(ENetConnection.COMPRESS_RANGE_CODER)
	# Setting up multiplayer peer
	#	Created an object saying "hey im hosting this thing"
	#	Now telling godot we want to use that peer value as our host
	#	Now saying we want to use that host as our own peer, to play our own game
	multiplayer.set_multiplayer_peer(peer)
	# Setting their own info in the dict
	# note that this is done without rpc
	# get_unique_id should return 1 for the host.
	send_player_info(multiplayer.get_unique_id(), GlbUser.username)
	
	# Getting code to join game
	code = MpManager.make_code(Address, port)
	$vbox/under_hbox/game_panel/game_margin/game_vbox/code_hbox/Code_label.text = code
	# Managing Panels
	$vbox/under_hbox.visible = true
	$vbox/mid_hbox.visible = true
	pnl_join.visible = false
	pnl_start.visible = false
	pnl_game.visible = true
	pnl_players.visible = true
	$vbox/abort_button.visible = true
	$vbox/back_button.visible = false
	
	# Notifying the host that we are now just waiting for players.
	peer_player.text = "WAITING FOR PLAYERS..."
	
	update_game_info(
			$vbox/under_hbox/game_panel/game_margin/game_vbox/dims_hbox/dims_spin.value,
			$vbox/under_hbox/game_panel/game_margin/game_vbox/radius_hbox/radius_spin.value,
			$vbox/under_hbox/game_panel/game_margin/game_vbox/axes_hbox/axes_spin.selected
			)

# Once the player's IP Address has been found, set it
func _on_request_completed(result, response_code, headers, body):
	if response_code == 200:
		var Address = body.get_string_from_utf8()
		print("Your Public IP Address is: ", Address)
		emit_signal("obtained_ip", true)
	else:
		print("Failed to fetch public IP. Response code: ", response_code)
		emit_signal("obtained_ip", false)


# When the host starts the game
func _on_start_button_pressed():
	host_starts.emit()


# A host chooses to abandon the game.
func _on_abort_button_pressed():
	multiplayer.multiplayer_peer.close()  # Disconnect all clients
	multiplayer.multiplayer_peer = null  # Reset the peer
	$vbox/abort_button.visible = false
	$vbox/back_button.visible = true
	$vbox/under_hbox.visible = false
	$vbox/mid_hbox.visible = false
	$vbox/start_panel.visible = true
	show_message("NO LONGER HOSTING")


# Confirms that the host has received and shared player information.
# Only the new player will receive this call
# The new player will then notify all others that they have in fact joined the game.
@rpc("any_peer")
func confirm_host_shared():
	show_message("JOINED " + MpManager.Players[1].name + "'S GAME")
	notify_joined.rpc(multiplayer.get_unique_id())


# When the host disconnects, this is run on clients
func on_server_disconnect():
	show_message("HOST DISCONNECTED")
	MpManager.Players = {}
	$vbox/mid_hbox.visible = false
	$vbox/disconnect_button.visible = false
	$vbox/back_button.visible = true
	$vbox/start_panel.visible = true
	$vbox/mid_hbox.visible = false


#---------------------------------------------#
#               Joining: Basis                #
#---------------------------------------------#
#------------------------------------------------------------------------------#


# A player goes to the "join game" screen
func _on_start_join_pressed():
	$vbox/under_hbox.visible = true
	pnl_game.visible = false
	pnl_start.visible = false
	pnl_join.visible = true
	pnl_info.visible = false
	$vbox/back_button2.visible = true
	$vbox/back_button.visible = false


# Returns players from the "join game" menu to the "host or join"
func _on_back_button_2_pressed():
	$vbox/under_hbox.visible = false
	$vbox/mid_hbox.visible = false
	$vbox/back_button2.visible = false
	$vbox/back_button.visible = true
	$vbox/start_panel.visible = true


# Player attempts joins game with a code
func _on_join_button_pressed():
	# Getting the Address and port
	code = $vbox/under_hbox/join_panel/join_margin/join_vbox/entercode_hbox/entercode_edit.text
	var dict = MpManager.use_code(code)
	
	# Checking for success
	if !dict.has("ip"):
		show_message("INVALID CODE")
		return
	
	# Otherwise, get address and port
	Address = dict["ip"]
	port = dict["port"]
	
	# Setting up a multiplayer connection
	show_message("FINDING SERVER...")
	
	peer = ENetMultiplayerPeer.new()
	# Creating a client and connecting to the addess and port
	var error = peer.create_client(Address, port)
	if error != Error.OK:
		message_label.text = "CANNOT JOIN: " + str(error)
		return
		
	# Set peer
	multiplayer.set_multiplayer_peer(peer)
	
	# Compressions
	peer.get_host().compress(ENetConnection.COMPRESS_RANGE_CODER)
	
	# Wait to see if the connection is successful
	var timer = Timer.new()
	timer.wait_time = 7
	timer.one_shot = true
	add_child(timer)
	timer.start()
	# Wait for the timeout signal
	await timer.timeout
	if not connected_successfully:
		show_message("SERVER OFFLINE")
		multiplayer.multiplayer_peer.close()  # Close the connection
		multiplayer.multiplayer_peer = null  # Reset the peer
	connected_successfully = false
	# Clean up the timer
	timer.queue_free()


# Client successfully connects
# Here, i send the player information to the host,
# Who then shares it with other players
func on_server_connect():
	connected_successfully = true
	# Add your info to everyone's dict.
	var my_id = multiplayer.get_unique_id()
	# by using rpc_id(1) we make it so only the host actually runs this function.
	send_player_info.rpc_id(1, my_id, GlbUser.username)
	print("THE CONNECTION SUCCEEDED")
	
	$vbox/mid_hbox.visible = true
	pnl_join.visible = false
	pnl_players.visible = true
	pnl_info.visible = true
	$vbox/disconnect_button.visible = true
	$vbox/back_button.visible = false
	$vbox/back_button2.visible = false


# Updates all other players' labels to show that this player has joined the game.
@rpc("any_peer", "call_remote")
func notify_joined(id):
	show_message(MpManager.Players[id].name + " HAS JOINED THE GAME")


# Sends your player information (as a client) to the host.
# The host then shares your information with other clients.
# Host then tells client that their information has successfully been shared.
@rpc("any_peer")
	# any_peer: all connected people call
	# authority: only when host calls will it actually go out
	# call_local: when I call the function, it runs for me too
	# call_remote: when I call the function, it only calls for me
	# without rpc, it of course only calls for you
func send_player_info(id, name):
	# This information gets added to the runner's dictionary
	# if called from on_server_connect, thats only the host.
	if !MpManager.Players.has(id):
		MpManager.Players[id] = {
			"name":name
		}
		print("Added " + name + " with id " + str(id) + " to game")
	# Server is gonna send everything to everyone else to confirm that
	# they are up to date.
	if multiplayer.is_server():
		for i in MpManager.Players:
			send_player_info.rpc(i, MpManager.Players[i].name)
			
		confirm_host_shared.rpc_id(id)
	
	# update the new player's game info
	host_updates_info(id)
	# Update the players panel
	update_player_panel.rpc()


# A player chooses to leave the game.
func _on_disconnect_button_pressed():
	multiplayer.multiplayer_peer.close()  # Close the connection
	multiplayer.multiplayer_peer = null  # Reset the peer
	show_message("YOU DISCONNECTED")
	$vbox/mid_hbox.visible = false
	$vbox/under_hbox.visible = false
	$vbox/disconnect_button.visible = false
	$vbox/back_button.visible = true
	$vbox/start_panel.visible = true
	
	pnl_info.visible = false


# When connection fails
func on_connection_failed():
	print("THE CONNECTION FAILED")
	show_message("COULD NOT CONNECT")


# Called on server AND clients when somebody connects
func on_peer_connected(id):
	print("Player connected " + str(id))


# Called on server AND clients when somebody disconnects
func on_peer_disconnected(id):
	print("Player disconnected " + str(id))
	show_message(MpManager.Players[id].name + " DISCONNECTED")
	MpManager.Players.erase(id)
	update_player_panel.rpc()


#---------------------------------------------#
#                  Helpers                    #
#---------------------------------------------#
#------------------------------------------------------------------------------#

# Copies the game code to clipboard
func _on_copy_code_pressed():
	DisplayServer.clipboard_set(code)
	show_message("CODE COPIED")


# Pastes code into the box and attempts to join
func _on_paste_code_pressed():
	$vbox/under_hbox/join_panel/join_margin/join_vbox/entercode_hbox/entercode_edit.text = DisplayServer.clipboard_get()
	_on_join_button_pressed()


# show a message on the message label
func show_message(message):
	message_label.visible = true
	message_label.text = message


# Updates the player panel with current player information.
@rpc("any_peer", "call_local")
func update_player_panel():
	peer_player.text = "WAITING FOR PLAYERS..."
	for id in MpManager.Players:
		if id == 1:
			host_player.text = MpManager.Players[id].name
		else:
			peer_player.text = MpManager.Players[id].name


# info panel just gives what's changed
# but to be honest, 
func host_changed_ui(info):
	host_updates_info()
	

# Called when a host starts a game, changes game info, or a new player joins.
# if a new player joins, only that new player needs to be updated,
# and so his id is given as a parameter 
func host_updates_info(id=null):
	if id == null:
		update_game_info.rpc(
			$vbox/under_hbox/game_panel/game_margin/game_vbox/dims_hbox/dims_spin.value,
			$vbox/under_hbox/game_panel/game_margin/game_vbox/radius_hbox/radius_spin.value,
			$vbox/under_hbox/game_panel/game_margin/game_vbox/axes_hbox/axes_spin.selected
			)
		update_game_panel.rpc()
	else:
		update_game_info.rpc_id(
			id,
			$vbox/under_hbox/game_panel/game_margin/game_vbox/dims_hbox/dims_spin.value,
			$vbox/under_hbox/game_panel/game_margin/game_vbox/radius_hbox/radius_spin.value,
			$vbox/under_hbox/game_panel/game_margin/game_vbox/axes_hbox/axes_spin.selected
			)
		update_game_panel.rpc_id(id)


@rpc("any_peer", "call_local")
func update_game_info(maze_rad, game_rad, host_axis):
	var my_axis
	if multiplayer.get_unique_id() == 1:
		my_axis = host_axis
	else:
		# this swaps 1 to 0 and 0 to 1
		my_axis = (-1*host_axis)+1
	# Update information in the global user script
	GlbUser.update_game_information(maze_rad, game_rad, my_axis)


# When the host updates 
@rpc("any_peer", "call_remote")
func update_game_panel():
	$vbox/under_hbox/game_panel_clients/game_margin/game_vbox/dims_hbox/dims_label.text = str(GlbUser.maze_rad)
	$vbox/under_hbox/game_panel_clients/game_margin/game_vbox/radius_hbox/radius_label.text = str(GlbUser.game_rad)
	$vbox/under_hbox/game_panel_clients/game_margin/game_vbox/axes_hbox/axes_label.text = C.AXES_STRINGS[GlbUser.axis]
