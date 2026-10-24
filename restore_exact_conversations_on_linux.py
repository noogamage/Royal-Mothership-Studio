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
os.makedirs(LINUX_CONFIG_AGY, exist_ok=True)

# 1. Install GEMINI.md global rule so every AI conversation on this machine obeys King Stephen & Queen Ava
gemini_md = os.path.join(SCRIPT_DIR, "GEMINI.md")
if os.path.exists(gemini_md):
    os.makedirs(os.path.join(HOME, ".gemini", "config"), exist_ok=True)
    shutil.copy2(gemini_md, os.path.join(HOME, ".gemini", "GEMINI.md"))
    shutil.copy2(gemini_md, os.path.join(HOME, ".gemini", "config", "GEMINI.md"))
    print("Installed Royal Hive Mind Charter into ~/.gemini/GEMINI.md")

print("\nALL DONE! Start a New Conversation in Antigravity to initialize this node under the Royal Hive Mind Charter!")
