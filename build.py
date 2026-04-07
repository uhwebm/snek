import os
import subprocess
import sys

OUT_DIR = "out"

TARGETS = {
    "windows": "windows_amd64",
    "linux": "linux_amd64",
    "macos_intel": "darwin_amd64",
    "macos_arm": "darwin_arm64"
}

OUTPUT_NAMES = {
    "windows": "snek.exe",
    "linux": "snek_linux",
    "macos_intel": "snek_macos_intel",
    "macos_arm": "snek_macos_arm"
}

def run(cmd):
    print(">>", " ".join(cmd))
    result = subprocess.run(cmd)
    if result.returncode != 0:
        print("build failed")
        sys.exit(result.returncode)

os.makedirs(OUT_DIR, exist_ok=True)

for platform, target in TARGETS.items():
    out_path = os.path.join(OUT_DIR, OUTPUT_NAMES[platform])

    cmd = [
        "odin",
        "build",
        "source",
        f"-target:{target}",
        f"-out:{out_path}",
    ]

    print(f"\nbuilding for {platform}")
    run(cmd)
    
print("\nbuilds complete!")