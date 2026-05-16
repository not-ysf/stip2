import struct, zlib, os, json
from PIL import Image

def make_plain_png(w, h, color=(30, 30, 30, 255)):
    def chunk(tag, data):
        crc = zlib.crc32(tag + data) & 0xffffffff
        return struct.pack('>I', len(data)) + tag + data + struct.pack('>I', crc)
    raw = b'\x89PNG\r\n\x1a\n'
    raw += chunk(b'IHDR', struct.pack('>IIBBBBB', w, h, 8, 6, 0, 0, 0))
    row = b'\x00' + bytes(color) * w
    raw += chunk(b'IDAT', zlib.compress(row * h, 9))
    raw += chunk(b'IEND', b'')
    return raw

def save_resized(src_img, path, size, rgb=False):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    resized = src_img.resize((size, size), Image.LANCZOS)
    if rgb:
        resized = resized.convert('RGB')
    resized.save(path, 'PNG')

# Load real logo from repo root
logo = Image.open('StipLogo.png').convert('RGBA')

# StipLogo imageset (1x / 2x / 3x)
logo_dir = 'Stip/Assets.xcassets/StipLogo.imageset'
os.makedirs(logo_dir, exist_ok=True)
save_resized(logo, f'{logo_dir}/StipLogo.png',    100)
save_resized(logo, f'{logo_dir}/StipLogo@2x.png', 200)
save_resized(logo, f'{logo_dir}/StipLogo@3x.png', 300)
with open(f'{logo_dir}/Contents.json', 'w') as f:
    json.dump({
        "images": [
            {"idiom": "universal", "filename": "StipLogo.png",    "scale": "1x"},
            {"idiom": "universal", "filename": "StipLogo@2x.png", "scale": "2x"},
            {"idiom": "universal", "filename": "StipLogo@3x.png", "scale": "3x"},
        ],
        "info": {"author": "xcode", "version": 1}
    }, f, indent=2)
print("StipLogo imageset done.")

# AppIcon appiconset
icon_dir = 'Stip/Assets.xcassets/AppIcon.appiconset'
os.makedirs(icon_dir, exist_ok=True)
specs = [
    (20,   'ipad',          '1x'),
    (20,   'ipad',          '2x'),
    (29,   'iphone',        '1x'),
    (29,   'iphone',        '2x'),
    (29,   'iphone',        '3x'),
    (40,   'iphone',        '2x'),
    (40,   'iphone',        '3x'),
    (60,   'iphone',        '2x'),
    (60,   'iphone',        '3x'),
    (76,   'ipad',          '1x'),
    (76,   'ipad',          '2x'),
    (83.5, 'ipad',          '2x'),
    (1024, 'ios-marketing', '1x'),
]
icons = []
for size, idiom, scale in specs:
    px = int(size * int(scale[0]))
    fname = f'icon_{px}.png'
    save_resized(logo, f'{icon_dir}/{fname}', px, rgb=True)
    icons.append({"size": f"{size}x{size}", "idiom": idiom, "filename": fname, "scale": scale})
with open(f'{icon_dir}/Contents.json', 'w') as f:
    json.dump({"images": icons, "info": {"author": "xcode", "version": 1}}, f, indent=2)
print("AppIcon appiconset done.")
print("All assets fixed!")
