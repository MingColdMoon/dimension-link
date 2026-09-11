"""把主图标缩放到各平台所需尺寸。"""
from __future__ import annotations

from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
SRC = ROOT / "assets" / "images" / "app_icon.png"


def save_png(image: Image.Image, dest: Path, size: int) -> None:
    dest.parent.mkdir(parents=True, exist_ok=True)
    resized = image.resize((size, size), Image.Resampling.LANCZOS)
    resized.save(dest, format="PNG")


def main() -> None:
    master = Image.open(SRC).convert("RGBA")
    android = {
        "mipmap-mdpi": 48,
        "mipmap-hdpi": 72,
        "mipmap-xhdpi": 96,
        "mipmap-xxhdpi": 144,
        "mipmap-xxxhdpi": 192,
    }
    for folder, size in android.items():
        save_png(master, ROOT / "android" / "app" / "src" / "main" / "res" / folder / "ic_launcher.png", size)

    ios = ROOT / "ios" / "Runner" / "Assets.xcassets" / "AppIcon.appiconset"
    for name, size in {
        "Icon-App-20x20@1x.png": 20,
        "Icon-App-20x20@2x.png": 40,
        "Icon-App-20x20@3x.png": 60,
        "Icon-App-29x29@1x.png": 29,
        "Icon-App-29x29@2x.png": 58,
        "Icon-App-29x29@3x.png": 87,
        "Icon-App-40x40@1x.png": 40,
        "Icon-App-40x40@2x.png": 80,
        "Icon-App-40x40@3x.png": 120,
        "Icon-App-60x60@2x.png": 120,
        "Icon-App-60x60@3x.png": 180,
        "Icon-App-76x76@1x.png": 76,
        "Icon-App-76x76@2x.png": 152,
        "Icon-App-83.5x83.5@2x.png": 167,
        "Icon-App-1024x1024@1x.png": 1024,
    }.items():
        save_png(master, ios / name, size)

    macos = ROOT / "macos" / "Runner" / "Assets.xcassets" / "AppIcon.appiconset"
    for size in (16, 32, 64, 128, 256, 512, 1024):
        save_png(master, macos / f"app_icon_{size}.png", size)

    web = ROOT / "web"
    save_png(master, web / "favicon.png", 32)
    save_png(master, web / "icons" / "Icon-192.png", 192)
    save_png(master, web / "icons" / "Icon-512.png", 512)
    save_png(master, web / "icons" / "Icon-maskable-192.png", 192)
    save_png(master, web / "icons" / "Icon-maskable-512.png", 512)

    ico_sizes = [(16, 16), (32, 32), (48, 48), (256, 256)]
    dest_ico = ROOT / "windows" / "runner" / "resources" / "app_icon.ico"
    dest_ico.parent.mkdir(parents=True, exist_ok=True)
    master.save(dest_ico, format="ICO", sizes=ico_sizes)
    print(f"已写入各平台图标，源文件 {SRC}")


if __name__ == "__main__":
    main()
