extends Resource

class_name ConfigResource

enum MODE { DEVELOPMENT, DEPLOYMENT }

@export_group("Global Configuration")
@export var mode: MODE = MODE.DEVELOPMENT
@export var use_tls: bool = false

@export_group("Gateway Server Server Configuration")
@export var gateway_server_server_bind_address: String = "*"
@export var gateway_server_server_port: int = 9071
@export var gateway_server_server_fps: int = 30
@export var gateway_server_certh_path: String = ""
@export var gateway_server_key_path: String = ""

@export_group("Gateway Client Server Configuration")
@export var gateway_client_server_bind_address: String = "*"
@export var gateway_client_server_port: int = 9072
@export var gateway_client_server_fps: int = 30
@export var gateway_client_certh_path: String = ""
@export var gateway_client_key_path: String = ""

@export_group("Server Client Server Configuration")
@export var server_client_server_bind_address: String = "*"
@export var server_client_server_port: int = 9073
@export var server_client_server_fps: int = 10
@export var server_client_certh_path: String = ""
@export var server_client_key_path: String = ""

@export_group("Client Gateway Configuration")
@export var server_gateway_client_address: String = "ws://localhost:9071"
@export var server_gateway_client_fps: int = 30

@export_group("Client Gateway Configuration")
@export var client_gateway_client_address: String = "ws://localhost:9072"
@export var client_gateway_client_fps: int = 30

@export_group("Client Server Configuration")
@export var client_server_client_address: String = "ws://localhost:9073"
@export var client_server_client_fps: int = 30
