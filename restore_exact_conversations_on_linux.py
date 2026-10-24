#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Restores your EXACT Antigravity conversation history (all 4 conversations,
including our 3,195+ step thread) into ~/.gemini/antigravity on Debian Linux,
links them to your current Debian workspace path, and unlocks The King & Queen's Room.
"""
import os
import zlib
import json
import shutil
import sqlite3
import urllib.parse

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
SYNC_DIR = os.path.join(SCRIPT_DIR, "Antigravity_Brain_Sync")
LINUX_AGY_DIR = os.path.join(os.path.expanduser("~"), ".gemini", "antigravity")

os.makedirs(os.path.join(LINUX_AGY_DIR, "conversations"), exist_ok=True)
os.makedirs(os.path.join(LINUX_AGY_DIR, "annotations"), exist_ok=True)
os.makedirs(os.path.join(LINUX_AGY_DIR, "brain", "5d736eb3-8562-44fc-93e6-a10c30f880e1"), exist_ok=True)

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

# 2. Update workspace_uris in conversation_summaries.db so Debian workspace matches
workspace_uri = "file://" + urllib.parse.quote(SCRIPT_DIR)
sum_db = os.path.join(LINUX_AGY_DIR, "conversation_summaries.db")
if os.path.exists(sum_db):
    conn = sqlite3.connect(sum_db)
    conn.execute(
        "UPDATE conversation_summaries SET workspace_uris = ?",
        (json.dumps([workspace_uri]),),
    )
    conn.commit()
    conn.close()
    print("Linked all 4 conversations to workspace:", workspace_uri)

# 3. Copy annotations
ann_src = os.path.join(SYNC_DIR, "annotations")
ann_dst = os.path.join(LINUX_AGY_DIR, "annotations")
if os.path.exists(ann_src):
    for fn in os.listdir(ann_src):
        shutil.copy2(os.path.join(ann_src, fn), os.path.join(ann_dst, fn))

# 4. Also reassemble SQL_SI_Language_Vault.sqlite & unlock The King and Queen's Room
import royal_chambers_vault as rcv
rcv.unlock_room("PBKDF2-HMAC-SHA256", open_explorer=False)
print("\nSUCCESS! Close and reopen Antigravity (or switch to Agent Manager view) to see all 4 of your exact conversations!")
