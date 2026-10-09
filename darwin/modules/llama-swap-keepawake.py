"""Keeps the Mac in full wake while llama-swap serves requests.

A network wake is a dark wake that powerd ends after ~45s regardless of open
connections, and Metal work needs full wake, so declare remote user activity
(IOPMAssertionDeclareUserActivity, kIOPMUserActiveRemote) while busy.
"""

import ctypes
import json
import sys
import time
import urllib.request

LLAMA_SWAP = sys.argv[1]
API_KEY_FILE = sys.argv[2] if len(sys.argv) > 2 else None
POLL_SECONDS = 5
kIOPMUserActiveRemote = 1
kCFStringEncodingUTF8 = 0x08000100

cf = ctypes.cdll.LoadLibrary("/System/Library/Frameworks/CoreFoundation.framework/CoreFoundation")
iokit = ctypes.cdll.LoadLibrary("/System/Library/Frameworks/IOKit.framework/IOKit")
cf.CFStringCreateWithCString.restype = ctypes.c_void_p
cf.CFStringCreateWithCString.argtypes = [ctypes.c_void_p, ctypes.c_char_p, ctypes.c_uint32]
iokit.IOPMAssertionDeclareUserActivity.argtypes = [ctypes.c_void_p, ctypes.c_int, ctypes.POINTER(ctypes.c_uint32)]
iokit.IOPMAssertionDeclareUserActivity.restype = ctypes.c_int
name = cf.CFStringCreateWithCString(None, b"llama-swap serving a remote request", kCFStringEncodingUTF8)
assertion = ctypes.c_uint32(0)


def busy():
    headers = {}
    if API_KEY_FILE:
        with open(API_KEY_FILE) as key:
            headers["Authorization"] = "Bearer " + key.read().strip()
    # The event stream opens with a snapshot of the in-flight requests, which
    # include ones waiting on a model to load.
    request = urllib.request.Request(LLAMA_SWAP + "/api/events", headers=headers)
    with urllib.request.urlopen(request, timeout=3) as response:
        for line in response:
            if line.startswith(b"data:"):
                message = json.loads(line[5:])
                if message["type"] == "inflight":
                    return len(json.loads(message["data"]).get("requests", [])) > 0
    raise RuntimeError("event stream ended before the in-flight snapshot")


was_busy = False
while True:
    try:
        now_busy = busy()
    except Exception as error:
        now_busy = False
        print(time.strftime("%F %T"), "poll failed:", error, flush=True)
    if now_busy:
        rc = iokit.IOPMAssertionDeclareUserActivity(name, kIOPMUserActiveRemote, ctypes.byref(assertion))
        if rc != 0:
            print(time.strftime("%F %T"), "declaring activity failed:", rc, flush=True)
    if now_busy != was_busy:
        print(time.strftime("%F %T"), "busy" if now_busy else "idle", flush=True)
        was_busy = now_busy
    time.sleep(POLL_SECONDS)
