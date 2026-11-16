class_name Train
extends Node
## The steam train (design/game-brief.md, Features item 2; story 002): a locomotive
## and [code]train_cars[/code] carriages run along the track row in the +i direction,
## slow into the station, stop with the loco's front at [code]train_stop_i[/code],
## wait, pull out and leave the screen, then return [code]train_interval[/code]
## seconds later. The first train arrives [code]train_first[/code] seconds after start.
##
## Each piece is one sprite in the village's y-sorted World (through
## [method VillageScene.add_entity]), so it depth-sorts against villagers and
## buildings. Smoke puffs ([SmokePuff]) rise from the chimney. All logic runs on the
## physics step, so [code]Engine.time_scale[/code] speeds it up.
##
## Tuning keys in [code]assets/data/village_tuning.json[/code] (distances in tiles,
## times in seconds, speeds in tiles per second):
## [codeblock]
## train_first, train_interval, train_dwell  first arrival, gap between trains, wait at the station
## train_speed, train_cars                   full speed, carriages behind the loco
## train_stop_i                              tile i where the loco's front stops
## train_enter_i, train_exit_i               loco front where a train appears / is removed
## train_gap                                 space between pieces
## train_units_per_tile                      sprite len_units per tile
## train_brake_tiles, train_min_speed        braking starts this far from the stop; slowest crawl
## train_depart_speed, train_accel           speed when it pulls out; acceleration (tiles/s^2)
## train_wheel_frames_per_tile               wheel frame swaps per tile travelled
## train_platform_min_i                      platform tiles with a smaller i are not reported
## smoke_interval_moving, smoke_interval_stopped, smoke_moving_above
##                                           puff gap while moving / stopped; speed that counts as moving
## smoke_chimney_back, smoke_chimney_height  new puff's centre: tiles behind the loco front, px above
##                                           the track (just above the stack mouth in loco.png)
## smoke_jitter                              random +- px on a new puff's x
## whistle_volume, whistle_attack, whistle_end_gain, whistle_tones
##                                           see _build_whistle
## [/codeblock]
##
## Command-line user args (after [code]--[/code]) for repeatable screenshots:
## [codeblock]
## godot --path . -- --train-at=stopped   # start stopped at the station (dwell timer running)
## godot --path . -- --train-at=moving    # start braking into the station, front train_brake_tiles from the stop
## [/codeblock]

## Emitted when the train stops at the station. [param platform_tiles] are the
## layout's platform tiles with i >= [code]train_platform_min_i[/code].
signal arrived(platform_tiles: Array[Vector2i])
## Emitted when the train starts to pull out of the station.
signal departing()

enum State { WAITING, ARRIVING, STOPPED, LEAVING }

const TUNING_KEYS: Array[String] = [
	"train_first", "train_interval", "train_dwell", "train_speed", "train_cars", "train_stop_i",
	"train_enter_i", "train_exit_i", "train_gap", "train_units_per_tile", "train_brake_tiles",
	"train_min_speed", "train_depart_speed", "train_accel", "train_wheel_frames_per_tile",
	"train_platform_min_i", "smoke_interval_moving", "smoke_interval_stopped",
	"smoke_moving_above", "smoke_chimney_back", "smoke_chimney_height", "smoke_jitter",
	"smoke_drift_x", "smoke_drift_y", "smoke_life", "smoke_frame_seconds", "smoke_alpha",
	"smoke_fade_seconds", "whistle_volume", "whistle_attack", "whistle_end_gain", "whistle_tones",
]
const LAYOUT_KEYS: Array[String] = ["track_row", "map", "tile_legend", "sprites"]
const LOCO_SPRITE: String = "loco"
const CAR_SPRITE: String = "car"
const SMOKE_SPRITE: String = "smoke"
const TILE_PLATFORM: String = "platform"
## Sprite sheet layout of loco and car: frames 0/1 are the day wheel phases, 2/3 the night ones.
const WHEEL_PHASES: int = 2
const NIGHT_FRAME_OFFSET: int = 2
const ARG_TRAIN_AT: String = "--train-at="
const WHISTLE_MIX_RATE: int = 22050

## The village the train runs through. Set in the scene; the train sets itself up
## once the village is ready.
@export var village: VillageScene
## True to show the night wheel frames (set by the day and night cycle, story 006).
var night: bool = false

var _tuning: Dictionary = {}
var _state: State = State.WAITING
var _timer: float = 0.0
var _front: float = 0.0
var _speed: float = 0.0
var _distance: float = 0.0
var _puff_timer: float = 0.0
var _track_j: float = 0.0
var _platform_tiles: Array[Vector2i] = []
var _pieces: Array[Sprite2D] = []
## Middle of each piece's footprint, in tiles relative to the loco's front.
var _piece_mids: Array[float] = []

@onready var _whistle: AudioStreamPlayer = $Whistle


func _ready() -> void:
	set_physics_process(false)
	village.ready.connect(_setup, CONNECT_ONE_SHOT)


func _physics_process(delta: float) -> void:
	var before: float = _front
	match _state:
		State.WAITING:
			_timer -= delta
			if _timer <= 0.0:
				_enter(State.ARRIVING)
		State.ARRIVING:
			var left: float = _t("train_stop_i") - _front
			_speed = _t("train_speed")
			if left < _t("train_brake_tiles"):
				_speed = maxf(_t("train_min_speed"), _speed * left / _t("train_brake_tiles"))
			_front = minf(_front + _speed * delta, _t("train_stop_i"))
			if _front >= _t("train_stop_i"):
				_enter(State.STOPPED)
		State.STOPPED:
			_timer -= delta
			if _timer <= 0.0:
				_enter(State.LEAVING)
		State.LEAVING:
			_speed = minf(_t("train_speed"), _speed + _t("train_accel") * delta)
			_front += _speed * delta
			if _front > _t("train_exit_i"):
				_enter(State.WAITING)
	if _state == State.WAITING:
		return
	_distance += absf(_front - before)
	_place_pieces()
	_puff_timer -= delta
	if _puff_timer <= 0.0:
		var moving: bool = _speed > _t("smoke_moving_above")
		_puff_timer = _t("smoke_interval_moving") if moving else _t("smoke_interval_stopped")
		_spawn_puff()


func _setup() -> void:
	var layout: Dictionary = _load_json(VillageScene.LAYOUT_PATH, LAYOUT_KEYS)
	_tuning = _load_json(VillageScene.TUNING_PATH, TUNING_KEYS)
	if layout.is_empty() or _tuning.is_empty():
		get_tree().quit(1)
		return
	_track_j = float(layout["track_row"])
	_find_platform_tiles(layout)
	var sprites: Dictionary = layout["sprites"]
	var units: float = _t("train_units_per_tile")
	var loco_len: float = float(sprites[LOCO_SPRITE]["len_units"]) / units
	var car_len: float = float(sprites[CAR_SPRITE]["len_units"]) / units
	var back: float = -loco_len
	_add_piece(LOCO_SPRITE, back, loco_len)
	for k: int in int(_tuning["train_cars"]):
		back -= _t("train_gap") + car_len
		_add_piece(CAR_SPRITE, back, car_len)
	_whistle.stream = _build_whistle()
	_state = State.WAITING
	_timer = _t("train_first")
	for arg: String in OS.get_cmdline_user_args():
		if not arg.begins_with(ARG_TRAIN_AT):
			continue
		match arg.trim_prefix(ARG_TRAIN_AT):
			"stopped":
				_enter(State.STOPPED)
			"moving":
				_enter(State.ARRIVING)
				_front = _t("train_stop_i") - _t("train_brake_tiles")
			_:
				push_error("Train: expected --train-at=stopped or --train-at=moving, got '%s'" % arg)
	if _state != State.WAITING:
		_place_pieces()
	set_physics_process(true)


func _enter(state: State) -> void:
	_state = state
	match state:
		State.WAITING:
			_timer = _t("train_interval")
			_speed = 0.0
			for piece: Sprite2D in _pieces:
				piece.visible = false
		State.ARRIVING:
			_front = _t("train_enter_i")
			_speed = _t("train_speed")
			_puff_timer = 0.0
			for piece: Sprite2D in _pieces:
				piece.visible = true
			_whistle.play()
		State.STOPPED:
			_front = _t("train_stop_i")
			_speed = 0.0
			_timer = _t("train_dwell")
			for piece: Sprite2D in _pieces:
				piece.visible = true
			_whistle.play()
			arrived.emit(_platform_tiles.duplicate())
		State.LEAVING:
			_speed = _t("train_depart_speed")
			_whistle.play()
			departing.emit()


func _add_piece(sprite_name: String, back: float, length: float) -> void:
	var sprite: Sprite2D = village.create_sprite(sprite_name, 0)
	# The sprite's anchor is the back of its footprint; move the node origin to the
	# footprint's middle so y-sorting compares the middle of the piece, not its tail.
	sprite.offset -= village.tile_to_world(length * 0.5, 0.0)
	sprite.visible = false
	village.add_entity(sprite)
	_pieces.append(sprite)
	_piece_mids.append(back + length * 0.5)


func _place_pieces() -> void:
	var frame: int = floori(_distance * _t("train_wheel_frames_per_tile")) % WHEEL_PHASES
	if night:
		frame += NIGHT_FRAME_OFFSET
	for k: int in _pieces.size():
		_pieces[k].position = village.tile_to_world(_front + _piece_mids[k], _track_j)
		_pieces[k].frame = frame


func _spawn_puff() -> void:
	var puff: SmokePuff = SmokePuff.new(village.create_sprite(SMOKE_SPRITE, 0), _tuning)
	var jitter: float = _t("smoke_jitter")
	puff.position = village.tile_to_world(_front - _t("smoke_chimney_back"), _track_j) \
		+ Vector2(randf_range(-jitter, jitter), -_t("smoke_chimney_height"))
	village.add_entity(puff)


func _find_platform_tiles(layout: Dictionary) -> void:
	var legend: Dictionary = layout["tile_legend"]
	var platform_key: Variant = legend.find_key(TILE_PLATFORM)
	if platform_key == null:
		push_error("Train: %s tile_legend has no '%s' entry" % [VillageScene.LAYOUT_PATH, TILE_PLATFORM])
		return
	var platform_char: String = platform_key
	var rows: Array = layout["map"]
	var min_i: int = int(_tuning["train_platform_min_i"])
	for j: int in rows.size():
		var row: String = rows[j]
		for i: int in range(min_i, row.length()):
			if row[i] == platform_char:
				_platform_tiles.append(Vector2i(i, j))


## Renders the two-tone whistle (prototype whistle(): triangle tones, each with a
## linear frequency slide, a linear attack to its gain over [code]whistle_attack[/code]
## seconds, then an exponential fall to [code]whistle_end_gain[/code] at its end).
## Each entry of [code]whistle_tones[/code] is
## [code]{freq (Hz), seconds, gain, slide (Hz over the tone), delay (s)}[/code];
## the mix is scaled by [code]whistle_volume[/code].
func _build_whistle() -> AudioStreamWAV:
	var tones: Array = _tuning["whistle_tones"]
	var attack: float = _t("whistle_attack")
	var end_gain: float = _t("whistle_end_gain")
	var volume: float = _t("whistle_volume")
	var length: float = 0.0
	for tone: Dictionary in tones:
		length = maxf(length, float(tone["delay"]) + float(tone["seconds"]))
	var samples: int = ceili(length * WHISTLE_MIX_RATE)
	var data: PackedByteArray = PackedByteArray()
	data.resize(samples * 2)
	for n: int in samples:
		var t: float = float(n) / WHISTLE_MIX_RATE
		var value: float = 0.0
		for tone: Dictionary in tones:
			var local: float = t - float(tone["delay"])
			var seconds: float = float(tone["seconds"])
			if local < 0.0 or local >= seconds:
				continue
			var freq: float = float(tone["freq"])
			var slide: float = float(tone["slide"])
			var gain: float = float(tone["gain"])
			var phase: float = freq * local + slide * local * local / (2.0 * seconds)
			var wave: float = 4.0 * absf(fposmod(phase, 1.0) - 0.5) - 1.0
			var envelope: float = gain * local / attack
			if local >= attack:
				envelope = gain * pow(end_gain / gain, (local - attack) / (seconds - attack))
			value += wave * envelope
		data.encode_s16(n * 2, int(clampf(value * volume, -1.0, 1.0) * 32767.0))
	var stream: AudioStreamWAV = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = WHISTLE_MIX_RATE
	stream.stereo = false
	stream.data = data
	return stream


func _t(key: String) -> float:
	return float(_tuning[key])


## Reads a JSON data file and checks it has every required key. Returns an empty
## dictionary (and logs why) when it does not.
func _load_json(path: String, required_keys: Array[String]) -> Dictionary:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not parsed is Dictionary:
		push_error("Train: %s is missing or is not a JSON object" % path)
		return {}
	var data: Dictionary = parsed
	for key: String in required_keys:
		if not data.has(key):
			push_error("Train: %s has no '%s'" % [path, key])
			return {}
	return data


## True while the train is on screen (arriving, stopped or leaving), for the night
## headlamp glow (story 006).
func is_running() -> bool:
	return _state != State.WAITING


## World position of the locomotive's front on the track: the headlamp glow anchor
## (story 006). Valid after setup.
func front_position() -> Vector2:
	return village.tile_to_world(_front, _track_j)


## The train's current state (WAITING, ARRIVING, STOPPED or LEAVING), for the HUD (story 007).
func get_state() -> State:
	return _state


## Simulation seconds until the next train starts arriving; 0 while a train is running
## (the HUD's next-train countdown, story 007).
func seconds_to_next_train() -> float:
	return maxf(0.0, _timer) if _state == State.WAITING else 0.0
