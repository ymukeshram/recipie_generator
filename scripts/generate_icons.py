import os
import numpy as np
from PIL import Image
import scipy.ndimage as ndi

def main():
    src_path = r'C:/Users/ymuke/.gemini/antigravity/brain/020f6b92-cc9d-4d4a-8a61-af6fd460ea8a/.user_uploaded/media_1791653596825_72076537.jpg'
    base_dir = r'C:/Users/ymuke/.gemini/antigravity/scratch/rasoiai'
    
    print("Loading source image:", src_path)
    src_rgb = Image.open(src_path).convert('RGB')
    arr_rgb = np.array(src_rgb)
    
    # 1. Generate Transparent Icon (RGBA 1024x1024)
    # Background outside the squircle is black (RGB < 15)
    rgb_max = np.maximum(np.maximum(arr_rgb[:, :, 0], arr_rgb[:, :, 1]), arr_rgb[:, :, 2])
    binary = rgb_max > 15
    filled = ndi.binary_fill_holes(binary)
    # Gaussian antialiasing for ultra-smooth edge
    smooth_alpha = ndi.gaussian_filter(filled.astype(float), sigma=0.8)
    alpha = (np.clip(smooth_alpha, 0, 1) * 255).astype(np.uint8)
    
    arr_rgba = np.dstack([arr_rgb, alpha])
    icon_transparent = Image.fromarray(arr_rgba, 'RGBA')
    
    # 2. Generate Opaque Icon with matching warm cream gradient in outer corners (RGB 1024x1024)
    gradient = np.zeros((1024, 1024, 3), dtype=np.float32)
    for y in range(1024):
        t = y / 1023.0
        # Interpolate between top cream [253, 250, 233] and bottom cream [251, 226, 188]
        r = 253.0 * (1 - t) + 251.0 * t
        g = 250.0 * (1 - t) + 226.0 * t
        b = 233.0 * (1 - t) + 188.0 * t
        gradient[y, :, :] = [r, g, b]
        
    smooth_mask_3d = smooth_alpha[:, :, np.newaxis]
    blended_rgb = arr_rgb.astype(np.float32) * smooth_mask_3d + gradient * (1.0 - smooth_mask_3d)
    blended_rgb = np.clip(blended_rgb, 0, 255).astype(np.uint8)
    icon_opaque = Image.fromarray(blended_rgb, 'RGB')
    
    # 3. Create assets/icons directory
    assets_icons_dir = os.path.join(base_dir, 'assets', 'icons')
    os.makedirs(assets_icons_dir, exist_ok=True)
    icon_transparent.save(os.path.join(assets_icons_dir, 'app_icon.png'), 'PNG')
    icon_opaque.save(os.path.join(assets_icons_dir, 'app_icon_opaque.png'), 'PNG')
    print("Saved master icons in assets/icons/")
    
    # 4. Generate Android Icons
    # Standard mipmap sizes
    android_sizes = {
        'mdpi': 48,
        'hdpi': 72,
        'xhdpi': 96,
        'xxhdpi': 144,
        'xxxhdpi': 192,
    }
    res_dir = os.path.join(base_dir, 'android', 'app', 'src', 'main', 'res')
    for density, size in android_sizes.items():
        folder = os.path.join(res_dir, f'mipmap-{density}')
        os.makedirs(folder, exist_ok=True)
        # Resize transparent icon with Lanczos filter
        resized = icon_transparent.resize((size, size), Image.Resampling.LANCZOS)
        resized.save(os.path.join(folder, 'ic_launcher.png'), 'PNG')
        print(f"Android mipmap-{density}/ic_launcher.png ({size}x{size}) saved")

    # Android Adaptive Foreground (108dp canvas, safe zone 72dp)
    # densities: mdpi: 108, hdpi: 162, xhdpi: 216, xxhdpi: 324, xxxhdpi: 432
    adaptive_sizes = {
        'mdpi': 108,
        'hdpi': 162,
        'xhdpi': 216,
        'xxhdpi': 324,
        'xxxhdpi': 432,
    }
    for density, canvas_size in adaptive_sizes.items():
        folder = os.path.join(res_dir, f'mipmap-{density}')
        # Sized to ~68% of canvas to fit comfortably inside the 72dp safe zone circle
        content_size = int(canvas_size * 0.68)
        content_resized = icon_transparent.resize((content_size, content_size), Image.Resampling.LANCZOS)
        fg_canvas = Image.new('RGBA', (canvas_size, canvas_size), (0, 0, 0, 0))
        offset = (canvas_size - content_size) // 2
        fg_canvas.paste(content_resized, (offset, offset), content_resized)
        fg_canvas.save(os.path.join(folder, 'ic_launcher_foreground.png'), 'PNG')
        print(f"Android mipmap-{density}/ic_launcher_foreground.png ({canvas_size}x{canvas_size}) saved")
        
    # Android Adaptive anydpi-v26 xml
    anydpi_dir = os.path.join(res_dir, 'mipmap-anydpi-v26')
    os.makedirs(anydpi_dir, exist_ok=True)
    
    adaptive_xml = '''<?xml version="1.0" encoding="utf-8"?>
<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">
    <background android:drawable="@color/ic_launcher_background" />
    <foreground android:drawable="@mipmap/ic_launcher_foreground" />
</adaptive-icon>
'''
    with open(os.path.join(anydpi_dir, 'ic_launcher.xml'), 'w', encoding='utf-8') as f:
        f.write(adaptive_xml)
    with open(os.path.join(anydpi_dir, 'ic_launcher_round.xml'), 'w', encoding='utf-8') as f:
        f.write(adaptive_xml)
    print("Android mipmap-anydpi-v26 XMLs created")

    # Android color values
    values_dir = os.path.join(res_dir, 'values')
    os.makedirs(values_dir, exist_ok=True)
    colors_xml_path = os.path.join(values_dir, 'colors.xml')
    # If colors.xml exists, check or write
    color_content = '''<?xml version="1.0" encoding="utf-8"?>
<resources>
    <color name="ic_launcher_background">#FFF8EE</color>
</resources>
'''
    with open(colors_xml_path, 'w', encoding='utf-8') as f:
        f.write(color_content)
    print("Android values/colors.xml saved")

    # 5. Generate Web Icons
    web_dir = os.path.join(base_dir, 'web')
    web_icons_dir = os.path.join(web_dir, 'icons')
    os.makedirs(web_icons_dir, exist_ok=True)
    
    # Favicon 32x32 & 16x16
    favicon = icon_transparent.resize((32, 32), Image.Resampling.LANCZOS)
    favicon.save(os.path.join(web_dir, 'favicon.png'), 'PNG')
    print("web/favicon.png (32x32) saved")

    # Icon-192 & Icon-512
    icon_192 = icon_transparent.resize((192, 192), Image.Resampling.LANCZOS)
    icon_192.save(os.path.join(web_icons_dir, 'Icon-192.png'), 'PNG')
    
    icon_512 = icon_transparent.resize((512, 512), Image.Resampling.LANCZOS)
    icon_512.save(os.path.join(web_icons_dir, 'Icon-512.png'), 'PNG')
    print("web/icons/Icon-192.png and Icon-512.png saved")

    # Maskable PWA icons (with cream background and safe zone padding)
    for m_size in [192, 512]:
        inner_size = int(m_size * 0.76)
        inner_img = icon_transparent.resize((inner_size, inner_size), Image.Resampling.LANCZOS)
        # Background color #FFF8EE = (255, 248, 238)
        maskable_canvas = Image.new('RGB', (m_size, m_size), (255, 248, 238))
        offset = (m_size - inner_size) // 2
        maskable_canvas.paste(inner_img, (offset, offset), inner_img)
        maskable_canvas.save(os.path.join(web_icons_dir, f'Icon-maskable-{m_size}.png'), 'PNG')
        print(f"web/icons/Icon-maskable-{m_size}.png ({m_size}x{m_size}) saved")

    # 6. Generate iOS Icons
    ios_appicon_dir = os.path.join(base_dir, 'ios', 'Runner', 'Assets.xcassets', 'AppIcon.appiconset')
    if os.path.exists(ios_appicon_dir):
        ios_files = [
            ('Icon-App-20x20@1x.png', 20),
            ('Icon-App-20x20@2x.png', 40),
            ('Icon-App-20x20@3x.png', 60),
            ('Icon-App-29x29@1x.png', 29),
            ('Icon-App-29x29@2x.png', 58),
            ('Icon-App-29x29@3x.png', 87),
            ('Icon-App-40x40@1x.png', 40),
            ('Icon-App-40x40@2x.png', 80),
            ('Icon-App-40x40@3x.png', 120),
            ('Icon-App-60x60@2x.png', 120),
            ('Icon-App-60x60@3x.png', 180),
            ('Icon-App-76x76@1x.png', 76),
            ('Icon-App-76x76@2x.png', 152),
            ('Icon-App-83.5x83.5@2x.png', 167),
            ('Icon-App-1024x1024@1x.png', 1024),
        ]
        for fname, sz in ios_files:
            resized_ios = icon_opaque.resize((sz, sz), Image.Resampling.LANCZOS)
            resized_ios.save(os.path.join(ios_appicon_dir, fname), 'PNG')
        print("All iOS AppIcon files updated successfully")

    # 7. Generate macOS Icons
    macos_appicon_dir = os.path.join(base_dir, 'macos', 'Runner', 'Assets.xcassets', 'AppIcon.appiconset')
    if os.path.exists(macos_appicon_dir):
        macos_files = [
            ('app_icon_16.png', 16),
            ('app_icon_32.png', 32),
            ('app_icon_64.png', 64),
            ('app_icon_128.png', 128),
            ('app_icon_256.png', 256),
            ('app_icon_512.png', 512),
            ('app_icon_1024.png', 1024),
        ]
        for fname, sz in macos_files:
            resized_mac = icon_transparent.resize((sz, sz), Image.Resampling.LANCZOS)
            resized_mac.save(os.path.join(macos_appicon_dir, fname), 'PNG')
        print("All macOS AppIcon files updated successfully")

    # 8. Generate Windows ICO
    windows_icon_path = os.path.join(base_dir, 'windows', 'runner', 'resources', 'app_icon.ico')
    if os.path.exists(os.path.dirname(windows_icon_path)):
        ico_sizes = [(16, 16), (32, 32), (48, 48), (64, 64), (128, 128), (256, 256)]
        icon_transparent.save(windows_icon_path, format='ICO', sizes=ico_sizes)
        print("windows/runner/resources/app_icon.ico updated successfully")

    print("ALL APP ICON ASSETS GENERATED SUCCESSFULLY!")

if __name__ == '__main__':
    main()
