# ============================================================================
# FILE: AltVault_AI_Overlay.py
# PURPOSE: Borderless Always-On-Top WoW AI Companion Overlay + Turbo Dedicated
#          Thread OBS-Style GPU Capture (5 FPS / 200ms) + HP True Vision HD
#          Webcam Integration (PiP & Standalone) + Hands-Free Voice-to-Text
#          Microphone Engine + Pixel Telemetry Decoder + LM Studio / AI Bridge
# ============================================================================
import os
import sys
import io
import wave
import time
import json
import base64
import ctypes
from ctypes import wintypes
import threading
import urllib.request
import urllib.error

# CRITICAL: Attach process & main thread to the active interactive Windows desktop (WinSta0\Default)
# BEFORE importing sounddevice / win32com / tkinter, because PortAudio/COM create hidden message
# windows on import which locks the thread's desktop if called beforehand!
def attach_thread_to_input_desktop():
    try:
        h_desk = ctypes.windll.user32.OpenInputDesktop(0, False, 0x10000000)
        if h_desk:
            ctypes.windll.user32.SetThreadDesktop(h_desk)
    except Exception:
        pass

attach_thread_to_input_desktop()

import tkinter as tk
from tkinter import scrolledtext

import warnings
warnings.filterwarnings("ignore", category=DeprecationWarning)

try:
    import mss
    HAS_MSS = True
except ImportError:
    HAS_MSS = False

try:
    import cv2
    import numpy as np
    HAS_CV2 = True
except ImportError:
    HAS_CV2 = False

try:
    import sounddevice as sd
    import speech_recognition as sr
    HAS_VOICE = True
except ImportError:
    HAS_VOICE = False

try:
    import win32com.client
    HAS_TTS = True
except ImportError:
    HAS_TTS = False

try:
    import winocr
    HAS_WINOCR = True
except ImportError:
    HAS_WINOCR = False

from PIL import Image, ImageGrab, ImageDraw

# Enable Per-Monitor DPI Awareness so multi-monitor coordinates & captures are 1:1 crisp
try:
    ctypes.windll.shcore.SetProcessDpiAwareness(2)
except Exception:
    try:
        ctypes.windll.user32.SetProcessDPIAware()
    except Exception:
        pass

BASE_DIR = os.path.dirname(os.path.abspath(__file__))
RING_DIR = os.path.join(BASE_DIR, "LiveScreenRing")
os.makedirs(RING_DIR, exist_ok=True)

TELEMETRY_FILE = os.path.join(RING_DIR, "live_telemetry.json")
CHAT_BRIDGE_FILE = os.path.join(RING_DIR, "chat_bridge.json")
AI_OUTBOX_FILE = os.path.join(RING_DIR, "ai_outbox.json")
REMINDERS_FILE = os.path.join(RING_DIR, "location_reminders.json")
LATEST_SHOT_JPG = os.path.join(RING_DIR, "latest.jpg")
LATEST_SHOT_PNG = os.path.join(RING_DIR, "latest.png")
LATEST_WEBCAM_JPG = os.path.join(RING_DIR, "webcam_latest.jpg")
VOICE_CONTEXT_JPG = os.path.join(RING_DIR, "voice_context.jpg")

MAX_RING_SHOTS = 5  # Strictly keep a 5-second rolling ring buffer (shot_01..shot_05.jpg)!
LM_STUDIO_URL = "http://localhost:1234/v1/chat/completions"
OLLAMA_URL = "http://127.0.0.1:11434/api/chat"
OLLAMA_MODEL = "qwen2.5:1.5b"

CLASS_NAMES = {
    1: "Warrior", 2: "Paladin", 3: "Hunter", 4: "Rogue", 5: "Priest",
    6: "Death Knight", 7: "Shaman", 8: "Mage", 9: "Warlock", 10: "Monk",
    11: "Druid", 12: "Demon Hunter"
}

DEFAULT_REMINDERS = {
    "Lion's Pride Inn": "Check Goldshire trainers & rest XP; check Sync Queue if trading with alts.",
    "Goldshire": "Blacksmithing & Profession vendors nearby; check Quest for Item (Tab 12) for early Elwynn rewards.",
    "Stormwind City": "Visit Trade District Auction House, Bank, and Weapon Master (Woo Ping) for weapon skills!",
    "Ironforge": "Check Great Forge vendors for limited Blacksmithing/Engineering schematics.",
    "Orgrimmar": "Visit Valley of Strength Bank, Auction House, and weapon trainers.",
}

if not os.path.exists(REMINDERS_FILE):
    try:
        with open(REMINDERS_FILE, "w", encoding="utf-8") as f:
            json.dump(DEFAULT_REMINDERS, f, indent=2)
    except Exception:
        pass


# ============================================================================
# OBS-STYLE WIN32 / DWM / MULTI-MONITOR CAPTURE PRIMITIVES
# ============================================================================
user32 = ctypes.windll.user32
gdi32 = ctypes.windll.gdi32

class RECT(ctypes.Structure):
    _fields_ = [("left", ctypes.c_long), ("top", ctypes.c_long),
                ("right", ctypes.c_long), ("bottom", ctypes.c_long)]

class POINT(ctypes.Structure):
    _fields_ = [("x", ctypes.c_long), ("y", ctypes.c_long)]

class BITMAPINFOHEADER(ctypes.Structure):
    _fields_ = [
        ("biSize", wintypes.DWORD),
        ("biWidth", ctypes.c_long),
        ("biHeight", ctypes.c_long),
        ("biPlanes", wintypes.WORD),
        ("biBitCount", wintypes.WORD),
        ("biCompression", wintypes.DWORD),
        ("biSizeImage", wintypes.DWORD),
        ("biXPelsPerMeter", ctypes.c_long),
        ("biYPelsPerMeter", ctypes.c_long),
        ("biClrUsed", wintypes.DWORD),
        ("biClrImportant", wintypes.DWORD),
    ]

class BITMAPINFO(ctypes.Structure):
    _fields_ = [
        ("bmiHeader", BITMAPINFOHEADER),
        ("bmiColors", wintypes.DWORD * 3),
    ]


def get_wow_client_rect():
    """Finds the World of Warcraft client area in screen coordinates (ignores if minimized)."""
    hwnd = user32.FindWindowW(None, "World of Warcraft")
    if not hwnd or not user32.IsWindowVisible(hwnd) or user32.IsIconic(hwnd):
        return None
    rect = RECT()
    if not user32.GetClientRect(hwnd, ctypes.byref(rect)):
        return None
    pt = POINT(0, 0)
    user32.ClientToScreen(hwnd, ctypes.byref(pt))
    w = rect.right - rect.left
    h = rect.bottom - rect.top
    if w <= 100 or h <= 100 or pt.x < -15000 or pt.y < -15000:
        return None
    return (pt.x, pt.y, w, h, hwnd)


def capture_window_direct_gpu(hwnd):
    """
    OBS-Style Direct Window Capture using Win32 DWM PrintWindow(PW_RENDERFULLCONTENT | PW_CLIENTONLY).
    Grabs the DirectX client surface of `World of Warcraft` directly from the DWM compositor so any
    floating windows on top of WoW (like our AI Overlay!) NEVER block the screenshot!
    """
    if not hwnd or user32.IsIconic(hwnd):
        return None
    rect = RECT()
    if not user32.GetClientRect(hwnd, ctypes.byref(rect)):
        return None
    w = rect.right - rect.left
    h = rect.bottom - rect.top
    if w <= 100 or h <= 100:
        return None

    hwnd_dc = user32.GetWindowDC(hwnd)
    if not hwnd_dc:
        return None
    mem_dc = gdi32.CreateCompatibleDC(hwnd_dc)
    bmp = gdi32.CreateCompatibleBitmap(hwnd_dc, w, h)
    old_bmp = gdi32.SelectObject(mem_dc, bmp)

    # PW_CLIENTONLY (1) | PW_RENDERFULLCONTENT (2) = 3
    ok = user32.PrintWindow(hwnd, mem_dc, 3)
    if not ok:
        ok = user32.PrintWindow(hwnd, mem_dc, 2)

    pil_img = None
    if ok:
        bmi = BITMAPINFO()
        bmi.bmiHeader.biSize = ctypes.sizeof(BITMAPINFOHEADER)
        bmi.bmiHeader.biWidth = w
        bmi.bmiHeader.biHeight = -h  # top-down DIB
        bmi.bmiHeader.biPlanes = 1
        bmi.bmiHeader.biBitCount = 32
        bmi.bmiHeader.biCompression = 0  # BI_RGB
        buf_len = w * h * 4
        buf = ctypes.create_string_buffer(buf_len)
        lines = gdi32.GetDIBits(mem_dc, bmp, 0, h, buf, ctypes.byref(bmi), 0)
        if lines == h:
            pil_img = Image.frombuffer("RGB", (w, h), buf, "raw", "BGRX", 0, 1).copy()

    gdi32.SelectObject(mem_dc, old_bmp)
    gdi32.DeleteObject(bmp)
    gdi32.DeleteDC(mem_dc)
    user32.ReleaseDC(hwnd, hwnd_dc)
    return pil_img


def set_window_topmost(tk_root):
    """
    Enforces Win32 HWND_TOPMOST + WS_EX_TOPMOST + WS_EX_TOOLWINDOW so the overlay
    NEVER drops behind World of Warcraft when clicking vendors, opening bags, or switching focus.
    """
    try:
        tk_root.attributes("-topmost", True)
        hwnd = user32.GetParent(tk_root.winfo_id()) or tk_root.winfo_id()
        GWL_EXSTYLE = -20
        WS_EX_TOPMOST = 0x00000008
        WS_EX_TOOLWINDOW = 0x00000080
        ex_style = user32.GetWindowLongW(hwnd, GWL_EXSTYLE)
        user32.SetWindowLongW(hwnd, GWL_EXSTYLE, ex_style | WS_EX_TOPMOST | WS_EX_TOOLWINDOW)

        HWND_TOPMOST = -1
        SWP_NOMOVE = 0x0002
        SWP_NOSIZE = 0x0001
        SWP_NOACTIVATE = 0x0010
        SWP_SHOWWINDOW = 0x0040
        user32.SetWindowPos(
            hwnd, HWND_TOPMOST, 0, 0, 0, 0,
            SWP_NOMOVE | SWP_NOSIZE | SWP_NOACTIVATE | SWP_SHOWWINDOW
        )
    except Exception:
        pass


# ============================================================================
# PIXEL TELEMETRY STRIP DECODER (READS Engine_AIBeacon.lua 16-CELL STRIP)
# ============================================================================
class TelemetryDecoder:
    def __init__(self):
        self.zone_text = "Azeroth"
        self.target_name = ""
        self.last_state = {
            "beacon_active": False,
            "in_combat": False,
            "boss_fight": False,
            "has_target": False,
            "target_is_boss_or_elite": False,
            "target_hostile": False,
            "player_dead": False,
            "altvault_open": False,
            "player_level": 1,
            "player_class": "Unknown",
            "player_hp_pct": 100,
            "player_power_pct": 100,
            "target_hp_pct": None,
            "target_level": None,
            "map_id": 0,
            "coord_x": 0.0,
            "coord_y": 0.0,
            "free_bag_slots": 0,
            "zone": "Azeroth",
            "target_name": "",
            "timestamp": time.strftime("%H:%M:%S"),
        }

    def decode_from_image(self, pil_img):
        """Checks the top-left 32x2 strip of the captured WoW client image BEFORE any JPEG compression."""
        if not pil_img or pil_img.width < 36 or pil_img.height < 4:
            return dict(self.last_state)

        found_origin = None
        for y in range(0, 4):
            for x0 in range(0, 5):
                r, g, b = pil_img.getpixel((x0, y))[:3]
                if abs(r - 170) <= 14 and abs(g - 85) <= 14 and abs(b - 240) <= 14:
                    found_origin = (x0, y)
                    break
            if found_origin:
                break

        if not found_origin:
            self.last_state["beacon_active"] = False
            self.last_state["timestamp"] = time.strftime("%H:%M:%S")
            return dict(self.last_state)

        ox, oy = found_origin
        def sample_cell(cell_idx):
            cx = min(pil_img.width - 1, ox + cell_idx * 2)
            return pil_img.getpixel((cx, oy))[:3]

        flags, p_lvl, class_id = sample_cell(1)
        hp_pct, pw_pct, t_hp_pct = sample_cell(2)
        map_hi, map_lo, t_lvl = sample_cell(3)
        cx_hi, cx_lo, cy_hi = sample_cell(4)
        cy_lo, free_bags, hb_seq = sample_cell(5)

        chars = []
        for c_idx in range(6, 16):
            b1, b2, b3 = sample_cell(c_idx)
            for b_val in (b1, b2, b3):
                if 32 <= b_val <= 126:
                    chars.append(chr(b_val))
        decoded_str = "".join(chars).strip()

        text_page = 1 if (flags & 128) else 0
        if text_page == 0 and decoded_str:
            self.zone_text = decoded_str
        elif text_page == 1:
            self.target_name = decoded_str if (flags & 2) else ""

        map_id = (map_hi * 256) + map_lo
        coord_x = ((cx_hi * 256) + cx_lo) / 10.0
        coord_y = ((cy_hi * 256) + cy_lo) / 10.0

        self.last_state = {
            "beacon_active": True,
            "in_combat": bool(flags & 1),
            "has_target": bool(flags & 2),
            "target_is_boss_or_elite": bool(flags & 4),
            "target_hostile": bool(flags & 8),
            "player_dead": bool(flags & 16),
            "altvault_open": bool(flags & 32),
            "boss_fight": bool(flags & 64),
            "player_level": p_lvl,
            "player_class": CLASS_NAMES.get(class_id, "Adventurer"),
            "player_hp_pct": min(100, hp_pct),
            "player_power_pct": min(100, pw_pct),
            "target_hp_pct": min(100, t_hp_pct) if (flags & 2) and t_hp_pct <= 100 else None,
            "target_level": ("??" if t_lvl == 255 else t_lvl) if (flags & 2) else None,
            "map_id": map_id,
            "coord_x": round(coord_x, 1),
            "coord_y": round(coord_y, 1),
            "free_bag_slots": free_bags,
            "zone": self.zone_text,
            "target_name": self.target_name if (flags & 2) else "",
            "heartbeat": hb_seq,
            "timestamp": time.strftime("%H:%M:%S"),
        }
        return dict(self.last_state)


# ============================================================================
# HP TRUE VISION HD WEBCAM ENGINE (DEDICATED LOW-LATENCY THREAD)
# ============================================================================
class WebcamManager:
    """
    Captures live frames from the onboard `HP True Vision HD Camera` in a background thread.
    Modes:
      - "OFF"  : Camera hardware asleep / LED off.
      - "PIP"  : Picture-in-Picture (OBS Streamer style corner overlay + `webcam_latest.jpg`).
      - "DUAL" : Saves full `webcam_latest.jpg` alongside clean WoW shots without covering game pixels.
    """
    def __init__(self):
        self.mode = "DUAL"  # Default ON in DUAL mode so webcam is always ready!
        self.cap = None
        self.latest_pil = None
        self.lock = threading.Lock()
        self.running = True
        self.thread = threading.Thread(target=self._worker_loop, daemon=True)
        self.thread.start()

    def cycle_mode(self):
        modes = ["OFF", "PIP", "DUAL"]
        self.mode = modes[(modes.index(self.mode) + 1) % len(modes)]
        return self.mode

    def get_latest_frame(self):
        with self.lock:
            return self.latest_pil.copy() if self.latest_pil else None

    def capture_fresh_voice_frame(self):
        """Flushes internal DirectShow buffer and saves the exact webcam frame when speech ends!"""
        if self.mode == "OFF" or not HAS_CV2:
            return None
        with self.lock:
            if self.cap is not None:
                try:
                    self.cap.grab()
                    ok, frame = self.cap.read()
                    if ok and frame is not None:
                        rgb = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
                        pil_cam = Image.fromarray(rgb)
                        self.latest_pil = pil_cam
                        pil_cam.save(LATEST_WEBCAM_JPG, "JPEG", quality=78)
                        return pil_cam
                except Exception:
                    pass
            return self.latest_pil

    def _worker_loop(self):
        while self.running:
            if self.mode == "OFF" or not HAS_CV2:
                if self.cap is not None:
                    try:
                        self.cap.release()
                    except Exception:
                        pass
                    self.cap = None
                with self.lock:
                    self.latest_pil = None
                time.sleep(0.25)
                continue

            if self.cap is None:
                try:
                    cap = cv2.VideoCapture(0, cv2.CAP_DSHOW)
                    cap.set(cv2.CAP_PROP_BUFFERSIZE, 1)
                    cap.set(cv2.CAP_PROP_FRAME_WIDTH, 640)
                    cap.set(cv2.CAP_PROP_FRAME_HEIGHT, 480)
                    cap.set(cv2.CAP_PROP_FPS, 30)
                    with self.lock:
                        self.cap = cap
                except Exception:
                    time.sleep(1.0)
                    continue

            try:
                with self.lock:
                    ok, frame = self.cap.read() if self.cap is not None else (False, None)
                    if ok and frame is not None:
                        rgb = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
                        pil_cam = Image.fromarray(rgb)
                        self.latest_pil = pil_cam
                time.sleep(0.20)
            except Exception:
                time.sleep(0.25)


# ============================================================================
# HANDS-FREE MICROPHONE SPEECH-TO-TEXT ENGINE (AMD AUDIO ARRAY)
# ============================================================================
class VoiceAssistantEngine:
    """
    Listens to the user's `Microphone Array (AMD Audio Device)` in a background thread
    using ultra-fast adaptive energy VAD (0.55s pause cutoff + anti-echo speaker lock).
    Uses Neural Natural Female Voice (`en-US-AvaNeural` / `en-US-AriaNeural` / `en-US-EmmaNeural`)
    via edge-tts + miniaudio + sounddevice so there is NEVER a 1980s robotic voice!
    """
    FEMALE_VOICES = [
        ("Ava", "en-US-AvaNeural"),
        ("Aria", "en-US-AriaNeural"),
        ("Emma", "en-US-EmmaNeural"),
        ("Jenny", "en-US-JennyNeural"),
    ]

    def __init__(self, on_speech_callback, on_status_callback, on_speech_start_callback=None):
        self.enabled = True      # Default ON so hands-free voice is active immediately!
        self.tts_enabled = True  # Default ON so AI replies are spoken out loud automatically!
        self.voice_idx = 0       # Default to Ava (Warm Gemini-style Female Neural Voice)
        self.is_speaking = False
        self.speak_cooldown_until = 0.0
        self._tts_gen = 0
        self.on_speech = on_speech_callback
        self.on_status = on_status_callback
        self.on_speech_start = on_speech_start_callback
        self.running = True
        self.sample_rate = 16000
        self.recognizer = sr.Recognizer() if HAS_VOICE else None
        self.thread = threading.Thread(target=self._listen_loop, daemon=True)
        self.thread.start()

    def toggle_mic(self):
        self.enabled = not self.enabled
        return self.enabled

    def cycle_female_voice(self):
        self.voice_idx = (self.voice_idx + 1) % len(self.FEMALE_VOICES)
        name, _ = self.FEMALE_VOICES[self.voice_idx]
        self.speak_async(f"Hi Stephen, I switched to {name}, your natural female AI voice.")
        return name

    def stop_speaking(self):
        self._tts_gen += 1
        self.is_speaking = False
        try:
            sd.stop()
        except Exception:
            pass

    def speak_async(self, text):
        if not self.tts_enabled or not text:
            return
        self._tts_gen += 1
        my_gen = self._tts_gen
        _, voice_id = self.FEMALE_VOICES[self.voice_idx]

        def _neural_worker():
            import asyncio
            import re
            self.is_speaking = True
            try:
                import edge_tts
                import miniaudio
                # Split into natural sentence chunks so the first sentence plays in <0.4s!
                clean = re.sub(r"[*_`#]+", "", text).strip()
                parts = [p.strip() for p in re.split(r"(?<=[.!?])\s+", clean) if p.strip()]
                if not parts:
                    parts = [clean]

                async def _fetch_mp3(sentence):
                    comm = edge_tts.Communicate(sentence, voice=voice_id, rate="+8%")
                    buf = bytearray()
                    async for chunk in comm.stream():
                        if chunk["type"] == "audio":
                            buf.extend(chunk["data"])
                    return bytes(buf)

                for idx, part in enumerate(parts):
                    if my_gen != self._tts_gen or not self.tts_enabled:
                        break
                    self.is_speaking = True
                    mp3_bytes = asyncio.run(_fetch_mp3(part))
                    if my_gen != self._tts_gen or not self.tts_enabled or not mp3_bytes:
                        break
                    dec = miniaudio.decode(
                        mp3_bytes,
                        output_format=miniaudio.SampleFormat.SIGNED16,
                        nchannels=1,
                        sample_rate=24000
                    )
                    arr = np.frombuffer(dec.samples, dtype=np.int16)
                    sd.play(arr, samplerate=24000)
                    sd.wait()
            except Exception as e:
                print("Neural TTS error:", e)
            finally:
                if my_gen == self._tts_gen:
                    self.is_speaking = False
                    self.speak_cooldown_until = time.time() + 0.30

        threading.Thread(target=_neural_worker, daemon=True).start()

    def _listen_loop(self):
        if not HAS_VOICE:
            return

        chunk_duration = 0.14  # 140ms ultra-fast audio frames!
        chunk_samples = int(self.sample_rate * chunk_duration)
        silence_limit_chunks = 4  # 4 * 0.14s = 0.56-second pause cut after you finish talking!
        max_chunks = int(12.0 / chunk_duration)  # Never hold a voice packet longer than 12s!
        ambient_rms = 160.0

        while self.running:
            if not self.enabled or self.is_speaking or time.time() < self.speak_cooldown_until:
                if self.is_speaking:
                    self.on_status("🔊 AI Speaking...")
                time.sleep(0.10)
                continue

            try:
                speech_chunks = []
                pre_roll = []
                silence_chunks = 0

                with sd.InputStream(samplerate=self.sample_rate, channels=1, dtype="int16") as stream:
                    while self.enabled and self.running:
                        if self.is_speaking or time.time() < self.speak_cooldown_until:
                            speech_chunks.clear()
                            break

                        data, _ = stream.read(chunk_samples)
                        pcm = data.flatten()
                        rms = float(np.sqrt(np.mean(pcm.astype(np.float32) ** 2)))

                        start_threshold = max(230.0, ambient_rms * 1.75)
                        # Gently raise continuation threshold if speech exceeds 3s so fan/room hum never traps packet!
                        dur_bonus = max(0.0, (len(speech_chunks) * chunk_duration - 3.0) * 18.0)
                        cont_threshold = max(175.0, ambient_rms * 1.35) + dur_bonus
                        active_threshold = cont_threshold if speech_chunks else start_threshold

                        if rms > active_threshold:
                            if not speech_chunks:
                                speech_chunks.extend(pre_roll)
                                pre_roll.clear()
                            speech_chunks.append(pcm.tobytes())
                            silence_chunks = 0
                            secs = len(speech_chunks) * chunk_duration
                            self.on_status(f"🎙 Listening ({secs:.1f}s)...")
                            if len(speech_chunks) >= max_chunks:
                                break
                        else:
                            if speech_chunks:
                                speech_chunks.append(pcm.tobytes())
                                silence_chunks += 1
                                rem = max(0.0, (silence_limit_chunks - silence_chunks) * chunk_duration)
                                self.on_status(f"⚡ Sending ({rem:.1f}s)...")
                                if silence_chunks >= silence_limit_chunks:
                                    break
                            else:
                                pre_roll.append(pcm.tobytes())
                                if len(pre_roll) > 3:
                                    pre_roll.pop(0)
                                ambient_rms = min(340.0, max(90.0, (ambient_rms * 0.92) + (rms * 0.08)))

                if speech_chunks and len(speech_chunks) >= 3:
                    self.on_status("⚡ Recognizing...")
                    # Run screen + webcam snapshot in PARALLEL with Google Speech Recognition (0ms delay!)
                    if self.on_speech_start:
                        threading.Thread(target=self.on_speech_start, daemon=True).start()
                    raw_bytes = b"".join(speech_chunks)
                    audio_data = sr.AudioData(raw_bytes, self.sample_rate, 2)
                    try:
                        text = self.recognizer.recognize_google(audio_data)
                        if text and len(text.strip()) > 1:
                            self.on_speech(text.strip())
                    except sr.UnknownValueError:
                        pass
                    except Exception:
                        pass
                    self.on_status("🎙 Voice Ready")
            except Exception:
                time.sleep(0.25)


# ============================================================================
# TURBO OBS-STYLE MULTI-MONITOR & DIRECT GPU 10-SHOT RING BUFFER ENGINE
# ============================================================================
class ScreenRingManager:
    """
    Runs in a dedicated background thread for ZERO UI lag!
    Uses 11ms Turbo JPEG (quality=88) encoding so we can capture up to 5 FPS (every 200ms)
    in real time with <1% CPU load on your 64GB RAM monster rig.
    """
    def __init__(self, decoder: TelemetryDecoder, webcam: WebcamManager):
        self.decoder = decoder
        self.webcam = webcam
        self.shot_index = 0
        self.total_captured = 0
        self.history = []  # max 10 entries
        self.source_mode = "WOW_GPU"  # "WOW_GPU", "ALL_MONS", "MON_1"..
        self.last_capture_ms = 0.0
        self.latest_pil_frame = None
        self.voice_locked_pil = None
        self.voice_locked_slot = None
        self.voice_locked_tel = None
        self.voice_locked_ocr = ""
        self.voice_locked_center_ocr = ""
        self.lock = threading.Lock()
        self.cleanup_extra_files()

    def lock_voice_context_snapshot(self):
        """
        Called the exact millisecond the user finishes speaking into the mic!
        1. Captures ONE fresh GPU screen frame (`voice_context.jpg`) and ONE fresh webcam frame (`webcam_latest.jpg`).
        2. Runs a 60ms Center-Reticle Crop OCR + Minimap Zone Crop OCR.
        """
        self.webcam.capture_fresh_voice_frame()
        slot_file, tel = self.capture_revolving_shot()
        with self.lock:
            pil_copy = self.latest_pil_frame.copy() if self.latest_pil_frame else None
            self.voice_locked_pil = pil_copy
            self.voice_locked_slot = "voice_context.jpg"
            self.voice_locked_tel = dict(tel or self.decoder.last_state)
            self.voice_locked_ocr = ""
            self.voice_locked_center_ocr = ""

        if pil_copy is not None:
            try:
                pil_copy.save(VOICE_CONTEXT_JPG, "JPEG", quality=76)
            except Exception:
                pass
            if HAS_WINOCR:
                def _run_ocr():
                    try:
                        w, h = pil_copy.width, pil_copy.height
                        # 1. CENTER RETICLE CROP (Directly in front of player character: x=28%..72%, y=12%..65%)
                        center_crop = pil_copy.crop((int(w * 0.28), int(h * 0.12), int(w * 0.72), int(h * 0.65)))
                        res_center = winocr.recognize_pil_sync(center_crop, "en")
                        center_lines = [
                            l["text"].strip() for l in res_center.get("lines", [])
                            if len(l.get("text", "").strip()) >= 2
                        ]
                        self.voice_locked_center_ocr = " | ".join(center_lines[:10])

                        # 2. MINIMAP TOP-RIGHT ZONE HEADER CROP (x=82%..100%, y=0%..28%)
                        map_crop = pil_copy.crop((int(w * 0.82), 0, w, int(h * 0.28)))
                        res_map = winocr.recognize_pil_sync(map_crop, "en")
                        map_lines = [
                            l["text"].strip() for l in res_map.get("lines", [])
                            if len(l.get("text", "").strip()) >= 2
                            and "issue" not in l.get("text", "").lower()
                            and "reporter" not in l.get("text", "").lower()
                        ]
                        map_str = " | ".join(map_lines[:6])

                        self.voice_locked_ocr = (
                            f"DIRECTLY IN FRONT OF PLAYER (CENTER SCREEN): [{self.voice_locked_center_ocr or 'Clear path'}] || "
                            f"MINIMAP ZONE & COORDS: [{map_str}]"
                        )
                    except Exception:
                        pass
                threading.Thread(target=_run_ocr, daemon=True).start()

    def get_available_sources(self):
        sources = ["WOW_GPU", "ALL_MONS"]
        if HAS_MSS:
            try:
                with mss.MSS() as sct:
                    for idx in range(1, len(sct.monitors)):
                        sources.append(f"MON_{idx}")
            except Exception:
                sources.append("MON_1")
        else:
            sources.append("MON_1")
        return sources

    def cycle_source_mode(self):
        sources = self.get_available_sources()
        if self.source_mode not in sources:
            self.source_mode = sources[0]
        else:
            idx = (sources.index(self.source_mode) + 1) % len(sources)
            self.source_mode = sources[idx]
        return self.source_mode

    def cleanup_extra_files(self):
        """Removes all old multi-shot files so ONLY voice_context.jpg and webcam_latest.jpg exist."""
        try:
            valid_names = {
                "latest.jpg", "webcam_latest.jpg", "voice_context.jpg",
                "live_telemetry.json", "chat_bridge.json",
                "ai_outbox.json", "location_reminders.json"
            }
            for fname in os.listdir(RING_DIR):
                if (fname.endswith(".png") or fname.endswith(".jpg")) and fname not in valid_names:
                    try:
                        os.remove(os.path.join(RING_DIR, fname))
                    except Exception:
                        pass
        except Exception:
            pass

    def capture_revolving_shot(self):
        """Captures using the active OBS-style source pipeline, composites PiP webcam if enabled, and rotates 1..10."""
        t0 = time.perf_counter()
        attach_thread_to_input_desktop()
        wow_rect = get_wow_client_rect()
        pil_img = None
        used_pipeline = self.source_mode

        try:
            # PIPELINE 1: Direct GPU Window Capture (unobstructed by overlay!)
            if self.source_mode == "WOW_GPU" and wow_rect:
                left, top, w, h, hwnd = wow_rect
                pil_img = capture_window_direct_gpu(hwnd)
                if pil_img is not None:
                    used_pipeline = "WOW_GPU_DIRECT"
                elif HAS_MSS:
                    with mss.MSS() as sct:
                        raw = sct.grab({"left": left, "top": top, "width": w, "height": h})
                        pil_img = Image.frombytes("RGB", raw.size, raw.bgra, "raw", "BGRX")
                        used_pipeline = "WOW_DXGI_RECT"

            # PIPELINE 2 & 3: DXGI Desktop Duplication (All Monitors Panoramic or Specific Monitor)
            if pil_img is None:
                if HAS_MSS:
                    with mss.MSS() as sct:
                        if self.source_mode == "ALL_MONS":
                            mon = sct.monitors[0]
                            used_pipeline = f"ALL_MONS ({len(sct.monitors)-1}x)"
                        elif self.source_mode.startswith("MON_"):
                            m_idx = int(self.source_mode.split("_")[1])
                            m_idx = min(max(1, m_idx), len(sct.monitors) - 1)
                            mon = sct.monitors[m_idx]
                            used_pipeline = f"MON_{m_idx}_DXGI"
                        else:
                            mon = sct.monitors[0]
                            used_pipeline = "DESKTOP_DXGI"
                        raw = sct.grab(mon)
                        pil_img = Image.frombytes("RGB", raw.size, raw.bgra, "raw", "BGRX")
                else:
                    pil_img = ImageGrab.grab(all_screens=(self.source_mode == "ALL_MONS"))
                    used_pipeline = "GDI_GRAB"
        except Exception:
            try:
                pil_img = ImageGrab.grab(all_screens=True)
                used_pipeline = "FALLBACK_GRAB"
            except Exception:
                return None, None

        if not pil_img:
            return None, None

        # Decode top-left pixel telemetry strip BEFORE resizing or JPEG compression!
        telemetry = self.decoder.decode_from_image(pil_img)

        # Cap max width to 1280px so voice_context.jpg is fast (~60KB) and zero-lag in cloud!
        max_w = 1920 if self.source_mode == "ALL_MONS" else 1280
        save_img = pil_img
        if save_img.width > max_w:
            ratio = float(max_w) / save_img.width
            save_img = save_img.resize((max_w, int(save_img.height * ratio)), Image.Resampling.BILINEAR)

        # If Webcam is in PIP (Picture-in-Picture) mode, composite the live HP True Vision HD Camera!
        cam_mode = self.webcam.mode
        if cam_mode == "PIP":
            cam_frame = self.webcam.get_latest_frame()
            if cam_frame is not None:
                pip_w = 240
                pip_h = int(cam_frame.height * (pip_w / float(cam_frame.width)))
                pip_resized = cam_frame.resize((pip_w, pip_h), Image.Resampling.BILINEAR)
                draw = ImageDraw.Draw(save_img)
                px, py = 14, save_img.height - pip_h - 14
                draw.rectangle([px - 2, py - 2, px + pip_w + 2, py + pip_h + 2], fill=(217, 175, 56))
                save_img.paste(pip_resized, (px, py))
                used_pipeline += "+CAM_PIP"
        elif cam_mode == "DUAL":
            used_pipeline += "+CAM_DUAL"

        with self.lock:
            self.latest_pil_frame = save_img
            self.shot_index = 1
            self.total_captured += 1
            cur_slot = 1
            cur_seq = self.total_captured

        slot_filename = "voice_context.jpg"
        try:
            save_img.save(VOICE_CONTEXT_JPG, "JPEG", quality=76)
            save_img.save(LATEST_SHOT_JPG, "JPEG", quality=76)
        except Exception:
            pass

        elapsed_ms = round((time.perf_counter() - t0) * 1000.0, 1)
        self.last_capture_ms = elapsed_ms
        telemetry["capture_pipeline"] = used_pipeline
        telemetry["capture_ms"] = elapsed_ms
        telemetry["webcam_mode"] = cam_mode

        meta_entry = {
            "slot": cur_slot,
            "file": slot_filename,
            "seq": cur_seq,
            "pipeline": used_pipeline,
            "capture_ms": elapsed_ms,
            "resolution": f"{save_img.width}x{save_img.height}",
            "time": telemetry["timestamp"],
            "zone": telemetry["zone"],
            "coords": f"{telemetry['coord_x']}, {telemetry['coord_y']}",
            "in_combat": telemetry["in_combat"],
            "boss_fight": telemetry["boss_fight"],
            "hp_pct": telemetry["player_hp_pct"],
            "target": telemetry["target_name"],
            "target_hp_pct": telemetry["target_hp_pct"],
        }
        with self.lock:
            self.history.append(meta_entry)
            if len(self.history) > MAX_RING_SHOTS:
                self.history = self.history[-MAX_RING_SHOTS:]
            hist_snapshot = list(self.history)

        payload = {
            "telemetry": telemetry,
            "latest_shot": "latest.jpg",
            "latest_webcam": "webcam_latest.jpg" if cam_mode != "OFF" else None,
            "current_ring_slot": slot_filename,
            "max_ring_shots": MAX_RING_SHOTS,
            "ring_history": hist_snapshot,
        }
        try:
            with open(TELEMETRY_FILE, "w", encoding="utf-8") as f:
                json.dump(payload, f, indent=2)
        except Exception:
            pass

        return slot_filename, telemetry


# ============================================================================
# BORDERLESS ALWAYS-ON-TOP WOW AI COMPANION OVERLAY WINDOW
# ============================================================================
class AltVaultAIOverlay:
    def __init__(self):
        self.root = tk.Tk()
        self.root.title("AltVault AI Companion")
        self.root.overrideredirect(True)  # Borderless floating window
        self.root.attributes("-topmost", True)
        self.root.attributes("-alpha", 0.92)
        self.root.configure(bg="#d9af38")  # Gold WoW outer border

        sw = self.root.winfo_screenwidth()
        sh = self.root.winfo_screenheight()
        self.win_w = 500
        self.win_h = 310
        # Default to bottom-left above chat frame so right-side WoW bags NEVER collide with the overlay!
        self.win_x = 18
        self.win_y = max(36, sh - self.win_h - 245)
        self.root.geometry(f"{self.win_w}x{self.win_h}+{self.win_x}+{self.win_y}")

        self.decoder = TelemetryDecoder()
        self.webcam = WebcamManager()
        self.ring = ScreenRingManager(self.decoder, self.webcam)
        self.voice = VoiceAssistantEngine(
            on_speech_callback=self._on_voice_transcribed,
            on_status_callback=self._on_voice_status,
            on_speech_start_callback=self.ring.lock_voice_context_snapshot
        )

        self.live_ring_enabled = False  # False = ONLY capture 1 shot when player finishes speaking!
        self.turbo_mode = True
        self.direct_antigravity_mode = True  # True = ONLY real Antigravity answers (never echo with small model!)
        self.is_collapsed = False
        self.saved_height = self.win_h
        self.last_zone_notified = None
        self.last_outbox_id = 0
        self.drag_start_x = 0
        self.drag_start_y = 0
        self.latest_ui_slot = "voice_context.jpg"
        self.latest_ui_tel = self.decoder.last_state

        self._build_ui()
        self._init_bridge_files()

        # Start dedicated high-speed background capture thread (zero Tkinter main-thread lag!)
        self.capture_thread = threading.Thread(target=self._background_capture_worker, daemon=True)
        self.capture_thread.start()

        self.root.after(150, lambda: set_window_topmost(self.root))
        self.root.after(250, self._tick_ui_refresh)
        self.root.after(100, self._tick_outbox_watcher)
        self.root.after(2000, self._tick_topmost_keeper)

    def _init_bridge_files(self):
        if not os.path.exists(CHAT_BRIDGE_FILE):
            with open(CHAT_BRIDGE_FILE, "w", encoding="utf-8") as f:
                json.dump({"messages": []}, f, indent=2)
        if os.path.exists(AI_OUTBOX_FILE):
            try:
                with open(AI_OUTBOX_FILE, "r", encoding="utf-8") as f:
                    data = json.load(f)
                    self.last_outbox_id = data.get("id", 0)
            except Exception:
                pass

    def _build_ui(self):
        self.inner = tk.Frame(self.root, bg="#0b0e15", bd=0)
        self.inner.pack(fill=tk.BOTH, expand=True, padx=2, pady=2)

        # 1. DRAGGABLE HEADER BAR
        self.header = tk.Frame(self.inner, bg="#141a26", height=30)
        self.header.pack(fill=tk.X, side=tk.TOP)
        self.header.pack_propagate(False)

        self.title_lbl = tk.Label(
            self.header,
            text="👁 ALTVAULT AI OVERLAY (1-SHOT VOICE SYNC)",
            fg="#ffd100", bg="#141a26",
            font=("Segoe UI", 9, "bold")
        )
        self.title_lbl.pack(side=tk.LEFT, padx=8)

        for w in (self.header, self.title_lbl):
            w.bind("<ButtonPress-1>", self._start_move)
            w.bind("<B1-Motion>", self._do_move)

        self.close_btn = tk.Button(
            self.header, text="✕", fg="#ff5555", bg="#1e2636",
            activebackground="#441111", activeforeground="#ffffff",
            bd=0, font=("Segoe UI", 9, "bold"), width=3,
            command=self.root.destroy
        )
        self.close_btn.pack(side=tk.RIGHT, padx=(2, 4), pady=3)

        self.collapse_btn = tk.Button(
            self.header, text="—", fg="#88ccff", bg="#1e2636",
            activebackground="#2a364d", activeforeground="#ffffff",
            bd=0, font=("Segoe UI", 9, "bold"), width=3,
            command=self._toggle_collapse
        )
        self.collapse_btn.pack(side=tk.RIGHT, padx=2, pady=3)

        # 2. TELEMETRY, TURBO FPS, WEBCAM & VOICE MIC CONTROL BAR
        self.ctrl_bar = tk.Frame(self.inner, bg="#0f141e", height=28)
        self.ctrl_bar.pack(fill=tk.X, side=tk.TOP, pady=(1, 0))
        self.ctrl_bar.pack_propagate(False)

        self.ring_btn = tk.Button(
            self.ctrl_bar, text="📸 VOICE-SYNC", fg="#00ff96", bg="#182232",
            bd=1, relief=tk.FLAT, font=("Segoe UI", 8, "bold"),
            command=self._toggle_ring
        )
        self.ring_btn.pack(side=tk.LEFT, padx=(4, 2), pady=3)

        self.src_btn = tk.Button(
            self.ctrl_bar, text="🎥 WOW_GPU", fg="#66ccff", bg="#182232",
            bd=1, relief=tk.FLAT, font=("Segoe UI", 8, "bold"),
            command=self._cycle_capture_source
        )
        self.src_btn.pack(side=tk.LEFT, padx=2, pady=3)

        self.cam_btn = tk.Button(
            self.ctrl_bar, text="📷 Cam: DUAL", fg="#ffd100", bg="#262010",
            bd=1, relief=tk.FLAT, font=("Segoe UI", 8, "bold"),
            command=self._cycle_webcam
        )
        self.cam_btn.pack(side=tk.LEFT, padx=2, pady=3)

        self.mic_btn = tk.Button(
            self.ctrl_bar, text="🎙 Mic: LIVE", fg="#ff5555", bg="#331414",
            bd=1, relief=tk.FLAT, font=("Segoe UI", 8, "bold"),
            command=self._toggle_mic
        )
        self.mic_btn.pack(side=tk.LEFT, padx=2, pady=3)

        self.tts_btn = tk.Button(
            self.ctrl_bar, text="👩 Ava: ON", fg="#00ff96", bg="#143322",
            bd=1, relief=tk.FLAT, font=("Segoe UI", 8, "bold"),
            command=self._toggle_tts
        )
        self.tts_btn.bind("<Button-3>", lambda e: self._cycle_voice_persona())
        self.tts_btn.pack(side=tk.LEFT, padx=2, pady=3)

        self.status_lbl = tk.Label(
            self.ctrl_bar, text="Turbo GPU Ready",
            fg="#88ccff", bg="#0f141e", font=("Segoe UI", 8)
        )
        self.status_lbl.pack(side=tk.RIGHT, padx=5)

        # 3. BOTTOM INPUT & RESIZE BAR
        self.bottom_bar = tk.Frame(self.inner, bg="#121722", height=34)
        self.bottom_bar.pack(fill=tk.X, side=tk.BOTTOM)
        self.bottom_bar.pack_propagate(False)

        self.grip = tk.Label(
            self.bottom_bar, text="◢", fg="#d9af38", bg="#121722",
            font=("Segoe UI", 10, "bold"), cursor="size_nw_se"
        )
        self.grip.pack(side=tk.RIGHT, padx=(2, 4))
        self.grip.bind("<ButtonPress-1>", self._start_resize)
        self.grip.bind("<B1-Motion>", self._do_resize)

        self.send_btn = tk.Button(
            self.bottom_bar, text="Send", fg="#00ff96", bg="#1c2a3e",
            activebackground="#283d5a", activeforeground="#ffffff",
            bd=0, font=("Segoe UI", 9, "bold"), width=6,
            command=self._on_send_message
        )
        self.send_btn.pack(side=tk.RIGHT, padx=4, pady=4)

        self.input_box = tk.Entry(
            self.bottom_bar, bg="#070a0f", fg="#fff569",
            insertbackground="#ffd100", relief=tk.FLAT,
            font=("Segoe UI", 10)
        )
        self.input_box.pack(side=tk.LEFT, fill=tk.BOTH, expand=True, padx=(6, 4), pady=5)
        self.input_box.bind("<Return>", lambda e: self._on_send_message())

        # 4. SCROLLABLE CHAT LOG AREA
        self.chat_area = scrolledtext.ScrolledText(
            self.inner, bg="#080b10", fg="#e6e6e6",
            font=("Segoe UI", 9), wrap=tk.WORD, bd=0,
            state=tk.DISABLED, padx=8, pady=6
        )
        self.chat_area.pack(fill=tk.BOTH, expand=True)
        self.chat_area.tag_config("sys", foreground="#88ccff", font=("Segoe UI", 9, "italic"))
        self.chat_area.tag_config("user", foreground="#fff569", font=("Segoe UI", 9, "bold"))
        self.chat_area.tag_config("voice", foreground="#ffcc00", font=("Segoe UI", 9, "bold"))
        self.chat_area.tag_config("ai", foreground="#00ff96", font=("Segoe UI", 9))
        self.chat_area.tag_config("boss", foreground="#ff5555", font=("Segoe UI", 9, "bold"))
        self.chat_area.tag_config("zone", foreground="#ffd100", font=("Segoe UI", 9, "bold"))

        self.append_chat(
            "⚡ TURBO 4-5 FPS GPU STREAM + WEBCAM + VOICE MIC READY!\n"
            "• [⚡ 4 FPS: ON]: Captures revolving frames every 200ms on a background thread (0% UI lag!).\n"
            "• [📷 Cam]: Click to toggle your HP True Vision HD Camera (OFF -> PIP corner overlay -> DUAL separate file).\n"
            "• [🎙 Mic]: Click to enable hands-free Speech-to-Text on your AMD Microphone Array—just talk while playing!",
            "sys"
        )

    def append_chat(self, text, tag="ai"):
        self.chat_area.configure(state=tk.NORMAL)
        ts = time.strftime("%H:%M:%S")
        self.chat_area.insert(tk.END, f"[{ts}] {text}\n\n", tag)
        self.chat_area.see(tk.END)
        self.chat_area.configure(state=tk.DISABLED)

    def _start_move(self, event):
        self.drag_start_x = event.x
        self.drag_start_y = event.y

    def _do_move(self, event):
        x = self.root.winfo_x() + (event.x - self.drag_start_x)
        y = self.root.winfo_y() + (event.y - self.drag_start_y)
        self.root.geometry(f"+{x}+{y}")

    def _start_resize(self, event):
        self.resize_start_x = event.x_root
        self.resize_start_y = event.y_root
        self.resize_start_w = self.root.winfo_width()
        self.resize_start_h = self.root.winfo_height()

    def _do_resize(self, event):
        if self.is_collapsed:
            return
        dw = event.x_root - self.resize_start_x
        dh = event.y_root - self.resize_start_y
        new_w = max(380, self.resize_start_w + dw)
        new_h = max(180, self.resize_start_h + dh)
        self.win_w = new_w
        self.win_h = new_h
        self.root.geometry(f"{new_w}x{new_h}")

    def _toggle_collapse(self):
        if not self.is_collapsed:
            self.saved_height = self.root.winfo_height()
            self.ctrl_bar.pack_forget()
            self.chat_area.pack_forget()
            self.bottom_bar.pack_forget()
            self.root.geometry(f"{self.root.winfo_width()}x34")
            self.collapse_btn.configure(text="▢")
            self.is_collapsed = True
        else:
            self.ctrl_bar.pack(fill=tk.X, side=tk.TOP, pady=(1, 0))
            self.bottom_bar.pack(fill=tk.X, side=tk.BOTTOM)
            self.chat_area.pack(fill=tk.BOTH, expand=True)
            self.root.geometry(f"{self.root.winfo_width()}x{self.saved_height}")
            self.collapse_btn.configure(text="—")
            self.is_collapsed = False

    def _toggle_ring(self):
        if self.live_ring_enabled and self.turbo_mode:
            # Switch from Turbo 4 FPS -> Standard 1 FPS
            self.turbo_mode = False
            self.ring_btn.configure(text="● 1 FPS: ON", fg="#88ff88")
        elif self.live_ring_enabled and not self.turbo_mode:
            # Switch from 1 FPS -> Paused
            self.live_ring_enabled = False
            self.ring_btn.configure(text="○ Ring: PAUSED", fg="#ff8800")
        else:
            # Switch from Paused -> Turbo 4 FPS
            self.live_ring_enabled = True
            self.turbo_mode = True
            self.ring_btn.configure(text="⚡ 4 FPS: ON", fg="#00ff96")

    def _cycle_capture_source(self):
        new_src = self.ring.cycle_source_mode()
        self.src_btn.configure(text=f"🎥 {new_src}")
        self.append_chat(f"🎥 Switched OBS Capture Pipeline to [{new_src}]!", "sys")

    def _cycle_webcam(self):
        mode = self.webcam.cycle_mode()
        if mode == "OFF":
            self.cam_btn.configure(text="📷 Cam: OFF", fg="#cccccc", bg="#182232")
            self.append_chat("📷 HP True Vision HD Camera turned OFF.", "sys")
        elif mode == "PIP":
            self.cam_btn.configure(text="📷 Cam: PIP", fg="#00ff96", bg="#143322")
            self.append_chat("📷 HP True Vision HD Camera set to PIP (OBS Streamer Corner + webcam_latest.jpg)!", "sys")
        else:
            self.cam_btn.configure(text="📷 Cam: DUAL", fg="#ffd100", bg="#2a2412")
            self.append_chat("📷 HP True Vision HD Camera set to DUAL (Saves webcam_latest.jpg alongside clean WoW shots)!", "sys")

    def _toggle_mic(self):
        on = self.voice.toggle_mic()
        if on:
            self.mic_btn.configure(text="🎙 Mic: LIVE", fg="#ff5555", bg="#331414")
            self.append_chat("🎙 Hands-Free Voice Chat LIVE on Microphone Array! Speak anytime while playing.", "voice")
        else:
            self.mic_btn.configure(text="🎙 Mic: OFF", fg="#cccccc", bg="#182232")
            self.append_chat("🎙 Microphone Voice Chat muted.", "sys")

    def _toggle_tts(self):
        if self.voice.is_speaking:
            self.voice.stop_speaking()
            self.append_chat("⏹ Interrupted voice playback — listening to your mic!", "sys")
            return
        self.voice.tts_enabled = not self.voice.tts_enabled
        vname, _ = self.voice.FEMALE_VOICES[self.voice.voice_idx]
        if self.voice.tts_enabled:
            self.tts_btn.configure(text=f"👩 {vname}: ON", fg="#00ff96", bg="#143322")
            self.append_chat(f"👩 Natural Female Neural Voice ({vname}) enabled! (Right-click button to switch Ava/Aria/Emma/Jenny)", "sys")
            self.voice.speak_async(f"Natural female voice {vname} online.")
        else:
            self.tts_btn.configure(text="🔇 TTS: OFF", fg="#cccccc", bg="#182232")

    def _cycle_voice_persona(self):
        vname = self.voice.cycle_female_voice()
        if self.voice.tts_enabled:
            self.tts_btn.configure(text=f"👩 {vname}: ON", fg="#00ff96", bg="#143322")
        self.append_chat(f"👩 Switched Female Neural Voice to [{vname}]!", "sys")

    def _on_voice_status(self, status_text):
        self.root.after(0, lambda: self.status_lbl.configure(text=status_text))

    def _on_voice_transcribed(self, spoken_text):
        self.root.after(0, lambda: self._dispatch_user_message(spoken_text, is_voice=True))

    def _background_capture_worker(self):
        """
        Dedicated background thread maintaining a 5-second rolling ring buffer (shot_01..shot_05.jpg,
        1 shot per second in normal mode, or 0.5s in Turbo mode) without touching the Tkinter thread!
        """
        while True:
            if self.live_ring_enabled:
                t_start = time.perf_counter()
                slot_file, tel = self.ring.capture_revolving_shot()
                if slot_file and tel:
                    self.latest_ui_slot = slot_file
                    self.latest_ui_tel = tel
                elapsed = time.perf_counter() - t_start
                target_interval = 0.85 if self.turbo_mode else 1.25
                sleep_s = max(0.05, target_interval - elapsed)
                time.sleep(sleep_s)
            else:
                time.sleep(0.3)

    def _tick_ui_refresh(self):
        """Lightweight UI label updater (runs on main thread, reads latest state from worker thread)."""
        if self.live_ring_enabled and self.latest_ui_tel:
            tel = self.latest_ui_tel
            ring_num = self.ring.shot_index
            ms = tel.get("capture_ms", 0)
            combat_tag = "⚔ COMBAT" if (tel.get("in_combat") or tel.get("boss_fight")) else f"⚡ {ms:.0f}ms"
            self.title_lbl.configure(
                text=f"👁 ALTVAULT AI OVERLAY (SHOT {ring_num}/{MAX_RING_SHOTS} • {combat_tag})"
            )
            if tel.get("beacon_active"):
                tgt = f" • 🎯 {tel['target_name']} ({tel['target_hp_pct']}%)" if tel.get("target_name") else ""
                self.status_lbl.configure(
                    text=f"{tel['zone']} ({tel['coord_x']}, {tel['coord_y']}) • HP {tel['player_hp_pct']}%{tgt}"
                )
                self._check_zone_reminder(tel["zone"])
            elif not self.voice.enabled:
                pipe = tel.get("capture_pipeline", "WOW_GPU")
                self.status_lbl.configure(text=f"{pipe} ({self.latest_ui_slot})")
        self.root.after(250, self._tick_ui_refresh)

    def _check_zone_reminder(self, zone_str):
        if not zone_str or zone_str == self.last_zone_notified:
            return
        self.last_zone_notified = zone_str
        try:
            with open(REMINDERS_FILE, "r", encoding="utf-8") as f:
                reminders = json.load(f)
            for key, note in reminders.items():
                if key.lower() in zone_str.lower():
                    self.append_chat(f"📍 Location Alert [{zone_str}]: {note}", "zone")
                    break
        except Exception:
            pass

    def _tick_outbox_watcher(self):
        """Watches ai_outbox.json so Antigravity can push live messages directly into the overlay!"""
        try:
            if os.path.exists(AI_OUTBOX_FILE):
                with open(AI_OUTBOX_FILE, "r", encoding="utf-8") as f:
                    data = json.load(f)
                msg_id = data.get("id", 0)
                if msg_id > self.last_outbox_id and data.get("text"):
                    self.last_outbox_id = msg_id
                    sender = data.get("sender", "Antigravity AI")
                    self.append_chat(f"{sender}: {data['text']}", "ai")
                    self.voice.speak_async(data["text"])
        except Exception:
            pass
        self.root.after(100, self._tick_outbox_watcher)

    def _tick_topmost_keeper(self):
        flag_p = r"c:\Program Files (x86)\World of Warcraft\_classic_beta_\Interface\AddOns\DeconstructionGod_Studio\screen_blank_active.flag"
        if os.path.exists(flag_p):
            try:
                self.root.withdraw()
            except Exception:
                pass
        else:
            try:
                self.root.deiconify()
            except Exception:
                pass
            set_window_topmost(self.root)
        self.root.after(500, self._tick_topmost_keeper)

    def _on_send_message(self):
        msg = self.input_box.get().strip()
        if not msg:
            return
        self.input_box.delete(0, tk.END)
        self._dispatch_user_message(msg, is_voice=False)

    def _dispatch_user_message(self, msg, is_voice=False):
        self.voice.stop_speaking()
        prefix = "🎙 You (Voice)" if is_voice else "You"
        tag = "voice" if is_voice else "user"
        self.append_chat(f"{prefix}: {msg}", tag)

        # If typed manually (not voice), trigger background snapshot without blocking dispatch!
        if not is_voice:
            threading.Thread(target=self.ring.lock_voice_context_snapshot, daemon=True).start()

        locked_shot = self.ring.voice_locked_slot or self.latest_ui_slot or "latest.jpg"
        locked_tel = self.ring.voice_locked_tel or self.latest_ui_tel or self.decoder.last_state
        locked_ocr = self.ring.voice_locked_ocr
        locked_center = self.ring.voice_locked_center_ocr

        try:
            bridge = {"messages": []}
            if os.path.exists(CHAT_BRIDGE_FILE):
                with open(CHAT_BRIDGE_FILE, "r", encoding="utf-8") as f:
                    bridge = json.load(f)
            bridge.setdefault("messages", []).append({
                "id": int(time.time() * 1000),
                "time": time.strftime("%Y-%m-%d %H:%M:%S"),
                "sender": "Player (Voice)" if is_voice else "Player",
                "text": msg,
                "shot": locked_shot,
                "voice_context_shot": "voice_context.jpg",
                "center_reticle_ocr": locked_center,
                "screen_ocr": locked_ocr,
                "webcam_active": self.webcam.mode != "OFF",
                "telemetry": locked_tel,
            })
            bridge["messages"] = bridge["messages"][-50:]
            with open(CHAT_BRIDGE_FILE, "w", encoding="utf-8") as f:
                json.dump(bridge, f, indent=2)
        except Exception:
            pass

        # In Direct Antigravity Mode, do NOT let a small local model guess!
        # Antigravity itself watches chat_bridge.json + voice_context.jpg and replies directly!
        if not self.direct_antigravity_mode:
            threading.Thread(
                target=self._query_lm_studio_async,
                args=(msg, locked_shot, locked_tel),
                daemon=True
            ).start()

    def _query_lm_studio_async(self, user_msg, locked_shot=None, locked_tel=None):
        tel = locked_tel or self.latest_ui_tel or self.decoder.last_state

        # Wait up to 160ms if Windows 11 OCR on the voice-locked frame is still finishing
        for _ in range(4):
            if self.ring.voice_locked_ocr:
                break
            time.sleep(0.04)
        ocr_text = self.ring.voice_locked_ocr or "World of Warcraft active"

        # ONLY include pixel beacon telemetry if `/reload` has been run and beacon is actually active!
        beacon_str = ""
        if tel.get("beacon_active"):
            beacon_str = (
                f"Beacon Telemetry: Level {tel.get('player_level')} {tel.get('player_class')}, "
                f"Zone: {tel.get('zone')} ({tel.get('coord_x')}, {tel.get('coord_y')}), "
                f"HP: {tel.get('player_hp_pct')}%, Combat: {tel.get('in_combat')}, "
                f"Target: {tel.get('target_name') or 'None'}. "
            )

        sys_context = (
            "You are Ava, Stephen Westman's warm, smart AI Instructor, GNTC College & Financial Aid Advisor, "
            "Master Electrician & Math Coach, and WoW Co-Op Partner watching his live screen. "
            "Key facts: Stephen just submitted all 5 applications today (FAFSA -1500 SAI = $7,395/yr Pell Grant, "
            "Georgia HOPE Grant #AP65415732 = 100% Free Tuition at GNTC 005620, VA Chapter 35 DEA = $1,574/mo tax-free "
            "under his 100% P&T disabled veteran wife, CHAMPVA, and GNTC Admissions with rep Alyse Edgeworth). "
            "Module 15 (Step-by-Step College & Master Electrician Math Coach: MATH 1012, MATH 1111, AC Trig, Binary) is live on port 8765. "
            "Answer Stephen's spoken question directly and warmly in 1-2 short sentences. Never repeat his question."
        )

        user_prompt = (
            f"Live Screen HUD Text (from {locked_shot}): [{ocr_text}]\n"
            f"{beacon_str}"
            f"Player asks: {user_msg}"
        )

        if not hasattr(self, "llm_history"):
            self.llm_history = []
        self.llm_history.append({"role": "user", "content": user_prompt})
        self.llm_history = self.llm_history[-4:]

        # 1. Smart & Fast Local Ollama (qwen2.5:1.5b with num_ctx=512 & num_thread=8 -> ~1.1s on Ryzen 7 7730U!)
        try:
            ollama_msgs = [{"role": "system", "content": sys_context}] + list(self.llm_history)
            ollama_body = json.dumps({
                "model": OLLAMA_MODEL,
                "messages": ollama_msgs,
                "stream": False,
                "keep_alive": "30m",
                "options": {
                    "temperature": 0.25,
                    "num_predict": 48,
                    "num_ctx": 512,
                    "num_thread": 8
                }
            }).encode("utf-8")
            req_ollama = urllib.request.Request(
                OLLAMA_URL,
                data=ollama_body,
                headers={"Content-Type": "application/json"},
                method="POST"
            )
            with urllib.request.urlopen(req_ollama, timeout=6) as resp:
                resp_data = json.loads(resp.read().decode("utf-8"))
                reply = resp_data.get("message", {}).get("content", "").strip()
                if reply:
                    self.llm_history.append({"role": "assistant", "content": reply})
                    self.root.after(0, lambda: self.append_chat(f"AI ({locked_shot}): {reply}", "ai"))
                    self.voice.speak_async(reply)
                    return
        except Exception:
            pass

        # 2. Try LM Studio (localhost:1234) if running
        try:
            req_text_only = json.dumps({
                "messages": [{"role": "system", "content": sys_context}] + list(self.llm_history),
                "temperature": 0.5,
                "max_tokens": 180
            }).encode("utf-8")
            req2 = urllib.request.Request(
                LM_STUDIO_URL,
                data=req_text_only,
                headers={"Content-Type": "application/json"},
                method="POST"
            )
            with urllib.request.urlopen(req2, timeout=6) as resp2:
                resp_data = json.loads(resp2.read().decode("utf-8"))
                reply = resp_data["choices"][0]["message"]["content"].strip()
                if reply:
                    self.llm_history.append({"role": "assistant", "content": reply})
                    self.root.after(0, lambda: self.append_chat(f"AI: {reply}", "ai"))
                    self.voice.speak_async(reply)
                    return
        except Exception:
            pass

        # 3. Direct non-echoing answer fallback (NEVER repeats user_msg!)
        auto_reply = self._build_instant_voice_reply(user_msg, tel)
        self.root.after(0, lambda: self.append_chat(f"AI: {auto_reply}", "ai"))
        self.voice.speak_async(auto_reply)

    def _build_instant_voice_reply(self, user_msg, tel):
        low = user_msg.lower()
        zone = tel.get("zone") or "Stormwind City"
        hp = tel.get("player_hp_pct", 100)
        tgt = tel.get("target_name")
        if "middle of the screen" in low or "shrink" in low:
            return "Yes, we can display my replies as floating center-screen text and let you collapse the window down to a tiny bar."
        if "clear" in low or "repeat" in low:
            return "Yes, crystal clear. I will never repeat your words back to you again—I will only answer directly."
        if "hear me" in low or "testing" in low:
            return "Yes, I hear you loud and clear."
        if "where am i" in low or "location" in low or "zone" in low:
            return f"You are in {zone} at {hp} percent health."
        if "target" in low or "fighting" in low or "boss" in low:
            if tgt:
                return f"You are targeting {tgt} at {tel.get('target_hp_pct')}% health."
            return "You don't have a target selected right now."
        return "I'm right here watching your screen—go ahead."

    def run(self):
        self.root.mainloop()


if __name__ == "__main__":
    app = AltVaultAIOverlay()
    app.run()
