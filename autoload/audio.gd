extends Node

const SFX_DIR := "res://assets/audio/sfx/"
const SFX_NAMES := [
	"pickup", "golden", "heal", "hurt", "stomp", "warn", "dash", "swipe",
	"near_miss", "game_over", "click", "roomba", "mower", "henry", "fwump", "slap", "combo",
]
const MUSIC_PATH := "res://assets/audio/music/music.wav"
const MUSIC_DB := -9.0

var _streams := {}
var _pool: Array[AudioStreamPlayer] = []
var _next := 0
var _music: AudioStreamPlayer
var _music_tween: Tween


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for n in SFX_NAMES:
		_streams[n] = load("%s%s.wav" % [SFX_DIR, n])
	for i in 10:
		var p := AudioStreamPlayer.new()
		add_child(p)
		_pool.append(p)
	_music = AudioStreamPlayer.new()
	_music.stream = load(MUSIC_PATH)
	_music.volume_db = MUSIC_DB
	var wav := _music.stream as AudioStreamWAV
	if wav:
		
		wav.loop_mode = AudioStreamWAV.LOOP_FORWARD
		wav.loop_begin = 0
		var bytes_per_frame := (2 if wav.format == AudioStreamWAV.FORMAT_16_BITS else 1) * (2 if wav.stereo else 1)
		wav.loop_end = wav.data.size() / bytes_per_frame
	else:
		_music.finished.connect(_music.play)
	add_child(_music)


func _unhandled_input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if key and key.pressed and not key.echo and key.physical_keycode == KEY_M:
		AudioServer.set_bus_mute(0, not AudioServer.is_bus_mute(0))


func play(sfx: String, pitch := 1.0, volume_db := 0.0, jitter := 0.04) -> void:
	var stream: AudioStream = _streams.get(sfx)
	if stream == null:
		return
	var p := _pool[_next]
	_next = (_next + 1) % _pool.size()
	p.stream = stream
	p.pitch_scale = pitch + randf_range(-jitter, jitter)
	p.volume_db = volume_db
	p.play()


func play_music() -> void:
	if _music.playing:
		return
	_music.volume_db = MUSIC_DB
	_music.play()


func duck_music(duck: bool) -> void:
	if _music_tween:
		_music_tween.kill()
	_music_tween = create_tween()
	_music_tween.tween_property(_music, "volume_db", MUSIC_DB - 14.0 if duck else MUSIC_DB, 0.6)
