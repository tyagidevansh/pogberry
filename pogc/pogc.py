import sys
import os
import subprocess

# --- Configuration ---
STUB_FILE = "pogc/stub.c"
POG_LIB_PATH = "lib"
# ---------------------

def compile_script(script_path):
    """
    Compiles a Pogberry script into a self-contained executable by
    embedding it into a C stub and linking against the Pogberry library.
    """
    if not os.path.exists(script_path):
        print(f"Error: File not found at '{script_path}'")
        return

    with open(script_path, 'r', encoding='utf-8') as f:
        script_content = f.read()

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

    base_name = os.path.splitext(os.path.basename(script_path))[0]
    
    compile_command = [
        "gcc", temp_c_file,
        "-o", 
    ]

    # OS-specific adjustments
    if sys.platform == "win32":
        print("Platform: Windows")
        output_name = base_name + ".exe"
        compile_command.append(output_name)
        compile_command.extend([f"-L{POG_LIB_PATH}", "-lpogberry"])
    elif sys.platform.startswith("linux"):
        print("Platform: Linux")
        output_name = base_name
        compile_command.append(output_name)
        # on Linux, we link the math library and set the rpath
        compile_command.extend([f"-L{POG_LIB_PATH}", "-lpogberry", "-lm", "-Wl,-rpath,."])
    else:
        print(f"Error: Unsupported platform '{sys.platform}'")
        os.remove(temp_c_file)
        return

    compile_command.append("-s")

    print(f"Compiling into: {output_name}...")
    
    result = subprocess.run(compile_command, capture_output=True, text=True)

    if result.returncode != 0:
        print("\nCompilation Failed!")
        print("--- GCC Error Output ---")
        print(result.stderr)
        print("------------------------")
    else:
        print(f"\nSuccess! Executable created: {output_name}")

    os.remove(temp_c_file)


if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: python pogc.py <your_script.pb>")
    else:
        compile_script(sys.argv[1])
