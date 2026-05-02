"""Generate placeholder audio files for Fable.
Run: python generate_audio.py
Creates WAV files in audio/sfx/ and audio/music/
"""
import wave, struct, math, random, os

SAMPLE_RATE = 44100

def make_dirs():
    os.makedirs("audio/sfx", exist_ok=True)
    os.makedirs("audio/music", exist_ok=True)

def write_wav(path, samples, sample_rate=SAMPLE_RATE):
    """Write mono 16-bit WAV."""
    with wave.open(path, "w") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(sample_rate)
        for s in samples:
            clamped = max(-1.0, min(1.0, s))
            w.writeframes(struct.pack("<h", int(clamped * 32767)))

def sine(freq, t):
    return math.sin(2 * math.pi * freq * t)

def square(freq, t):
    return 1.0 if sine(freq, t) >= 0 else -1.0

def noise():
    return random.uniform(-1, 1)

def envelope(t, duration, attack=0.01, release=0.05):
    """Simple AR envelope."""
    if t < attack:
        return t / attack
    elif t > duration - release:
        return max(0, (duration - t) / release)
    return 1.0

def gen_samples(duration, func):
    """Generate samples from a function f(t) -> amplitude."""
    n = int(SAMPLE_RATE * duration)
    return [func(i / SAMPLE_RATE) for i in range(n)]

# ============================================================
# SFX GENERATORS
# ============================================================

def sfx_card_play():
    dur = 0.15
    def f(t):
        freq = 400 + 800 * (t / dur)
        return sine(freq, t) * envelope(t, dur, 0.005, 0.05) * 0.5
    return gen_samples(dur, f)

def sfx_card_draw():
    dur = 0.12
    def f(t):
        freq = 600 + 400 * (t / dur)
        return sine(freq, t) * envelope(t, dur, 0.005, 0.04) * 0.35
    return gen_samples(dur, f)

def sfx_hit():
    dur = 0.12
    def f(t):
        env = envelope(t, dur, 0.002, 0.08)
        return (noise() * 0.6 + sine(80, t) * 0.4) * env * 0.7
    return gen_samples(dur, f)

def sfx_block():
    dur = 0.18
    def f(t):
        freq = 800 * math.exp(-t * 8)
        return sine(freq, t) * envelope(t, dur, 0.002, 0.06) * 0.5
    return gen_samples(dur, f)

def sfx_enemy_die():
    dur = 0.4
    def f(t):
        freq = 300 - 200 * (t / dur)
        return sine(freq, t) * envelope(t, dur, 0.01, 0.15) * 0.5
    return gen_samples(dur, f)

def sfx_player_hurt():
    dur = 0.2
    def f(t):
        freq = 200 + 100 * sine(20, t)
        return sine(freq, t) * envelope(t, dur, 0.005, 0.1) * 0.6
    return gen_samples(dur, f)

def sfx_combat_win():
    dur = 0.8
    notes = [523, 659, 784, 1047]  # C5 E5 G5 C6
    def f(t):
        idx = min(int(t / dur * len(notes)), len(notes) - 1)
        freq = notes[idx]
        return sine(freq, t) * envelope(t, dur, 0.02, 0.2) * 0.4
    return gen_samples(dur, f)

def sfx_combat_lose():
    dur = 0.6
    def f(t):
        freq = 400 - 250 * (t / dur)
        return sine(freq, t) * envelope(t, dur, 0.02, 0.2) * 0.5
    return gen_samples(dur, f)

def sfx_button_click():
    dur = 0.06
    def f(t):
        return sine(1200, t) * envelope(t, dur, 0.002, 0.03) * 0.4
    return gen_samples(dur, f)

def sfx_gold_gain():
    dur = 0.25
    def f(t):
        freq = 1200 if t < 0.1 else 1500
        return sine(freq, t) * envelope(t, dur, 0.005, 0.08) * 0.35
    return gen_samples(dur, f)

def sfx_relic_acquire():
    dur = 0.5
    notes = [880, 1100, 1320, 1760]
    def f(t):
        idx = min(int(t / dur * len(notes)), len(notes) - 1)
        freq = notes[idx]
        return sine(freq, t) * envelope(t, dur, 0.01, 0.15) * 0.35
    return gen_samples(dur, f)

def sfx_heal():
    dur = 0.35
    def f(t):
        freq = 400 + 400 * (t / dur)
        return sine(freq, t) * envelope(t, dur, 0.02, 0.1) * 0.4
    return gen_samples(dur, f)

def sfx_status_apply():
    dur = 0.2
    def f(t):
        return (sine(300, t) * 0.5 + sine(450, t) * 0.3) * envelope(t, dur, 0.01, 0.08) * 0.4
    return gen_samples(dur, f)

def sfx_passion_shift():
    dur = 0.25
    def f(t):
        freq = 500 + 300 * sine(8, t)
        return sine(freq, t) * envelope(t, dur, 0.01, 0.1) * 0.4
    return gen_samples(dur, f)

def sfx_tier_change():
    dur = 0.5
    def f(t):
        freq = 600 + 200 * sine(4, t)
        return (sine(freq, t) * 0.5 + sine(freq * 1.5, t) * 0.3) * envelope(t, dur, 0.02, 0.15) * 0.5
    return gen_samples(dur, f)

def sfx_card_exhaust():
    dur = 0.2
    def f(t):
        return noise() * envelope(t, dur, 0.005, 0.15) * 0.3
    return gen_samples(dur, f)

def sfx_card_upgrade():
    dur = 0.35
    notes = [700, 900, 1100]
    def f(t):
        idx = min(int(t / dur * len(notes)), len(notes) - 1)
        return sine(notes[idx], t) * envelope(t, dur, 0.01, 0.1) * 0.35
    return gen_samples(dur, f)

def sfx_shop_buy():
    dur = 0.3
    def f(t):
        if t < 0.1:
            return sine(800, t) * envelope(t, 0.1, 0.003, 0.03) * 0.4
        else:
            return sine(1200, t) * envelope(t - 0.1, 0.2, 0.003, 0.1) * 0.4
    return gen_samples(dur, f)

# ============================================================
# MUSIC GENERATORS (short loops)
# ============================================================

def music_map():
    """Ambient exploration theme - 6 second loop."""
    dur = 6.0
    # Simple arpeggiated chords
    chord_freqs = [
        [261, 329, 392],  # C major
        [220, 277, 329],  # A minor
        [196, 247, 294],  # G (ish)
        [174, 220, 261],  # F (ish)
    ]
    def f(t):
        chord_idx = int(t / 1.5) % 4
        freqs = chord_freqs[chord_idx]
        note_t = (t % 0.5)
        note_idx = int((t % 1.5) / 0.5) % 3
        freq = freqs[note_idx]
        env = envelope(note_t, 0.5, 0.02, 0.15)
        return sine(freq, t) * env * 0.2 + sine(freq * 0.5, t) * env * 0.1
    return gen_samples(dur, f)

def music_combat():
    """Upbeat combat theme - 4 second loop."""
    dur = 4.0
    bass_pattern = [130, 130, 164, 146]  # C3, C3, E3, D3
    def f(t):
        beat = (t * 3) % 1.0  # 180 BPM
        beat_idx = int(t * 3) % 4
        bass = sine(bass_pattern[beat_idx], t) * 0.25
        kick = sine(60, t) * max(0, 1 - beat * 10) * 0.4 if beat < 0.1 else 0
        hihat = noise() * max(0, 1 - ((beat + 0.5) % 1.0) * 20) * 0.15 if (beat + 0.5) % 1.0 < 0.05 else 0
        return bass + kick + hihat
    return gen_samples(dur, f)

def music_boss():
    """Intense boss theme - 4 second loop."""
    dur = 4.0
    bass = [98, 98, 116, 110]  # Lower, more ominous
    def f(t):
        beat = (t * 3.5) % 1.0  # 210 BPM
        beat_idx = int(t * 3.5) % 4
        b = square(bass[beat_idx], t) * 0.15
        kick = sine(50, t) * max(0, 1 - beat * 8) * 0.5 if beat < 0.12 else 0
        snare = noise() * max(0, 1 - ((beat + 0.5) % 1.0) * 12) * 0.25 if (beat + 0.5) % 1.0 < 0.08 else 0
        drone = sine(65, t) * 0.08
        return b + kick + snare + drone
    return gen_samples(dur, f)

def music_shop():
    """Relaxed shop theme - 6 second loop."""
    dur = 6.0
    notes = [330, 392, 440, 494, 440, 392, 330, 294]  # Simple melody
    def f(t):
        idx = int(t / 0.75) % len(notes)
        note_t = t % 0.75
        freq = notes[idx]
        env = envelope(note_t, 0.75, 0.03, 0.25)
        return sine(freq, t) * env * 0.2 + sine(freq * 0.5, t) * env * 0.1
    return gen_samples(dur, f)

def music_rest():
    """Calm rest theme - 8 second loop."""
    dur = 8.0
    notes = [262, 330, 392, 330, 294, 349, 330, 262]
    def f(t):
        idx = int(t / 1.0) % len(notes)
        note_t = t % 1.0
        freq = notes[idx]
        env = envelope(note_t, 1.0, 0.05, 0.4)
        return sine(freq, t) * env * 0.15 + sine(freq * 2, t) * env * 0.05
    return gen_samples(dur, f)

def music_victory():
    """Triumphant victory theme - 4 second loop."""
    dur = 4.0
    notes = [523, 659, 784, 1047, 784, 659, 784, 1047]
    def f(t):
        idx = int(t / 0.5) % len(notes)
        note_t = t % 0.5
        freq = notes[idx]
        env = envelope(note_t, 0.5, 0.02, 0.15)
        return (sine(freq, t) * 0.25 + sine(freq * 0.5, t) * 0.15) * env
    return gen_samples(dur, f)

# ============================================================
# MAIN
# ============================================================

if __name__ == "__main__":
    make_dirs()

    sfx = {
        "card_play": sfx_card_play,
        "card_draw": sfx_card_draw,
        "hit": sfx_hit,
        "block": sfx_block,
        "enemy_die": sfx_enemy_die,
        "player_hurt": sfx_player_hurt,
        "combat_win": sfx_combat_win,
        "combat_lose": sfx_combat_lose,
        "button_click": sfx_button_click,
        "gold_gain": sfx_gold_gain,
        "relic_acquire": sfx_relic_acquire,
        "heal": sfx_heal,
        "status_apply": sfx_status_apply,
        "passion_shift": sfx_passion_shift,
        "tier_change": sfx_tier_change,
        "card_exhaust": sfx_card_exhaust,
        "card_upgrade": sfx_card_upgrade,
        "shop_buy": sfx_shop_buy,
    }

    music = {
        "map_theme": music_map,
        "combat_theme": music_combat,
        "boss_theme": music_boss,
        "shop_theme": music_shop,
        "rest_theme": music_rest,
        "victory_theme": music_victory,
    }

    for name, gen in sfx.items():
        path = f"audio/sfx/{name}.wav"
        write_wav(path, gen())
        print(f"  SFX: {path}")

    for name, gen in music.items():
        path = f"audio/music/{name}.wav"
        write_wav(path, gen())
        print(f"  Music: {path}")

    print(f"\nDone! Generated {len(sfx)} SFX + {len(music)} music tracks.")
