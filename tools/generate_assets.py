#!/usr/bin/env python3
"""Genera los recursos de los mundos (panoramas 360° y sonido del espacio).

Todo se crea por código para este proyecto, así que es dominio público (CC0).
Uso: python3 tools/generate_assets.py   (necesita numpy y Pillow)
"""
import os
import wave

import numpy as np
from PIL import Image

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
W, H = 4096, 2048


def directions(w, h):
    """Vector unitario de cada píxel de un panorama equirectangular (Y arriba)."""
    lon = (np.arange(w) + 0.5) / w * 2 * np.pi - np.pi
    lat = np.pi / 2 - (np.arange(h) + 0.5) / h * np.pi
    lon, lat = np.meshgrid(lon, lat)
    x = np.cos(lat) * np.sin(lon)
    y = np.sin(lat)
    z = -np.cos(lat) * np.cos(lon)
    return x, y, z, lat, lon


def sphere_noise(x, y, z, rng, octaves=6, base=2.0):
    """Ruido suave y sin costuras sobre la esfera (suma de ondas en 3D)."""
    total = np.zeros_like(x)
    amp, freq, norm = 1.0, base, 0.0
    for _ in range(octaves):
        for _ in range(6):
            d = rng.normal(size=3)
            d /= np.linalg.norm(d)
            total += amp * np.sin(freq * (d[0] * x + d[1] * y + d[2] * z) + rng.uniform(0, 2 * np.pi))
            norm += amp
        amp *= 0.55
        freq *= 2.1
    return total / norm * 2.2  # aprox. en [-1, 1]


def stars(h, w, rng, count, lat=None, min_lat=-1.0):
    img = np.zeros((h, w), np.float32)
    ys = rng.integers(0, h, count)
    xs = rng.integers(0, w, count)
    if lat is not None:
        keep = lat[ys, xs] > min_lat
        ys, xs = ys[keep], xs[keep]
    b = (rng.power(14, len(ys)) ** 3).astype(np.float32)
    img[ys, xs] = b
    big = rng.random(len(ys)) > 0.97
    for dy, dx in ((0, 1), (1, 0), (0, -1), (-1, 0)):
        img[(ys[big] + dy) % h, (xs[big] + dx) % w] += b[big] * 0.5
    return img


def save(img, name):
    path = os.path.join(ROOT, "worlds", "panoramas", name)
    os.makedirs(os.path.dirname(path), exist_ok=True)
    Image.fromarray((np.clip(img, 0, 1) ** (1 / 2.2) * 255).astype(np.uint8)).save(path, quality=90)
    print("ok", path)


def nebula():
    rng = np.random.default_rng(7)
    x, y, z, lat, _ = directions(W, H)
    n1 = sphere_noise(x, y, z, rng)
    n2 = sphere_noise(x, y, z, rng, base=3.0)
    band = np.exp(-((y * 1.6 + 0.35 * n1) ** 2) * 3.0)  # banda de la galaxia
    gas = np.clip(n1 * 0.5 + 0.5, 0, 1) ** 3 * band
    dust = np.clip(n2 * 0.5 + 0.5, 0, 1)
    img = np.zeros((H, W, 3), np.float32)
    img += gas[..., None] * np.array([0.55, 0.12, 0.45]) * 0.9
    img += (gas * dust)[..., None] * np.array([0.10, 0.35, 0.65]) * 1.2
    img += (band ** 4 * dust ** 2)[..., None] * np.array([0.9, 0.7, 0.5]) * 0.25
    img *= (1.0 - 0.6 * np.clip(-n2, 0, 1) ** 2)[..., None]  # nubes oscuras de polvo
    s = stars(H, W, rng, 30000)
    img += s[..., None] * np.array([1.0, 0.97, 0.92])
    img += np.array([0.001, 0.0015, 0.004])
    save(img, "nebulosa.jpg")


def aurora():
    rng = np.random.default_rng(11)
    x, y, z, lat, lon = directions(W, H)
    img = np.zeros((H, W, 3), np.float32)
    up = np.clip(y, 0, 1)
    sky = np.array([0.001, 0.003, 0.012]) + (1 - up)[..., None] ** 3 * np.array([0.02, 0.05, 0.08])
    img += sky
    img += (stars(H, W, rng, 40000, lat, 0.03) * up ** 0.3)[..., None]
    # cortinas de aurora: bandas que ondulan con la longitud
    n = sphere_noise(x, y * 0.3, z, rng, octaves=4, base=1.5)
    fine = sphere_noise(x * 4, y * 0.2, z * 4, rng, octaves=3, base=6.0)
    curtain_y = 0.35 + 0.15 * n
    d = y - curtain_y
    shape = np.where(d > 0, np.exp(-d * 9.0), np.exp(d * 40.0)) * (y > 0.02)
    rays = 0.55 + 0.45 * np.clip(fine, -1, 1)
    strength = np.clip(sphere_noise(x, y, z, rng, octaves=2, base=1.2) * 0.8 + 0.6, 0, 1)
    a = shape * rays * strength
    green = np.array([0.15, 0.95, 0.45])
    purple = np.array([0.55, 0.15, 0.75])
    top = np.clip(d * 6.0, 0, 1)
    img += a[..., None] * (green * (1 - top)[..., None] + purple * top[..., None]) * 0.8
    # montañas en el horizonte
    hills = sphere_noise(np.sin(lon), 0 * lon, np.cos(lon), rng, octaves=6, base=5.0)
    ridge = 0.01 + 0.13 * np.clip(hills * 0.9 + 0.45, 0, 1) ** 1.6
    mountain = (y < ridge) & (y > -0.02)
    img[mountain] = np.array([0.006, 0.008, 0.012])
    # lago helado que refleja el cielo (espejo vertical)
    below = y <= -0.02
    mirror_row = np.clip(H - 1 - np.arange(H), 0, H - 1)
    refl = img[mirror_row][below] * 0.35
    img[below] = refl + np.array([0.01, 0.015, 0.025])
    save(img, "aurora_boreal.jpg")


def space_drone():
    rate, secs = 22050, 20.0
    t = np.arange(int(rate * secs)) / rate
    sig = np.zeros_like(t)
    for f, a in ((55.0, 0.5), (82.5, 0.3), (110.0, 0.2), (164.8, 0.08)):
        # frecuencias múltiplo de 1/20 s para que el bucle no tenga corte
        sig += a * np.sin(2 * np.pi * f * t + 0.5 * np.sin(2 * np.pi * t / secs * 2))
    sig *= 0.6 + 0.4 * np.sin(2 * np.pi * t / secs * 3) ** 2
    sig = sig / np.abs(sig).max() * 0.35
    path = os.path.join(ROOT, "audio", "space_drone.wav")
    with wave.open(path, "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(rate)
        w.writeframes((sig * 32767).astype("<i2").tobytes())
    print("ok", path)


if __name__ == "__main__":
    nebula()
    aurora()
    space_drone()
