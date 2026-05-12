extends Node

signal connected(my_id: int)
signal player_joined(id: int)
signal player_updated(id: int, data: Dictionary)
signal player_left(id: int)

const SERVER_URL := "ws://127.0.0.1:8080"
const RECONNECT_INTERVAL := 3.0

var my_id := -1
var _socket := WebSocketPeer.new()
var _is_open := false
var _reconnect_timer := 0.0

func _ready() -> void:
	_connect()

func _connect() -> void:
	_socket = WebSocketPeer.new()
	_socket.connect_to_url(SERVER_URL)

func _process(delta: float) -> void:
	_socket.poll()
	var state := _socket.get_ready_state()

	match state:
		WebSocketPeer.STATE_OPEN:
			_is_open = true
			_reconnect_timer = 0.0
			while _socket.get_available_packet_count() > 0:
				_handle_packet(_socket.get_packet())

		WebSocketPeer.STATE_CLOSED:
			if _is_open:
				_is_open = false
				my_id = -1
			_reconnect_timer += delta
			if _reconnect_timer >= RECONNECT_INTERVAL:
				_reconnect_timer = 0.0
				_connect()

func _handle_packet(packet: PackedByteArray) -> void:
	var msg = JSON.parse_string(packet.get_string_from_utf8())
	if msg == null or typeof(msg) != TYPE_DICTIONARY:
		return
	match msg.get("type", ""):
		"welcome":
			my_id = int(msg.get("id", -1))
			connected.emit(my_id)
		"join":
			player_joined.emit(int(msg.get("id", -1)))
		"update":
			player_updated.emit(int(msg.get("id", -1)), msg)
		"leave":
			player_left.emit(int(msg.get("id", -1)))

func send_state(unit_type: String, hp: int, pos: Vector2) -> void:
	if _socket.get_ready_state() != WebSocketPeer.STATE_OPEN:
		return
	_socket.send_text(JSON.stringify({
		"unit_type": unit_type,
		"hp": hp,
		"x": pos.x,
		"y": pos.y,
	}))
