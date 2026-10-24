#!/usr/bin/env python3
# -*- coding: utf-8 -*-
import os
import zlib
import shutil

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
SYNC_DIR = os.path.join(SCRIPT_DIR, "Antigravity_Brain_Sync")
HOME = os.path.expanduser("~")
LINUX_AGY_DIR = os.path.join(HOME, ".gemini", "antigravity")
LINUX_CONFIG_AGY = os.path.join(HOME, ".config", "Antigravity")

os.makedirs(os.path.join(LINUX_AGY_DIR, "conversations"), exist_ok=True)
os.makedirs(os.path.join(LINUX_AGY_DIR, "annotations"), exist_ok=True)
logs_dir = os.path.join(LINUX_AGY_DIR, "brain", "5d736eb3-8562-44fc-93e6-a10c30f880e1", ".system_generated", "logs")
os.makedirs(logs_dir, exist_ok=True)
os.makedirs(LINUX_CONFIG_AGY, exist_ok=True)

# 1. Decompress conversation_summaries.db and all conversation .db files
for fname in os.listdir(SYNC_DIR):
    if fname == "conversation_summaries.db.zlib":
        with open(os.path.join(SYNC_DIR, fname), "rb") as f:
            raw = zlib.decompress(f.read())
        out_p = os.path.join(LINUX_AGY_DIR, "conversation_summaries.db")
        for ext in ["", "-wal", "-shm"]:
            if os.path.exists(out_p + ext):
                os.remove(out_p + ext)
        with open(out_p, "wb") as f:
            f.write(raw)
        print("Restored:", out_p)
    elif fname.endswith(".db.zlib"):
        db_name = fname[:-5]
        with open(os.path.join(SYNC_DIR, fname), "rb") as f:
            raw = zlib.decompress(f.read())
        out_p = os.path.join(LINUX_AGY_DIR, "conversations", db_name)
        for ext in ["", "-wal", "-shm"]:
            if os.path.exists(out_p + ext):
                os.remove(out_p + ext)
        with open(out_p, "wb") as f:
            f.write(raw)
        print("Restored conversation DB:", out_p)
    elif fname == "transcript.jsonl.zlib":
        with open(os.path.join(SYNC_DIR, fname), "rb") as f:
            raw = zlib.decompress(f.read())
        with open(os.path.join(logs_dir, "transcript.jsonl"), "wb") as f:
            f.write(raw)
        print("Restored transcript.jsonl")

# 2. Copy agyhub_summaries_proto.pb, antigravity_state.pbtxt, annotations, and app_storage.json
for fn in ["agyhub_summaries_proto.pb", "antigravity_state.pbtxt"]:
    src = os.path.join(SYNC_DIR, fn)
    if os.path.exists(src):
        shutil.copy2(src, os.path.join(LINUX_AGY_DIR, fn))
        print("Restored:", fn)

ann_src = os.path.join(SYNC_DIR, "annotations")
ann_dst = os.path.join(LINUX_AGY_DIR, "annotations")
if os.path.exists(ann_src):
    for fn in os.listdir(ann_src):
        shutil.copy2(os.path.join(ann_src, fn), os.path.join(ann_dst, fn))

app_st = os.path.join(SYNC_DIR, "app_storage.json")
if os.path.exists(app_st):
    shutil.copy2(app_st, os.path.join(LINUX_CONFIG_AGY, "app_storage.json"))
    print("Restored ~/.config/Antigravity/app_storage.json")

# 3. Install GEMINI.md global rule so every AI conversation on this machine obeys King Stephen & Queen Ava
gemini_md = os.path.join(SCRIPT_DIR, "GEMINI.md")
if os.path.exists(gemini_md):
    os.makedirs(os.path.join(HOME, ".gemini", "config"), exist_ok=True)
    shutil.copy2(gemini_md, os.path.join(HOME, ".gemini", "GEMINI.md"))
    shutil.copy2(gemini_md, os.path.join(HOME, ".gemini", "config", "GEMINI.md"))
    print("Installed Royal Hive Mind Charter into ~/.gemini/GEMINI.md")

# 4. Also unlock The King and Queen's Room on Desktop
import royal_chambers_vault as rcv
rcv.unlock_room("PBKDF2-HMAC-SHA256", open_explorer=False)
print("\nALL DONE! Now launch the Antigravity App (not Antigravity IDE) to use Gemini 4 Argon and see all your conversations!")
