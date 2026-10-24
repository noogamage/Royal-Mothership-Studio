import os
import subprocess
import ctypes

# CRITICAL: Attach process & main thread to the active interactive Windows desktop (WinSta0\Default)
# BEFORE importing tkinter, so the window and SC_MONITORPOWER hardware power-off execute on the physical screen!
def attach_thread_to_input_desktop():
    try:
        h_desk = ctypes.windll.user32.OpenInputDesktop(0, False, 0x10000000)
        if h_desk:
            ctypes.windll.user32.SetThreadDesktop(h_desk)
    except Exception:
        pass

attach_thread_to_input_desktop()

import tkinter as tk

STUDIO_DIR = r'c:\Program Files (x86)\World of Warcraft\_classic_beta_\Interface\AddOns\DeconstructionGod_Studio'
FLAG_PATH = os.path.join(STUDIO_DIR, 'screen_blank_active.flag')

def set_brightness(val):
    try:
        subprocess.Popen(
            ['powershell', '-WindowStyle', 'Hidden', '-Command',
             f'(Get-WmiObject -Namespace root/WMI -Class WmiMonitorBrightnessMethods).WmiSetBrightness(1, {int(val)})'],
            creationflags=0x08000000
        )
    except Exception:
        pass

def power_off_monitor_hardware(hwnd):
    try:
        # Keep CPU & Wi-Fi 100% awake (ES_CONTINUOUS | ES_SYSTEM_REQUIRED) without holding ES_DISPLAY_REQUIRED
        ctypes.windll.kernel32.SetThreadExecutionState(0x80000000 | 0x00000001)
        user32 = ctypes.windll.user32
        # Physically power off the laptop display controller & LED backlight (WM_SYSCOMMAND = 0x0112, SC_MONITORPOWER = 0xF170, 2 = OFF)
        user32.DefWindowProcW(hwnd, 0x0112, 0xF170, 2)
        user32.SendNotifyMessageW(0xFFFF, 0x0112, 0xF170, 2)
    except Exception:
        pass

def get_cursor_pos():
    class POINT(ctypes.Structure):
        _fields_ = [("x", ctypes.c_long), ("y", ctypes.c_long)]
    pt = POINT()
    ctypes.windll.user32.GetCursorPos(ctypes.byref(pt))
    return pt.x, pt.y

def run_blanker():
    set_brightness(0)
    root = tk.Tk()
    root.title("Screen Off Mode")
    root.configure(bg="#000000")
    root.overrideredirect(True)
    sw = root.winfo_screenwidth()
    sh = root.winfo_screenheight()
    root.geometry(f"{sw}x{sh}+0+0")
    root.attributes("-topmost", True)
    root.config(cursor="none")

    start_mx, start_my = get_cursor_pos()

    def wake(event=None):
        try:
            if os.path.exists(FLAG_PATH):
                os.remove(FLAG_PATH)
        except Exception:
            pass
        try:
            ctypes.windll.user32.mouse_event(0x0001, 1, 0, 0, 0)
        except Exception:
            pass
        set_brightness(90)
        root.destroy()

    root.bind("<Key>", wake)
    root.bind("<Button-1>", wake)

    tick_count = [0]

    def keep_off_and_poll():
        if not os.path.exists(FLAG_PATH):
            wake()
            return
        mx, my = get_cursor_pos()
        if abs(mx - start_mx) > 25 or abs(my - start_my) > 25:
            wake()
            return
        hwnd = ctypes.windll.user32.GetParent(root.winfo_id()) or root.winfo_id()
        if tick_count[0] == 1 or tick_count[0] % 12 == 0:
            power_off_monitor_hardware(hwnd)
        tick_count[0] += 1
        root.after(400, keep_off_and_poll)

    root.after(250, keep_off_and_poll)
    root.mainloop()

if __name__ == '__main__':
    run_blanker()
