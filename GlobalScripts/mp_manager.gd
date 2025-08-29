extends Node

var Players:Dictionary = {}

func print_players():
	for id in Players:
		print(str(id) + " with name " + Players[id].name)

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

# Function to encode an IP and port into a code
func make_code(ip: String, port: int) -> String:
	var ip_port = "%s:%d" % [ip, port]  # Combine IP and port as a string
	var byte_array = ip_port.to_utf8_buffer()  # Convert to byte array
	var encoded = Marshalls.raw_to_base64(byte_array)  # Base64 encode
	return encoded

# Function to decode a code back into an IP and port
func use_code(code: String):
	var decoded_bytes = Marshalls.base64_to_raw(code)  # Base64 decode
	var decoded_string = decoded_bytes.get_string_from_utf8()
	var parts = decoded_string.split(":")  # Split the string back into IP and port
	
	if parts.size() == 2:
		return {
			"ip": parts[0],
			"port": int(parts[1])
			}
	else:
		return parts

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
