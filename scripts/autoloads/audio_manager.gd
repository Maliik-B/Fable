extends Node
## Manages all game audio: SFX and music playback.
## Connects to Events signals and plays appropriate sounds.
## Audio files go in res://audio/sfx/ and res://audio/music/.

# -- Music player --
var music_player: AudioStreamPlayer

# -- SFX pool (multiple players for overlapping sounds) --
const SFX_POOL_SIZE := 8
var sfx_players: Array[AudioStreamPlayer] = []
var sfx_index: int = 0

# -- Preloaded sound streams --
# Populated in _ready() once audio files exist.
# Keys are sound names, values are AudioStream resources.
var sounds: Dictionary = {}

# -- Music tracks --
var music_tracks: Dictionary = {}
var current_music: String = ""


func _ready() -> void:
	# Create music player
	music_player = AudioStreamPlayer.new()
	music_player.bus = "Music"
	add_child(music_player)

	# Create SFX player pool
	for i in SFX_POOL_SIZE:
		var player = AudioStreamPlayer.new()
		player.bus = "SFX"
		add_child(player)
		sfx_players.append(player)

	music_player.finished.connect(_on_music_finished)

	_load_sounds()
	_connect_signals()


func _load_sounds() -> void:
	sounds["card_play"] = preload("res://audio/sfx/card_play.wav")
	sounds["card_draw"] = preload("res://audio/sfx/card_draw.wav")
	sounds["hit"] = preload("res://audio/sfx/hit.wav")
	sounds["block"] = preload("res://audio/sfx/block.wav")
	sounds["enemy_die"] = preload("res://audio/sfx/enemy_die.wav")
	sounds["player_hurt"] = preload("res://audio/sfx/player_hurt.wav")
	sounds["combat_win"] = preload("res://audio/sfx/combat_win.wav")
	sounds["combat_lose"] = preload("res://audio/sfx/combat_lose.wav")
	sounds["button_click"] = preload("res://audio/sfx/button_click.wav")
	sounds["gold_gain"] = preload("res://audio/sfx/gold_gain.wav")
	sounds["relic_acquire"] = preload("res://audio/sfx/relic_acquire.wav")
	sounds["heal"] = preload("res://audio/sfx/heal.wav")
	sounds["status_apply"] = preload("res://audio/sfx/status_apply.wav")
	sounds["passion_shift"] = preload("res://audio/sfx/passion_shift.wav")
	sounds["tier_change"] = preload("res://audio/sfx/tier_change.wav")
	sounds["card_exhaust"] = preload("res://audio/sfx/card_exhaust.wav")
	sounds["card_upgrade"] = preload("res://audio/sfx/card_upgrade.wav")
	sounds["shop_buy"] = preload("res://audio/sfx/shop_buy.wav")

	music_tracks["map"] = preload("res://audio/music/map_theme.wav")
	music_tracks["combat"] = preload("res://audio/music/combat_theme.wav")
	music_tracks["boss"] = preload("res://audio/music/boss_theme.wav")
	music_tracks["shop"] = preload("res://audio/music/shop_theme.wav")
	music_tracks["rest"] = preload("res://audio/music/rest_theme.wav")
	music_tracks["victory"] = preload("res://audio/music/victory_theme.wav")


func _connect_signals() -> void:
	# Card events
	Events.card_played.connect(_on_card_played)
	Events.card_drawn.connect(_on_card_drawn)
	Events.card_exhausted.connect(_on_card_exhausted)

	# Combat events
	Events.combat_started.connect(_on_combat_started)
	Events.combat_won.connect(_on_combat_won)
	Events.combat_lost.connect(_on_combat_lost)

	# Damage / defense
	Events.player_damaged.connect(_on_player_damaged)
	Events.enemy_damaged.connect(_on_enemy_damaged)
	Events.enemy_died.connect(_on_enemy_died)
	Events.block_gained.connect(_on_block_gained)

	# Status
	Events.status_applied.connect(_on_status_applied)

	# Passion
	Events.passion_changed.connect(_on_passion_changed)
	Events.passion_tier_changed.connect(_on_passion_tier_changed)

	# Items
	Events.relic_acquired.connect(_on_relic_acquired)


# ============================================================
# SFX PLAYBACK
# ============================================================

## Play a named sound effect. Silently skips if sound not loaded.
func play_sfx(sound_name: String, volume_db: float = 0.0) -> void:
	if sound_name not in sounds:
		return
	var player = sfx_players[sfx_index]
	player.stream = sounds[sound_name]
	player.volume_db = volume_db
	player.play()
	sfx_index = (sfx_index + 1) % SFX_POOL_SIZE


# ============================================================
# MUSIC PLAYBACK
# ============================================================

## Play a named music track. Does nothing if already playing that track.
func play_music(track_name: String, volume_db: float = -6.0) -> void:
	if track_name == current_music:
		return
	if track_name not in music_tracks:
		return
	current_music = track_name
	music_player.stream = music_tracks[track_name]
	music_player.volume_db = volume_db
	music_player.play()


func _on_music_finished() -> void:
	if current_music != "":
		music_player.play()


func stop_music() -> void:
	music_player.stop()
	current_music = ""


# ============================================================
# SIGNAL HANDLERS
# ============================================================

func _on_card_played(_card: CardData, _target) -> void:
	play_sfx("card_play")

func _on_card_drawn(_card: CardData) -> void:
	play_sfx("card_draw", -4.0)

func _on_card_exhausted(_card: CardData) -> void:
	play_sfx("card_exhaust")

func _on_combat_started() -> void:
	if RunManager.pending_act_complete:
		play_music("boss")
	else:
		play_music("combat")

func _on_combat_won() -> void:
	play_sfx("combat_win")

func _on_combat_lost() -> void:
	play_sfx("combat_lose")
	stop_music()

func _on_player_damaged(_amount: int, _new_hp: int) -> void:
	play_sfx("player_hurt")

func _on_enemy_damaged(_enemy, _amount: int, _new_hp: int) -> void:
	play_sfx("hit")

func _on_enemy_died(_enemy) -> void:
	play_sfx("enemy_die")

func _on_block_gained(_target, _amount: int) -> void:
	play_sfx("block")

func _on_status_applied(_target, _effect: StatusEffectData, _stacks: int) -> void:
	play_sfx("status_apply", -3.0)

func _on_passion_changed(_old_value: int, _new_value: int) -> void:
	play_sfx("passion_shift", -3.0)

func _on_passion_tier_changed(_old_tier: int, _new_tier: int) -> void:
	play_sfx("tier_change")

func _on_relic_acquired(_relic: RelicData) -> void:
	play_sfx("relic_acquire")
