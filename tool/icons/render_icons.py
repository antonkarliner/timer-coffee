#!/usr/bin/env python3
"""Renders the non-iOS app icons from ios/AppIcon.icon (plan 071).

ios/AppIcon.icon is the source of truth. Its three layer SVGs are combined
with the icon.json transforms (every group translated [10, 10] pt, the tick
group scaled 0.9 about the canvas centre) into a flat translation: same
geometry, no glass.

    python3 tool/icons/render_icons.py [android] [notification] [splash] [web]

PNGs are rasterised with headless Google Chrome (exact SVG strokes, nothing
to install); VectorDrawables are written as XML directly. Re-run after any
change to the .icon rather than editing the outputs by hand.
"""
import math
import os
import re
import subprocess
import sys
import tempfile

REPO = os.path.abspath(os.path.join(os.path.dirname(__file__), '..', '..'))
LAYERS = os.path.join(REPO, 'ios', 'AppIcon.icon', 'Assets')
RES = os.path.join(REPO, 'android', 'app', 'src', 'main', 'res')
CHROME = '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome'

# ------------------------------------------------------------- geometry ----
PLATE_R = 445                      # dial-plate.svg: r=445 at (502, 502)
SHIFT = 10                         # icon.json translation-in-points
TICK_SCALE = 0.9                   # icon.json Ticks group scale

# Android: the iOS canvas maps onto the visible 72 dp of a 108 dp layer.
LAYER_SCALE = 72 / 108

# Colours picked in plan 071 Phase 0 (option B'): white plate on a light-gray
# gradient, which needs more contrast than iOS's white-to-#f1f1f1 because the
# flat plate has no glass shadow; the shadow is a radial-gradient ring so it
# survives as a VectorDrawable (no blur).
BG_TOP, BG_BOTTOM = '#EEEEEE', '#DEDEDE'
SHADOW_ALPHA, SHADOW_SPREAD, SHADOW_DY = 0.16, 22, 8


def _paths(name, ids=None):
    """[(d, stroke_width)] for every <path> in a layer SVG (or only `ids`)."""
    src = open(os.path.join(LAYERS, name)).read()
    out = []
    for tag in re.findall(r'<path\b[^>]*/>', src, re.S):
        pid = re.search(r'\sid="([^"]+)"', tag)
        if ids is not None and (pid is None or pid.group(1) not in ids):
            continue
        d = re.search(r'\sd="([^"]+)"', tag).group(1)
        sw = re.search(r'stroke-width="([^"]+)"', tag)
        out.append((' '.join(d.split()), float(sw.group(1)) if sw else 0.0))
    return out


BEAN = _paths('bean.svg')
TICKS = _paths('ticks.svg')
# The 12, 3, 6 and 9 o'clock ticks (plan 071 D3 small-size mark).
CARDINAL_TICKS = _paths('ticks.svg', ids=('rect3', 'rect3-1', 'rect3-5', 'rect3-1-2'))


def _circle_d(cx, cy, r):
    return (f'M {cx - r:g} {cy:g} A {r:g} {r:g} 0 1 0 {cx + r:g} {cy:g} '
            f'A {r:g} {r:g} 0 1 0 {cx - r:g} {cy:g} Z')


# ----------------------------------------------------------------- SVG ----
def _svg_paths(paths, color):
    return ''.join(f'<path d="{d}" fill="{color}" stroke="{color}" stroke-width="{sw:g}"/>'
                   for d, sw in paths)


def svg_mark(color):
    """Ticks + bean in iOS canvas space (1024, art centred at 512)."""
    return (f'<g transform="translate(512 512) scale({TICK_SCALE}) translate(-512 -512) '
            f'translate({SHIFT} {SHIFT})">{_svg_paths(TICKS, color)}</g>'
            f'<g transform="translate({SHIFT} {SHIFT})">{_svg_paths(BEAN, color)}</g>')


def svg_small_mark(color):
    """The favicon mark for 16-48 px (plan 071 D3): the bean enlarged 1.45x and
    the four cardinal ticks, thickened and rotated 45 degrees about the bean."""
    ticks = ''.join(f'<path d="{d}" fill="{color}" stroke="{color}" stroke-width="{sw + 44:g}" '
                    f'stroke-linecap="round" stroke-linejoin="round"/>' for d, sw in CARDINAL_TICKS)
    return (f'<g transform="rotate(45 512 512) translate(512 512) scale({TICK_SCALE}) '
            f'translate(-512 -512) translate({SHIFT} {SHIFT})">{ticks}</g>'
            f'<g transform="translate(512 512) scale(1.45) translate(-512 -512) '
            f'translate({SHIFT} {SHIFT})">{_svg_paths(BEAN, color)}</g>')


def svg_plate(color, shadow=True):
    out = ''
    if shadow:
        r1 = PLATE_R + SHADOW_SPREAD
        out += (f'<defs><radialGradient id="psh" cx="512" cy="{512 + SHADOW_DY}" r="{r1}" '
                f'gradientUnits="userSpaceOnUse"><stop offset="{(PLATE_R - 4) / r1:.4f}" '
                f'stop-color="#000" stop-opacity="{SHADOW_ALPHA}"/><stop offset="1" '
                f'stop-color="#000" stop-opacity="0"/></radialGradient></defs>'
                f'<circle cx="512" cy="{512 + SHADOW_DY}" r="{r1}" fill="url(#psh)"/>')
    return out + f'<circle cx="512" cy="512" r="{PLATE_R}" fill="{color}"/>'


def svg_android_layer():
    """The full 108 dp adaptive icon (background + foreground), 1024 units."""
    bg = (f'<defs><linearGradient id="bg" x1="0" y1="0" x2="0" y2="1">'
          f'<stop offset="0" stop-color="{BG_TOP}"/><stop offset="1" stop-color="{BG_BOTTOM}"/>'
          f'</linearGradient></defs><rect width="1024" height="1024" fill="url(#bg)"/>')
    fg = (f'<g transform="translate(512 512) scale({LAYER_SCALE:.6f}) translate(-512 -512)">'
          f'{svg_plate("#fff")}{svg_mark("#000")}</g>')
    return bg + fg


VISIBLE = 1024 * LAYER_SCALE          # the 72 dp window, in layer units
VIS_O = (1024 - VISIBLE) / 2


def squircle_d(n=4.2, size=VISIBLE, cx=512, cy=512):
    pts = []
    for i in range(360):
        t = 2 * math.pi * i / 360
        c, s = math.cos(t), math.sin(t)
        pts.append((cx + math.copysign(abs(c) ** (2 / n), c) * size / 2,
                    cy + math.copysign(abs(s) ** (2 / n), s) * size / 2))
    return 'M ' + ' L '.join(f'{x:.2f} {y:.2f}' for x, y in pts) + ' Z'


def svg_doc(inner, px, view, clip=None):
    if clip:
        inner = (f'<defs><clipPath id="m"><path d="{clip}"/></clipPath></defs>'
                 f'<g clip-path="url(#m)">{inner}</g>')
    vb = ' '.join(f'{v:.3f}' for v in view)
    return (f'<svg xmlns="http://www.w3.org/2000/svg" width="{px}" height="{px}" '
            f'viewBox="{vb}">{inner}</svg>')


def render_png(svg_text, out, px):
    html = ('<!doctype html><html><head><style>html,body{margin:0;padding:0;'
            'background:transparent;overflow:hidden}svg{display:block}</style>'
            f'</head><body>{svg_text}</body></html>')
    with tempfile.NamedTemporaryFile('w', suffix='.html', delete=False) as f:
        f.write(html)
        tmp = f.name
    try:
        subprocess.run([CHROME, '--headless', '--disable-gpu', '--hide-scrollbars',
                        '--force-device-scale-factor=1',
                        '--default-background-color=00000000',
                        f'--window-size={px},{px}', f'--screenshot={out}',
                        f'file://{tmp}'], check=True, capture_output=True)
    finally:
        os.unlink(tmp)
    # Strip metadata so re-runs are byte-stable, and force 8-bit RGBA: left to
    # itself ImageMagick writes an all-gray icon as gray+alpha, which Android
    # 12+'s splash screen draws as a faint mask instead of the image.
    subprocess.run(['magick', out, '-strip', f'PNG32:{out}'], check=True)
    print('wrote', os.path.relpath(out, REPO))


# ------------------------------------------------------- VectorDrawable ----
VD_HEAD = ('<?xml version="1.0" encoding="utf-8"?>\n'
           '<!-- Generated by tool/icons/render_icons.py from ios/AppIcon.icon. '
           'Do not edit by hand. -->\n'
           '<vector xmlns:android="http://schemas.android.com/apk/res/android"{ns}\n'
           '    android:width="{dp}dp"\n    android:height="{dp}dp"\n'
           '    android:viewportWidth="1024"\n    android:viewportHeight="1024">\n')
AAPT = '\n    xmlns:aapt="http://schemas.android.com/aapt"'


def _vd_paths(paths, color, indent, extra_stroke=0):
    pad = ' ' * indent
    join = (f'{pad}    android:strokeLineJoin="round"\n' if extra_stroke else '')
    return ''.join(
        f'{pad}<path\n{pad}    android:fillColor="{color}"\n'
        f'{pad}    android:strokeColor="{color}"\n'
        f'{pad}    android:strokeWidth="{sw + extra_stroke:g}"\n{join}'
        f'{pad}    android:pathData="{d}" />\n' for d, sw in paths)


def vd_mark(color, indent, tick_extra_stroke=0):
    """Ticks + bean, inside groups that reproduce the icon.json transforms.
    Group matrices apply outer-last, so the [10, 10] shift is the inner group
    and the 0.9 tick scale about the centre wraps it."""
    p = ' ' * indent
    return (f'{p}<group android:pivotX="512" android:pivotY="512"\n'
            f'{p}    android:scaleX="{TICK_SCALE}" android:scaleY="{TICK_SCALE}">\n'
            f'{p}    <group android:translateX="{SHIFT}" android:translateY="{SHIFT}">\n'
            f'{_vd_paths(TICKS, color, indent + 8, tick_extra_stroke)}'
            f'{p}    </group>\n{p}</group>\n'
            f'{p}<group android:translateX="{SHIFT}" android:translateY="{SHIFT}">\n'
            f'{_vd_paths(BEAN, color, indent + 4)}'
            f'{p}</group>\n')


def _layer_group(body, indent=4):
    p = ' ' * indent
    return (f'{p}<group android:pivotX="512" android:pivotY="512"\n'
            f'{p}    android:scaleX="{LAYER_SCALE:.6f}" android:scaleY="{LAYER_SCALE:.6f}">\n'
            f'{body}{p}</group>\n')


def _argb(hex_rgb, alpha=1.0):
    return f'#{round(alpha * 255):02X}{hex_rgb.lstrip("#").upper()}'


def vd_background():
    return (VD_HEAD.format(ns=AAPT, dp=108) +
            '    <path android:pathData="M 0 0 H 1024 V 1024 H 0 Z">\n'
            '        <aapt:attr name="android:fillColor">\n'
            '            <gradient android:type="linear"\n'
            '                android:startX="512" android:startY="0"\n'
            '                android:endX="512" android:endY="1024">\n'
            f'                <item android:offset="0" android:color="{_argb(BG_TOP)}" />\n'
            f'                <item android:offset="1" android:color="{_argb(BG_BOTTOM)}" />\n'
            '            </gradient>\n'
            '        </aapt:attr>\n'
            '    </path>\n</vector>\n')


def vd_foreground():
    r1 = PLATE_R + SHADOW_SPREAD
    cy = 512 + SHADOW_DY
    shadow = (
        f'        <path android:pathData="{_circle_d(512, cy, r1)}">\n'
        '            <aapt:attr name="android:fillColor">\n'
        '                <gradient android:type="radial"\n'
        f'                    android:centerX="512" android:centerY="{cy}"\n'
        f'                    android:gradientRadius="{r1}">\n'
        f'                    <item android:offset="{(PLATE_R - 4) / r1:.4f}" '
        f'android:color="{_argb("000000", SHADOW_ALPHA)}" />\n'
        '                    <item android:offset="1" android:color="#00000000" />\n'
        '                </gradient>\n'
        '            </aapt:attr>\n'
        '        </path>\n')
    plate = (f'        <path android:fillColor="#FFFFFFFF"\n'
             f'            android:pathData="{_circle_d(512, 512, PLATE_R)}" />\n')
    body = shadow + plate + vd_mark('#FF000000', 8)
    return VD_HEAD.format(ns=AAPT, dp=108) + _layer_group(body) + '</vector>\n'


def vd_monochrome():
    # Themed icons read alpha only; plan 071 D2 = ticks + bean, no plate.
    return VD_HEAD.format(ns='', dp=108) + _layer_group(vd_mark('#FF000000', 8)) + '</vector>\n'


def write(path, text):
    with open(path, 'w') as f:
        f.write(text)
    print('wrote', os.path.relpath(path, REPO))


# ------------------------------------------------------------- targets ----
LEGACY_DENSITIES = {'mdpi': 48, 'hdpi': 72, 'xhdpi': 96, 'xxhdpi': 144, 'xxxhdpi': 192}


def android():
    write(os.path.join(RES, 'drawable', 'ic_launcher_background.xml'), vd_background())
    write(os.path.join(RES, 'drawable', 'ic_launcher_foreground.xml'), vd_foreground())
    write(os.path.join(RES, 'drawable', 'ic_launcher_monochrome.xml'), vd_monochrome())

    # API 24-25 (pre-adaptive): the icon as a 44 dp circle in a 48 dp square.
    pad = VISIBLE * (48 / 44 - 1) / 2
    view = (VIS_O - pad, VIS_O - pad, VISIBLE + 2 * pad, VISIBLE + 2 * pad)
    circle = _circle_d(512, 512, VISIBLE / 2)
    for density, px in LEGACY_DENSITIES.items():
        render_png(svg_doc(svg_android_layer(), px, view, circle),
                   os.path.join(RES, f'mipmap-{density}', 'ic_launcher.png'), px)

    # In-app icon picker preview (lib/widgets/settings/app_icon_selector.dart).
    render_png(svg_doc(svg_android_layer(), 512, (VIS_O, VIS_O, VISIBLE, VISIBLE),
                       squircle_d()),
               os.path.join(REPO, 'assets', 'icons', 'timer-coffee-icon-android.png'), 512)


# Notification small icon (plan 071 D4, provisional): the full mark with the
# ticks thickened from ~0.7 dp to ~1.2 dp so they survive at 24 dp. Android
# draws it from alpha only. The outer tick end sits ~368 units from the centre
# (after the 0.9); scale so it lands 11 dp out, leaving 1 dp of padding.
STAT_TICK_EXTRA = 26


def vd_notification():
    k = (11 / 24 * 1024) / 368
    body = (f'    <group android:pivotX="512" android:pivotY="512"\n'
            f'        android:scaleX="{k:.6f}" android:scaleY="{k:.6f}">\n'
            f'{vd_mark("#FFFFFFFF", 8, STAT_TICK_EXTRA)}    </group>\n')
    return VD_HEAD.format(ns='', dp=24) + body + '</vector>\n'


def notification():
    write(os.path.join(RES, 'drawable', 'ic_stat_timer_coffee.xml'), vd_notification())


# Splash (plan 071 D5): the flat mark on the splash background, with the plate
# a shade off it so it reads without the glass. flutter_native_splash takes
# `image` as a 4x asset (1024 px -> 256 pt/dp) for iOS, pre-12 Android and the
# web; the mark is scaled to 0.87 so its ticks span about what the old art did.
# Android 12+ (`android_12.image`) wants 1152 px with the icon inside a 768 px
# circle, so there the plate is sized to 760 px.
SPLASH = {
    'light': {'plate': '#F3F3F3', 'mark': '#000000'},
    'dark': {'plate': '#383838', 'mark': '#FFFFFF'},   # iOS Dark's gray 0.22 plate
}
SPLASH_SCALE = 0.87
SPLASH12_PLATE_D = 760


def splash():
    for mode, c in SPLASH.items():
        art = svg_plate(c['plate'], shadow=False) + svg_mark(c['mark'])
        k = SPLASH_SCALE
        render_png(svg_doc(f'<g transform="translate(512 512) scale({k}) translate(-512 -512)">'
                           f'{art}</g>', 1024, (0, 0, 1024, 1024)),
                   os.path.join(REPO, 'assets', 'icons', f'splash_{mode}.png'), 1024)
        k12 = SPLASH12_PLATE_D / (2 * PLATE_R) * 1024 / 1152
        render_png(svg_doc(f'<g transform="translate(512 512) scale({k12:.6f}) translate(-512 -512)">'
                           f'{art}</g>', 1152, (0, 0, 1024, 1024)),
                   os.path.join(REPO, 'assets', 'icons', f'splash_android12_{mode}.png'), 1152)


# Web (plan 071 Phase 5). Tab favicons sit on a light rounded tile like the
# iOS icon's system-light fill: the small mark up to 48 px, the full mark from
# 96 px. Install icons (apple-touch, PWA) use the Android look (B'), since they
# end up next to other app icons.
WEB = os.path.join(REPO, 'web', 'icons')
TILE_R = 0.2237 * 1024


def svg_tile(inner):
    return (f'<defs><linearGradient id="tb" x1="0" y1="0" x2="0" y2="1">'
            f'<stop offset="0" stop-color="#FFFFFF"/><stop offset="1" stop-color="#F1F1F1"/>'
            f'</linearGradient><clipPath id="tc"><rect width="1024" height="1024" '
            f'rx="{TILE_R:.1f}"/></clipPath></defs><g clip-path="url(#tc)">'
            f'<rect width="1024" height="1024" fill="url(#tb)"/>{inner}</g>')


def web():
    small = svg_tile(svg_small_mark('#000'))
    full = svg_tile(svg_mark('#000'))
    with open(os.path.join(WEB, 'favicon.svg'), 'w') as f:
        f.write('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1024 1024">'
                f'{small}</svg>\n')
    print('wrote web/icons/favicon.svg')
    frames = []
    for px in (16, 32, 48):
        out = os.path.join(tempfile.gettempdir(), f'tc-favicon-{px}.png')
        render_png(svg_doc(small, px, (0, 0, 1024, 1024)), out, px)
        frames.append(out)
    subprocess.run(['magick', *frames, os.path.join(WEB, 'favicon.ico')], check=True)
    for frame in frames:
        os.unlink(frame)
    print('wrote web/icons/favicon.ico (16, 32, 48)')
    render_png(svg_doc(small, 32, (0, 0, 1024, 1024)), os.path.join(WEB, 'favicon-32x32.png'), 32)
    render_png(svg_doc(full, 96, (0, 0, 1024, 1024)), os.path.join(WEB, 'favicon-96x96.png'), 96)

    window = (VIS_O, VIS_O, VISIBLE, VISIBLE)
    # apple-touch: opaque, full-bleed; iOS applies its own corner mask.
    render_png(svg_doc(svg_android_layer(), 180, window),
               os.path.join(WEB, 'apple-touch-icon.png'), 180)
    # Maskable: full-bleed, plate inside the 40 % safe-zone radius (it is
    # 43.5 % of the window, so widen the window 1.1x).
    pad = VISIBLE * 0.05
    maskable = (VIS_O - pad, VIS_O - pad, VISIBLE + 2 * pad, VISIBLE + 2 * pad)
    for px in (192, 512):
        render_png(svg_doc(svg_android_layer(), px, maskable),
                   os.path.join(WEB, f'web-app-manifest-{px}x{px}.png'), px)
        # "any": the icon with its own shape, for desktop installs.
        render_png(svg_doc(svg_android_layer(), px, window, squircle_d()),
                   os.path.join(WEB, f'web-app-icon-{px}x{px}.png'), px)


TARGETS = {'android': android, 'notification': notification, 'splash': splash, 'web': web}

if __name__ == '__main__':
    names = sys.argv[1:] or sorted(TARGETS)
    for n in names:
        if n not in TARGETS:
            sys.exit(f'unknown target {n!r}; choose from {sorted(TARGETS)}')
        TARGETS[n]()
