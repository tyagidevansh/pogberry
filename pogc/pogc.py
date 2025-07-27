import sys
import os
import subprocess

# --- Configuration ---
STUB_FILE = "stub.c"
POG_LIB_PATH = "."
# ---------------------

def compile_script(script_path):
    if not os.path.exists(script_path):
        print(f"Error: File not found at '{script_path}'")
        return

    with open(script_path, 'r', encoding='utf-8') as f:
        script_content = f.read()


    c_string = '"' + script_content.replace('\\', '\\\\').replace('"', '\\"') + '"'
    lines = script_content.splitlines()
    c_string_lines = ['"' + line.replace('\\', '\\\\').replace('"', '\\"') + '\\n"' for line in lines]    
    formatted_script = '\n'.join(c_string_lines)
    
    with open(STUB_FILE, 'r', encoding='utf-8') as f:
        stub_content = f.read()

    final_c_code = stub_content.replace(
        '"/* SCRIPT_CONTENT_HERE */"', formatted_script
    )

    temp_c_file = "temp_app.c"
    with open(temp_c_file, 'w', encoding='utf-8') as f:
        f.write(final_c_code)

    output_name = os.path.splitext(os.path.basename(script_path))[0] + ".exe"
    print(f"Compiling {script_path} into {output_name}...")
    compile_command = [
        "gcc", temp_c_file,
        "-o", output_name,
        f"-L{POG_LIB_PATH}",
        "-lpogberry",
        "-s"
    ]
    
    result = subprocess.run(compile_command, capture_output=True, text=True)

    if result.returncode != 0:
        print("Compilation Failed!")
        print(result.stderr)
    else:
        print(f"Success! Executable created: {output_name}")

    os.remove(temp_c_file)


if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: python pogc.py <your_script.pb>")
    else:
        compile_script(sys.argv[1])