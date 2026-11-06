#!/usr/bin/env python3
"""
Generate 4 separate authentic F1 car models with dedicated liveries and textures:
- car_ferrari.obj / car_ferrari.mtl -> Textures/colormap_ferrari.png
- car_redbull.obj / car_redbull.mtl -> Textures/colormap_redbull.png
- car_mercedes.obj / car_mercedes.mtl -> Textures/colormap_mercedes.png
- car_mclaren.obj / car_mclaren.mtl -> Textures/colormap_mclaren.png
"""

import os
import struct
import zlib

def decode_png(path):
    with open(path, "rb") as f:
        data = f.read()
    idx = 8
    idat = bytearray()
    width = height = None
    while idx < len(data):
        length, chunk_type = struct.unpack(">I4s", data[idx:idx+8])
        chunk_data = data[idx+8:idx+8+length]
        idx += 12 + length
        if chunk_type == b"IHDR":
            width, height, bit_depth, color_type = struct.unpack(">IIBB", chunk_data[:10])
        elif chunk_type == b"IDAT":
            idat.extend(chunk_data)
        elif chunk_type == b"IEND":
            break
    raw = zlib.decompress(idat)
    bpp = 4
    stride = width * bpp
    pixels = []
    prev_row = bytearray(stride)
    raw_idx = 0
    for y in range(height):
        filter_type = raw[raw_idx]
        raw_idx += 1
        row = bytearray(raw[raw_idx:raw_idx+stride])
        raw_idx += stride
        if filter_type == 1:
            for i in range(bpp, stride):
                row[i] = (row[i] + row[i - bpp]) & 0xff
        elif filter_type == 2:
            for i in range(stride):
                row[i] = (row[i] + prev_row[i]) & 0xff
        elif filter_type == 3:
            for i in range(stride):
                left = row[i - bpp] if i >= bpp else 0
                row[i] = (row[i] + ((left + prev_row[i]) >> 1)) & 0xff
        elif filter_type == 4:
            for i in range(stride):
                a = row[i - bpp] if i >= bpp else 0
                b = prev_row[i]
                c = prev_row[i - bpp] if i >= bpp else 0
                p = a + b - c
                pa, pb, pc = abs(p - a), abs(p - b), abs(p - c)
                pr = a if pa <= pb and pa <= pc else (b if pb <= pc else c)
                row[i] = (row[i] + pr) & 0xff
        pixels.append(row)
        prev_row = row
    return width, height, pixels

def encode_png(width, height, pixels):
    raw = bytearray()
    stride = width * 4
    for y in range(height):
        raw.append(0)
        raw.extend(pixels[y])
    compressed = zlib.compress(bytes(raw), level=9)
    ihdr = struct.pack(">IIBBBBB", width, height, 8, 6, 0, 0, 0)
    ihdr_crc = struct.pack(">I", zlib.crc32(b"IHDR" + ihdr))
    idat_len = struct.pack(">I", len(compressed))
    idat_crc = struct.pack(">I", zlib.crc32(b"IDAT" + compressed))
    iend = b"\x00\x00\x00\x00IEND\xaeB`\x82"
    return b"\x89PNG\r\n\x1a\n\x00\x00\x00\x0dIHDR" + ihdr + ihdr_crc + idat_len + b"IDAT" + compressed + idat_crc + iend

def set_pixel_block(pixels, block_idx, y_start, y_end, r, g, b, a=255):
    x_start = block_idx * 32
    x_end = (block_idx + 1) * 32
    for y in range(max(0, y_start), min(len(pixels), y_end)):
        row = pixels[y]
        for x in range(x_start, x_end):
            idx = x * 4
            row[idx] = r
            row[idx + 1] = g
            row[idx + 2] = b
            row[idx + 3] = a

def copy_pixels(pixels):
    return [bytearray(row) for row in pixels]

def build_textures(base_texture_path, out_dir, textures_dir):
    w, h, base_pixels = decode_png(base_texture_path)

    # 1. Ferrari Texture
    px_ferrari = copy_pixels(base_pixels)
    # Body livery: Column 432 (block 13) and Column 496 (block 15)
    for b_idx in (13, 15):
        set_pixel_block(px_ferrari, b_idx, 0, 512, 215, 0, 0) # Base Rosso Corsa F1 Red
        set_pixel_block(px_ferrari, b_idx, 140, 144, 255, 215, 0) # Roll hoop Modena yellow
        set_pixel_block(px_ferrari, b_idx, 144, 150, 215, 0, 0)
        set_pixel_block(px_ferrari, b_idx, 154, 158, 255, 255, 255) # Rear wing white stripe
        set_pixel_block(px_ferrari, b_idx, 163, 166, 255, 255, 255) # Shark fin white stripe
        set_pixel_block(px_ferrari, b_idx, 167, 170, 255, 215, 0)   # Shark fin yellow stripe
        set_pixel_block(px_ferrari, b_idx, 194, 198, 255, 215, 0)   # Mid-sidepod yellow pinstripe
        set_pixel_block(px_ferrari, b_idx, 203, 207, 255, 255, 255) # Nose white racing pinstripe
        set_pixel_block(px_ferrari, b_idx, 215, 218, 255, 215, 0)   # Nose yellow pinstripe
        set_pixel_block(px_ferrari, b_idx, 226, 229, 255, 255, 255) # Front wing white leading edge
        set_pixel_block(px_ferrari, b_idx, 240, 246, 255, 215, 0)   # Front wingtip yellow accent
        set_pixel_block(px_ferrari, b_idx, 305, 330, 24, 24, 28)    # Sidepod radiator black
    # Tires: Column 176 (block 5)
    set_pixel_block(px_ferrari, 5, 260, 385, 28, 28, 32) # Jet black Pirelli P-Zero
    set_pixel_block(px_ferrari, 5, 298, 305, 220, 20, 25) # Pirelli P-Zero Red soft compound
    # Rims: Column 304 (block 9)
    set_pixel_block(px_ferrari, 9, 150, 238, 235, 195, 20) # Yellow BBS rims
    set_pixel_block(px_ferrari, 9, 185, 193, 30, 30, 35)   # BBS black inner spoke
    set_pixel_block(px_ferrari, 9, 239, 252, 20, 20, 24)   # BBS black center lock hub
    # Helmet: Column 48 (block 1)
    set_pixel_block(px_ferrari, 1, 400, 424, 215, 10, 15)  # Charles Leclerc red crown
    set_pixel_block(px_ferrari, 1, 424, 428, 20, 20, 25)   # Visor band
    set_pixel_block(px_ferrari, 1, 428, 450, 250, 250, 255) # White base and chin

    # 2. Red Bull Texture
    px_redbull = copy_pixels(base_pixels)
    for b_idx in (13, 15):
        set_pixel_block(px_redbull, b_idx, 0, 512, 12, 28, 58) # Matte Navy Blue
        set_pixel_block(px_redbull, b_idx, 140, 145, 255, 210, 0) # Roll hoop yellow
        set_pixel_block(px_redbull, b_idx, 145, 152, 225, 20, 30) # Airbox red
        set_pixel_block(px_redbull, b_idx, 153, 158, 225, 20, 30) # Rear wing DRS red
        set_pixel_block(px_redbull, b_idx, 162, 172, 225, 20, 30) # Engine fin Red Bull red
        set_pixel_block(px_redbull, b_idx, 172, 176, 255, 210, 0) # Yellow bull sun halo
        set_pixel_block(px_redbull, b_idx, 193, 199, 225, 20, 30) # Sidepod red highlight
        set_pixel_block(px_redbull, b_idx, 201, 219, 255, 210, 0) # Vibrant yellow nose ring
        set_pixel_block(px_redbull, b_idx, 210, 214, 225, 20, 30) # Nose bull red horns
        set_pixel_block(px_redbull, b_idx, 225, 230, 255, 210, 0) # Front wing yellow tip
        set_pixel_block(px_redbull, b_idx, 240, 246, 225, 20, 30) # Front wing red cascades
        set_pixel_block(px_redbull, b_idx, 305, 330, 15, 18, 25)  # Diffuser carbon black
    set_pixel_block(px_redbull, 5, 260, 385, 28, 28, 32) # Black Pirelli tires
    set_pixel_block(px_redbull, 5, 298, 305, 255, 210, 0) # Pirelli Yellow medium compound
    set_pixel_block(px_redbull, 9, 150, 238, 255, 210, 0) # Red Bull yellow wheel caps
    set_pixel_block(px_redbull, 9, 185, 193, 12, 28, 58)  # Navy inner wheel rim
    set_pixel_block(px_redbull, 9, 239, 252, 15, 25, 45)  # Dark navy hub
    set_pixel_block(px_redbull, 1, 400, 424, 255, 95, 0)  # Max Verstappen orange crown
    set_pixel_block(px_redbull, 1, 424, 428, 15, 18, 28)  # Visor
    set_pixel_block(px_redbull, 1, 428, 450, 12, 28, 58)  # Dark navy chin

    # 3. Mercedes Texture
    px_mercedes = copy_pixels(base_pixels)
    for b_idx in (13, 15):
        set_pixel_block(px_mercedes, b_idx, 0, 512, 215, 220, 225) # Silver Arrow metallic silver
        set_pixel_block(px_mercedes, b_idx, 140, 152, 20, 20, 24)  # Carbon black roll hoop
        set_pixel_block(px_mercedes, b_idx, 143, 146, 0, 162, 155)  # Petronas teal ring
        set_pixel_block(px_mercedes, b_idx, 153, 160, 20, 20, 24)  # Carbon black rear wing
        set_pixel_block(px_mercedes, b_idx, 155, 158, 0, 162, 155)  # Petronas teal DRS flap
        set_pixel_block(px_mercedes, b_idx, 161, 175, 20, 20, 24)  # Engine cover fading to black
        set_pixel_block(px_mercedes, b_idx, 168, 172, 0, 162, 155)  # Petronas teal star flow
        set_pixel_block(px_mercedes, b_idx, 182, 188, 0, 162, 155)  # Petronas emerald teal stripe
        set_pixel_block(px_mercedes, b_idx, 193, 198, 0, 162, 155)  # Sidepod teal streak
        set_pixel_block(px_mercedes, b_idx, 201, 220, 215, 220, 225) # Silver nose cone
        set_pixel_block(px_mercedes, b_idx, 213, 217, 0, 162, 155)  # Teal nose dual stripe
        set_pixel_block(px_mercedes, b_idx, 225, 235, 20, 20, 24)   # Front wing carbon base
        set_pixel_block(px_mercedes, b_idx, 236, 246, 0, 162, 155)  # Front wing teal tips
        set_pixel_block(px_mercedes, b_idx, 305, 330, 18, 18, 22)   # Floor carbon black
    set_pixel_block(px_mercedes, 5, 260, 385, 28, 28, 32) # Black Pirelli tires
    set_pixel_block(px_mercedes, 5, 298, 305, 235, 240, 245) # Pirelli White hard compound
    set_pixel_block(px_mercedes, 9, 150, 238, 0, 162, 155) # Petronas Teal wheel rim rings
    set_pixel_block(px_mercedes, 9, 185, 193, 195, 200, 208) # Silver forged spoke
    set_pixel_block(px_mercedes, 9, 239, 252, 30, 32, 38)   # Titanium hub
    set_pixel_block(px_mercedes, 1, 400, 424, 225, 255, 0)  # Lewis Hamilton neon yellow crown
    set_pixel_block(px_mercedes, 1, 424, 428, 60, 15, 90)   # Purple visor
    set_pixel_block(px_mercedes, 1, 428, 450, 80, 20, 120)  # Deep purple chin

    # 4. McLaren Texture
    px_mclaren = copy_pixels(base_pixels)
    for b_idx in (13, 15):
        set_pixel_block(px_mclaren, b_idx, 0, 512, 255, 128, 0) # Papaya Orange body
        set_pixel_block(px_mclaren, b_idx, 140, 145, 40, 180, 255) # Roll hoop light blue
        set_pixel_block(px_mclaren, b_idx, 153, 160, 22, 22, 26)  # Rear wing carbon black
        set_pixel_block(px_mclaren, b_idx, 155, 158, 40, 180, 255) # Light blue winglet
        set_pixel_block(px_mclaren, b_idx, 163, 175, 22, 22, 26)  # Engine fin anthracite inlay
        set_pixel_block(px_mclaren, b_idx, 178, 189, 22, 22, 26)  # Sidepod inlays carbon black
        set_pixel_block(px_mclaren, b_idx, 184, 187, 40, 180, 255) # Light blue accent stripe
        set_pixel_block(px_mclaren, b_idx, 193, 198, 40, 180, 255) # Mid-sidepod light blue streak
        set_pixel_block(px_mclaren, b_idx, 201, 220, 255, 128, 0) # Papaya nose cone
        set_pixel_block(px_mclaren, b_idx, 212, 216, 40, 180, 255) # Nose light blue pinstripe
        set_pixel_block(px_mclaren, b_idx, 225, 235, 22, 22, 26)   # Front wing carbon plane
        set_pixel_block(px_mclaren, b_idx, 236, 246, 40, 180, 255) # Light blue wing endplate
        set_pixel_block(px_mclaren, b_idx, 305, 330, 22, 22, 26)   # Diffuser anthracite carbon
    set_pixel_block(px_mclaren, 5, 260, 385, 28, 28, 32) # Black Pirelli tires
    set_pixel_block(px_mclaren, 5, 298, 305, 230, 30, 20) # Pirelli Red soft compound
    set_pixel_block(px_mclaren, 9, 150, 238, 255, 165, 0) # Neon wheel cover accents
    set_pixel_block(px_mclaren, 9, 185, 193, 25, 25, 30)  # Anthracite wheel cover disc
    set_pixel_block(px_mclaren, 9, 239, 252, 255, 175, 0) # Neon orange hub ring
    set_pixel_block(px_mclaren, 1, 400, 424, 220, 255, 10) # Lando Norris neon yellow crown
    set_pixel_block(px_mclaren, 1, 424, 428, 18, 18, 22)   # Dark carbon visor
    set_pixel_block(px_mclaren, 1, 428, 450, 20, 20, 24)   # Jet black chin

    textures = {
        "colormap_ferrari.png": px_ferrari,
        "colormap_redbull.png": px_redbull,
        "colormap_mercedes.png": px_mercedes,
        "colormap_mclaren.png": px_mclaren,
    }

    for name, px in textures.items():
        encoded = encode_png(w, h, px)
        # Write to Textures/
        t_path = os.path.join(textures_dir, name)
        with open(t_path, "wb") as f:
            f.write(encoded)
        print(f"Wrote {t_path} ({len(encoded)} bytes)")
        # Also write to models/ root
        m_path = os.path.join(out_dir, name)
        with open(m_path, "wb") as f:
            f.write(encoded)
        print(f"Wrote {m_path} ({len(encoded)} bytes)")

def build_models(base_obj_path, out_dir):
    with open(base_obj_path, "r") as f:
        lines = f.readlines()

    teams = {
        "ferrari": {
            "mtl": "car_ferrari.mtl",
            "tex": "colormap_ferrari.png",
            # Ferrari SF-24: Sculpted undercut sidepods, wide front wing endplates, elevated DRS rear wing
            "mod_v": lambda x, y, z, g: (
                x * (1.06 if g == "body" and abs(x) > 0.25 and -0.4 < z < 0.3 else 1.0),
                y * (1.05 if g == "body" and z < -1.1 and y > 0.5 else (1.02 if g == "body" and z > 0.6 else 1.0)),
                z
            )
        },
        "redbull": {
            "mtl": "car_redbull.mtl",
            "tex": "colormap_redbull.png",
            # Red Bull RB-20: High rake stance, aggressive nose scoop, tall shark fin engine cover
            "mod_v": lambda x, y, z, g: (
                x * (0.92 if g == "body" and abs(x) > 0.22 and y < 0.4 and -0.4 < z < 0.3 else 1.0),
                y * (1.08 if g == "body" and -0.9 < z < -0.2 and y > 0.55 else (1.04 if g == "body" and z < -0.8 else 0.98 if g == "body" and z > 0.8 else 1.0)),
                z
            )
        },
        "mercedes": {
            "mtl": "car_mercedes.mtl",
            "tex": "colormap_mercedes.png",
            # Mercedes W15: Sleek elongated arrow nose cone, slim zeropod silhouette, low drag beam wing
            "mod_v": lambda x, y, z, g: (
                x * (0.90 if g == "body" and abs(x) > 0.20 and -0.3 < z < 0.3 else 1.0),
                y * (0.96 if g == "body" and z < -1.0 else 1.0),
                z * (1.04 if g == "body" and z > 0.4 else 1.0)
            )
        },
        "mclaren": {
            "mtl": "car_mclaren.mtl",
            "tex": "colormap_mclaren.png",
            # McLaren MCL38: High-downforce dual-plane front cascades, gull-wing sidepod inlet ramps, flared rear diffuser
            "mod_v": lambda x, y, z, g: (
                x * (1.05 if g == "body" and z < -0.8 and y < 0.25 else (0.95 if g == "body" and -0.4 < z < 0.3 and abs(x) > 0.2 else 1.0)),
                y * (1.04 if g == "body" and z > 0.8 else 1.0),
                z
            )
        }
    }

    for team, cfg in teams.items():
        # Write MTL
        mtl_path = os.path.join(out_dir, cfg["mtl"])
        mtl_content = f"# Dedicated authentic F1 material for {team.upper()}\nnewmtl colormap\nKd 1 1 1\nmap_Kd Textures/{cfg['tex']}\n"
        with open(mtl_path, "w") as f:
            f.write(mtl_content)
        print(f"Wrote {mtl_path}")

        # Write OBJ with team aerodynamic adjustments
        obj_path = os.path.join(out_dir, f"car_{team}.obj")
        new_lines = []
        cur_g = ""
        for line in lines:
            if line.startswith("mtllib "):
                new_lines.append(f"mtllib {cfg['mtl']}\n")
            elif line.startswith("g "):
                parts = line.strip().split()
                cur_g = parts[1] if len(parts) > 1 else ""
                new_lines.append(line)
            elif line.startswith("v "):
                parts = line.strip().split()
                vx = float(parts[1])
                vy = float(parts[2])
                vz = float(parts[3])
                nx, ny, nz = cfg["mod_v"](vx, vy, vz, cur_g)
                # preserve any trailing color values if present
                trailing = " " + " ".join(parts[4:]) if len(parts) > 4 else ""
                new_lines.append(f"v {nx:.6f} {ny:.6f} {nz:.6f}{trailing}\n")
            else:
                new_lines.append(line)

        with open(obj_path, "w") as f:
            f.writelines(new_lines)
        print(f"Wrote {obj_path} ({len(new_lines)} lines)")

def main():
    base_dir = os.path.dirname(os.path.abspath(__file__))
    models_dir = os.path.join(base_dir, "assets", "models")
    textures_dir = os.path.join(models_dir, "Textures")
    base_texture = os.path.join(textures_dir, "colormap.png")
    base_obj = os.path.join(models_dir, "race.obj")

    print(f"Generating authentic textures from {base_texture}...")
    build_textures(base_texture, models_dir, textures_dir)

    print(f"Generating authentic 3D models from {base_obj}...")
    build_models(base_obj, models_dir)
    print("Done generating 4 dedicated F1 car models and textures!")

if __name__ == "__main__":
    main()
