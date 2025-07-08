import subprocess
import sys
import os
from pathlib import Path

main_python_scr_dir = os.path.dirname(os.path.abspath(__file__))

welcome_message_file_dir = os.path.join(main_python_scr_dir, "src", "cpp-src", "printLogoConsole.cpp")

welcome_message_bin_dir = os.path.join(main_python_scr_dir, "src", "cpp-src", "output_bin")

welcome_message_bin = "output_bin.exe"


compile_cmd = ["g++", welcome_message_file_dir, "-o", "output_bin"]

try:
    subprocess.run(
        compile_cmd,
        check=True, 
        capture_output=True,
        text=True
    )
except subprocess.CalledProcessError as e:
    print("Compile ERROR!:")
    print(welcome_message_bin_dir,welcome_message_file_dir)
    print(e.stderr)
    exit(1)

if os.path.exists(welcome_message_bin):
    try:
        result = subprocess.run(
            ["output_bin.exe"],
            capture_output=True,
            text=True
        )
        print(result.stdout)
    except Exception as e:
        print(f"Running ERROR: {e}")
else:
    print("where")
    print(welcome_message_bin)