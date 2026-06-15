#!/usr/bin/env python3
"""
Generate pixel art sprites for GAWDZILLLLA.
All sprites are drawn pixel-by-pixel using PIL.
"""
from PIL import Image, ImageDraw
import os

OUT = "/Users/tc/godzilla-game/Assets/Sprites"
TRANSPARENT = (0, 0, 0, 0)

def save(img, path):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    img.save(path)
    print(f"  ✓ {os.path.basename(path)}")

def new(w, h):
    return Image.new("RGBA", (w, h), TRANSPARENT)

def rect(img, x, y, w, h, color):
    d = ImageDraw.Draw(img)
    d.rectangle([x, y, x+w-1, y+h-1], fill=color)

def pixel(img, x, y, color):
    if 0 <= x < img.width and 0 <= y < img.height:
        img.putpixel((x, y), color)

def hline(img, x, y, w, color):
    for i in range(w):
        pixel(img, x+i, y, color)

def vline(img, x, y, h, color):
    for i in range(h):
        pixel(img, x, y+i, color)

# ─── GODZILLA (64×96, 3 frames: idle, walk, attack) ──────────────────────────
# Colors
GZ_BODY  = (38, 100, 56, 255)
GZ_BELLY = (60, 140, 80, 255)
GZ_DARK  = (20, 65, 35, 255)
GZ_SPINE = (18, 55, 30, 255)
GZ_EYE   = (255, 220, 0, 255)
GZ_PUPIL = (0, 0, 0, 255)
GZ_TOOTH = (230, 230, 200, 255)

def draw_godzilla_frame(frame=0):
    img = new(48, 80)
    cx = 24  # center x

    # Tail
    tail_pts = [(2,72),(4,68),(6,64),(8,62),(10,64),(8,70),(4,74)]
    draw = ImageDraw.Draw(img)
    draw.polygon(tail_pts, fill=GZ_DARK)

    # Legs
    legW, legH = 10, 18
    rect(img, 10, 62, legW, legH, GZ_BODY)
    rect(img, 28, 62, legW, legH, GZ_BODY)
    # Feet
    rect(img, 8,  76, 13, 6, GZ_DARK)
    rect(img, 26, 76, 13, 6, GZ_DARK)
    # Toes
    for i in range(3):
        pixel(img, 8+i*4, 82, GZ_DARK)
        pixel(img, 26+i*4, 82, GZ_DARK)

    # Body
    rect(img, 10, 30, 28, 34, GZ_BODY)
    # Belly
    rect(img, 15, 35, 18, 25, GZ_BELLY)

    # Arms (small, T-rex style)
    if frame == 2:  # attack: arm extended
        rect(img, 38, 38, 8, 6, GZ_BODY)   # right arm forward
        rect(img, 2,  40, 6, 5, GZ_DARK)   # left arm
    else:
        rect(img, 36, 42, 6, 5, GZ_BODY)
        rect(img, 6,  42, 6, 5, GZ_DARK)

    # Neck
    rect(img, 16, 18, 16, 16, GZ_BODY)

    # Head
    rect(img, 12, 4, 24, 18, GZ_BODY)
    # Jaw/snout
    rect(img, 14, 16, 20, 8, GZ_DARK)
    # Teeth
    for i in range(4):
        rect(img, 14+i*5, 22, 3, 4, GZ_TOOTH)

    # Eye
    rect(img, 30, 8, 7, 6, GZ_EYE)
    rect(img, 32, 9, 3, 3, GZ_PUPIL)

    # Dorsal spines (back = left side)
    spine_x = 8
    for i, (sy, sh) in enumerate([(8,14),(18,12),(28,10),(38,8),(48,6)]):
        draw.polygon([
            (spine_x, sy+sh), (spine_x-4, sy), (spine_x+2, sy+sh)
        ], fill=GZ_SPINE)

    # Walk animation offset
    if frame == 1:
        # Shift legs slightly for walking
        rect(img, 10, 64, legW, 16, TRANSPARENT)
        rect(img, 10, 60, legW, 20, GZ_BODY)
        rect(img, 28, 66, legW, 14, GZ_BODY)

    return img

print("Generating Godzilla sprites...")
for i in range(3):
    img = draw_godzilla_frame(i)
    save(img, f"{OUT}/Characters/Godzilla_Frame{i}.png")

# Sprite sheet (3 frames side by side)
sheet = new(144, 80)
for i in range(3):
    f = draw_godzilla_frame(i)
    sheet.paste(f, (i*48, 0))
save(sheet, f"{OUT}/Characters/Godzilla_Sheet.png")

# ─── KONG (48×80) ─────────────────────────────────────────────────────────────
KG_BODY  = (88, 58, 28, 255)
KG_CHEST = (120, 80, 40, 255)
KG_DARK  = (55, 35, 15, 255)
KG_EYE   = (255, 180, 0, 255)
KG_PUPIL = (0, 0, 0, 255)
KG_FACE  = (140, 90, 50, 255)

def draw_kong_frame(frame=0):
    img = new(48, 80)

    # Legs (wide stance)
    rect(img, 8,  58, 12, 20, KG_BODY)
    rect(img, 28, 58, 12, 20, KG_BODY)
    # Feet (wide)
    rect(img, 5,  74, 16, 8, KG_DARK)
    rect(img, 27, 74, 16, 8, KG_DARK)

    # Body (barrel chest)
    rect(img, 8, 28, 32, 32, KG_BODY)
    # Chest highlight
    rect(img, 13, 30, 22, 20, KG_CHEST)

    # Long arms
    if frame == 2:  # attack: arm swinging
        rect(img, -2, 28, 14, 8, KG_BODY)   # left arm extended
        rect(img, 36, 30, 14, 8, KG_BODY)
    else:
        rect(img, 0,  36, 10, 6, KG_BODY)
        rect(img, 38, 36, 10, 6, KG_BODY)
    # Knuckles (on ground when still)
    if frame == 0:
        rect(img, 0,  56, 10, 5, KG_DARK)
        rect(img, 38, 56, 10, 5, KG_DARK)

    # Neck (short, gorilla)
    rect(img, 16, 18, 16, 12, KG_BODY)

    # Head (round)
    draw = ImageDraw.Draw(img)
    draw.ellipse([10, 2, 38, 26], fill=KG_BODY)
    # Face
    rect(img, 13, 12, 22, 12, KG_FACE)
    # Brow ridge
    rect(img, 11, 6, 26, 6, KG_DARK)
    # Eyes
    rect(img, 14, 10, 6, 5, KG_EYE)
    rect(img, 28, 10, 6, 5, KG_EYE)
    rect(img, 16, 11, 3, 3, KG_PUPIL)
    rect(img, 30, 11, 3, 3, KG_PUPIL)
    # Nostrils
    pixel(img, 21, 18, KG_DARK)
    pixel(img, 25, 18, KG_DARK)

    return img

print("Generating Kong sprites...")
sheet = new(144, 80)
for i in range(3):
    f = draw_kong_frame(i)
    save(f, f"{OUT}/Characters/Kong_Frame{i}.png")
    sheet.paste(f, (i*48, 0))
save(sheet, f"{OUT}/Characters/Kong_Sheet.png")

# ─── GHIDORAH (72×80 — wider for 3 heads) ─────────────────────────────────────
GH_BODY  = (185, 158, 20, 255)
GH_WING  = (160, 135, 15, 255)
GH_DARK  = (120, 100, 8, 255)
GH_EYE   = (255, 50, 50, 255)
GH_SCALE = (200, 170, 25, 255)

def draw_ghidorah_frame(frame=0):
    img = new(72, 88)
    draw = ImageDraw.Draw(img)

    # Wings (large, bat-like — behind body)
    wing_pts_l = [(0,20),(2,10),(8,5),(16,12),(20,30),(12,42),(4,40)]
    wing_pts_r = [(72,20),(70,10),(64,5),(56,12),(52,30),(60,42),(68,40)]
    draw.polygon(wing_pts_l, fill=GH_WING)
    draw.polygon(wing_pts_r, fill=GH_WING)
    # Wing membrane lines
    for y in range(10, 40, 5):
        t = (y-10)/30
        lx = int(4 + t*12)
        rx = int(68 - t*12)
        draw.line([(2,y),(lx,40)], fill=GH_DARK, width=1)
        draw.line([(70,y),(rx,40)], fill=GH_DARK, width=1)

    # Main body
    rect(img, 22, 44, 28, 28, GH_BODY)
    # Scale texture
    for gy in range(46, 70, 4):
        for gx in range(24, 48, 6):
            pixel(img, gx, gy, GH_SCALE)

    # Legs
    rect(img, 22, 68, 10, 18, GH_BODY)
    rect(img, 40, 68, 10, 18, GH_BODY)
    rect(img, 20, 82, 14, 6, GH_DARK)
    rect(img, 38, 82, 14, 6, GH_DARK)

    # Three necks
    # Left neck (curved)
    neck_left = [(25,44),(22,36),(18,28),(14,20),(18,14),(24,18),(22,26),(26,34),(28,44)]
    draw.polygon(neck_left, fill=GH_BODY)
    # Center neck (straight up)
    rect(img, 30, 18, 12, 28, GH_BODY)
    # Right neck
    neck_right = [(47,44),(50,36),(54,28),(58,20),(54,14),(48,18),(50,26),(46,34),(44,44)]
    draw.polygon(neck_right, fill=GH_BODY)

    # Three heads
    # Left head
    rect(img, 10, 6, 16, 12, GH_BODY)
    rect(img, 8, 14, 18, 5, GH_DARK)  # jaw
    rect(img, 14, 8, 6, 4, GH_EYE)   # eye
    rect(img, 16, 9, 2, 2, (0,0,0,255))  # pupil
    # Center head
    rect(img, 27, 4, 18, 14, GH_BODY)
    rect(img, 25, 14, 22, 5, GH_DARK)
    rect(img, 32, 6, 6, 4, GH_EYE)
    rect(img, 34, 7, 2, 2, (0,0,0,255))
    # Right head
    rect(img, 46, 6, 16, 12, GH_BODY)
    rect(img, 44, 14, 18, 5, GH_DARK)
    rect(img, 50, 8, 6, 4, GH_EYE)
    rect(img, 52, 9, 2, 2, (0,0,0,255))

    # Lightning beam effect for attack frame
    if frame == 2:
        draw.line([(36, 18), (36, 0)], fill=(255,255,100,200), width=3)
        draw.line([(18, 18), (10, 0)], fill=(255,255,100,200), width=2)
        draw.line([(54, 18), (62, 0)], fill=(255,255,100,200), width=2)

    return img

print("Generating Ghidorah sprites...")
sheet = new(216, 88)
for i in range(3):
    f = draw_ghidorah_frame(i)
    save(f, f"{OUT}/Characters/Ghidorah_Frame{i}.png")
    sheet.paste(f, (i*72, 0))
save(sheet, f"{OUT}/Characters/Ghidorah_Sheet.png")

# ─── NPC Human (12×24) ────────────────────────────────────────────────────────
def draw_npc_human(shirt_color, pants_color, skin=(220,180,140,255)):
    img = new(12, 24)
    # Head
    rect(img, 4, 0, 5, 5, skin)
    # Hair
    rect(img, 4, 0, 5, 2, (60,40,20,255))
    # Body
    rect(img, 3, 5, 6, 8, shirt_color)
    # Arms
    rect(img, 1, 5, 2, 6, shirt_color)
    rect(img, 9, 5, 2, 6, shirt_color)
    # Legs
    rect(img, 3, 13, 2, 8, pants_color)
    rect(img, 7, 13, 2, 8, pants_color)
    # Shoes
    rect(img, 2, 20, 4, 4, (40,30,20,255))
    rect(img, 6, 20, 4, 4, (40,30,20,255))
    # Eye
    pixel(img, 6, 2, (0,0,0,255))
    return img

print("Generating NPC sprites...")
# Various NPC types
npcs = [
    ("Human",    (180,100,60,255),  (80,80,180,255)),
    ("Police",   (60,80,160,255),   (60,80,160,255)),
    ("Soldier",  (80,100,60,255),   (80,100,60,255)),
]
for name, shirt, pants in npcs:
    img = draw_npc_human(shirt, pants)
    save(img, f"{OUT}/NPCs/{name}.png")
    # 3-frame walk sheet
    sheet = new(36, 24)
    for f in range(3):
        fr = draw_npc_human(shirt, pants)
        # Walk: offset one leg down
        if f == 1:
            rect(fr, 3, 13, 2, 8, (0,0,0,0))
            rect(fr, 3, 15, 2, 8, pants)
            rect(fr, 7, 11, 2, 8, pants)
        sheet.paste(fr, (f*12, 0))
    save(sheet, f"{OUT}/NPCs/{name}_Sheet.png")

# Blood splat effect (16x16)
def draw_blood_splat():
    img = new(32, 32)
    draw = ImageDraw.Draw(img)
    cx, cy = 16, 16
    # Main pool
    draw.ellipse([8,12,24,22], fill=(160,0,0,220))
    # Splatter drops
    drops = [(4,8,3,3),(24,6,3,3),(28,14,2,2),(5,20,2,2),(26,22,3,2),(14,4,2,2),(18,26,2,2)]
    for (dx,dy,dw,dh) in drops:
        draw.ellipse([dx,dy,dx+dw,dy+dh], fill=(180,0,0,200))
    return img

save(draw_blood_splat(), f"{OUT}/Effects/BloodSplat.png")

# Blood splat particle sheet (4 frames of expansion)
sheet = new(128, 32)
for i in range(4):
    fr = new(32, 32)
    draw = ImageDraw.Draw(fr)
    r = 4 + i * 4
    alpha = 255 - i * 40
    draw.ellipse([16-r, 16-r, 16+r, 16+r], fill=(160,0,0,alpha))
    for _ in range(i*2):
        import random
        dx = random.randint(-r-4, r+4)
        dy = random.randint(-r-4, r+4)
        draw.ellipse([16+dx, 16+dy, 16+dx+3, 16+dy+3], fill=(200,0,0,alpha))
    sheet.paste(fr, (i*32, 0))
save(sheet, f"{OUT}/Effects/BloodSplat_Sheet.png")

# ─── BUILDINGS (Tokyo style — tall, neon-lit) ─────────────────────────────────
def draw_building(w, h, damage_pct=1.0, style="office"):
    img = new(w, h)

    if damage_pct == 0:  # rubble
        # Rubble pile (jagged)
        draw = ImageDraw.Draw(img)
        pts = [(0,h),(0,h-8),(w//4,h-16),(w//2,h-10),(3*w//4,h-18),(w,h-6),(w,h)]
        draw.polygon(pts, fill=(80,65,50,255))
        rect(img, 2, h-6, w-4, 6, (70,55,40,255))
        return img

    # Building color varies by damage
    if damage_pct > 0.6:
        body_c = (45,48,72,255)
        win_lit = (255,240,100,220)
        win_off = (30,35,60,180)
    elif damage_pct > 0.3:
        body_c = (90,65,40,255)
        win_lit = (255,130,30,220)
        win_off = (60,40,25,180)
    else:
        body_c = (90,35,30,255)
        win_lit = (255,40,10,220)
        win_off = (70,20,15,180)

    # Main building body
    rect(img, 0, 0, w, h, body_c)

    # Right-side shadow (3D effect)
    shadow_w = max(3, w // 6)
    rect(img, w-shadow_w, 0, shadow_w, h, tuple(max(0,c-30) for c in body_c[:3]) + (255,))

    # Left highlight
    rect(img, 0, 0, 2, h, tuple(min(255,c+40) for c in body_c[:3]) + (255,))

    # Windows grid
    win_pad_x = max(3, w // 5)
    win_pad_y = 8
    win_w = max(3, w // 4)
    win_h = 5
    win_gap_x = max(2, w // 4)
    win_gap_y = 9

    for wy in range(win_pad_y, h-10, win_gap_y):
        for wx in range(win_pad_x, w-win_pad_x, win_gap_x):
            slot = (wy // win_gap_y + wx // win_gap_x)
            lit = (slot % 3 != 0) if damage_pct > 0.3 else (slot % 2 == 0)
            c = win_lit if lit else win_off
            rect(img, wx, wy, win_w, win_h, c)

    # Roof
    roof_c = tuple(min(255, c+20) for c in body_c[:3]) + (255,)
    rect(img, 0, 0, w, 4, roof_c)

    # Antenna for taller buildings
    if h > 60 and style == "office":
        rect(img, w//2-1, -8, 2, 10, (200,200,200,255))
        pixel(img, w//2, -8, (255,50,50,255))  # red warning light

    return img

print("Generating building sprites...")
# Building variants: wide-short, medium, tall, very-tall
sizes = [(24,60),(20,80),(16,100),(12,130),(30,50)]
for i, (bw, bh) in enumerate(sizes):
    for pct, name in [(1.0,"Intact"),(0.5,"Damaged"),(0.15,"Critical"),(0.0,"Rubble")]:
        img = draw_building(bw, bh, pct)
        save(img, f"{OUT}/City/Building{i+1}_{name}.png")

# Tokyo-specific landmark: Tokyo Tower (red steel lattice)
def draw_tokyo_tower():
    img = new(24, 120)
    draw = ImageDraw.Draw(img)
    # Tapering body
    for y in range(0, 120, 1):
        t = y / 120
        w = int(2 + t * 20)
        x = 12 - w//2
        c_r = int(220 - t*60)
        c = (c_r, int(80 - t*40), 20, 255)
        draw.line([(x, y), (x+w, y)], fill=c)
    # Lattice lines
    for y in range(0, 120, 8):
        t = y / 120
        w = int(2 + t * 20)
        x = 12 - w//2
        draw.line([(x, y), (12, y-6)], fill=(255,255,255,80))
        draw.line([(x+w, y), (12, y-6)], fill=(255,255,255,80))
    # Observation deck
    rect(img, 8, 50, 8, 5, (200,200,200,255))
    rect(img, 7, 30, 10, 5, (200,200,200,255))
    return img

save(draw_tokyo_tower(), f"{OUT}/City/TokyoTower.png")

# ─── GROUND TILE (32×16, perspective) ─────────────────────────────────────────
def draw_ground_tile():
    img = new(32, 16)
    draw = ImageDraw.Draw(img)
    # Asphalt base
    rect(img, 0, 0, 32, 16, (55,52,48,255))
    # Road markings
    rect(img, 0, 7, 32, 2, (80,78,72,255))
    # Cracks
    draw.line([(4,0),(8,16)], fill=(40,38,35,255), width=1)
    draw.line([(20,0),(18,16)], fill=(40,38,35,255), width=1)
    return img

save(draw_ground_tile(), f"{OUT}/City/Ground.png")

# Sidewalk tile
def draw_sidewalk():
    img = new(16, 16)
    rect(img, 0, 0, 16, 16, (160,155,145,255))
    # Tile grid
    rect(img, 0, 8, 16, 1, (130,125,115,255))
    rect(img, 8, 0, 1, 16, (130,125,115,255))
    return img

save(draw_sidewalk(), f"{OUT}/City/Sidewalk.png")

# ─── UI ELEMENTS ──────────────────────────────────────────────────────────────
# Health bar fill (1×8, green)
def draw_bar_fill(color, w=100, h=10):
    img = new(w, h)
    rect(img, 0, 0, w, h, color)
    # Gloss
    rect(img, 0, 0, w, 2, tuple(min(255,c+60) for c in color[:3]) + (180,))
    return img

save(draw_bar_fill((50,200,80,255)),    f"{OUT}/UI/HealthBarFill.png")
save(draw_bar_fill((220,200,30,255)),   f"{OUT}/UI/PowerBarFill.png")
save(draw_bar_fill((40,40,40,255)),     f"{OUT}/UI/BarBackground.png")

# ─── FART CLOUD (particle) ────────────────────────────────────────────────────
def draw_fart_cloud():
    img = new(32, 24)
    draw = ImageDraw.Draw(img)
    draw.ellipse([0,8,20,22], fill=(100,180,80,150))
    draw.ellipse([8,4,28,20], fill=(120,200,90,140))
    draw.ellipse([4,10,24,24], fill=(90,160,70,130))
    # Wavy lines
    for y in range(6, 20, 4):
        for x in range(2, 28, 4):
            draw.point((x, y + (1 if x%8==0 else 0)), fill=(60,120,50,100))
    return img

save(draw_fart_cloud(), f"{OUT}/Effects/FartCloud.png")

# ─── MOTHRA (56×72, wide moth — wings spread) ────────────────────────────────
MT_BODY  = (220, 200, 140, 255)
MT_WING  = (190, 160, 80, 255)
MT_WPAT  = (240, 120, 30, 255)
MT_EYE   = (180, 80, 200, 255)
MT_FUR   = (235, 215, 155, 255)
MT_DARK  = (140, 110, 40, 255)

def draw_mothra_frame(frame=0):
    img = new(56, 72)
    draw = ImageDraw.Draw(img)

    # Wings (large, spread horizontally)
    wing_off = 2 if frame == 1 else 0  # flap animation
    # Upper wings
    draw.polygon([(4,20+wing_off),(0,5+wing_off),(14,2+wing_off),(26,18)], fill=MT_WING)
    draw.polygon([(52,20+wing_off),(56,5+wing_off),(42,2+wing_off),(30,18)], fill=MT_WING)
    # Wing patterns (eyespots)
    for wx, wy in [(10, 10+wing_off), (46, 10+wing_off)]:
        draw.ellipse([wx-5,wy-4,wx+5,wy+4], fill=MT_WPAT)
        draw.ellipse([wx-2,wy-2,wx+2,wy+2], fill=(255,220,50,255))
    # Lower wings
    draw.polygon([(6,30-wing_off),(0,48-wing_off),(18,52-wing_off),(26,34)], fill=MT_DARK)
    draw.polygon([(50,30-wing_off),(56,48-wing_off),(38,52-wing_off),(30,34)], fill=MT_DARK)

    # Body (fuzzy moth body)
    rect(img, 20, 16, 16, 44, MT_BODY)
    # Fur texture (lighter center)
    rect(img, 22, 18, 12, 30, MT_FUR)
    # Abdomen stripes
    for sy in range(30, 58, 6):
        rect(img, 20, sy, 16, 2, MT_DARK)

    # Head (round, fuzzy)
    draw.ellipse([19, 6, 37, 22], fill=MT_FUR)
    # Compound eyes
    draw.ellipse([20, 8, 26, 14], fill=MT_EYE)
    draw.ellipse([30, 8, 36, 14], fill=MT_EYE)
    draw.ellipse([21, 9, 24, 12], fill=(255,255,255,180))
    draw.ellipse([31, 9, 34, 12], fill=(255,255,255,180))

    # Antennae
    draw.line([(25, 6),(18, 0)], fill=MT_DARK, width=2)
    draw.line([(31, 6),(38, 0)], fill=MT_DARK, width=2)
    pixel(img, 18, 0, MT_WPAT)
    pixel(img, 38, 0, MT_WPAT)

    # Attack: beam from antennae
    if frame == 2:
        draw.line([(18,0),(0,0)], fill=(255,220,100,200), width=2)
        draw.line([(38,0),(56,0)], fill=(255,220,100,200), width=2)

    return img

print("Generating Mothra sprites...")
sheet = new(168, 72)
for i in range(3):
    f = draw_mothra_frame(i)
    save(f, f"{OUT}/Characters/Mothra_Frame{i}.png")
    sheet.paste(f, (i*56, 0))
save(sheet, f"{OUT}/Characters/Mothra_Sheet.png")

# ─── RODAN (60×56, pterodactyl — wings define silhouette) ────────────────────
RD_BODY  = (130, 60, 40, 255)
RD_WING  = (100, 45, 30, 255)
RD_BELLY = (160, 100, 60, 255)
RD_EYE   = (255, 200, 0, 255)
RD_BEAK  = (180, 140, 50, 255)
RD_DARK  = (70, 30, 20, 255)

def draw_rodan_frame(frame=0):
    img = new(60, 56)
    draw = ImageDraw.Draw(img)

    # Wing flap offset
    wf = 4 if frame == 1 else (0 if frame == 0 else -4)

    # Wings (massive, sweeping)
    draw.polygon([(6,28+wf),(0,10+wf),(12,4+wf),(26,18),(24,32)], fill=RD_WING)
    draw.polygon([(54,28+wf),(60,10+wf),(48,4+wf),(34,18),(36,32)], fill=RD_WING)
    # Wing membrane lines
    for i in range(3):
        yt = 12 + wf + i*8
        xl = 2 + i*3
        draw.line([(xl,yt),(20,30)], fill=RD_DARK, width=1)
        draw.line([(60-xl,yt),(40,30)], fill=RD_DARK, width=1)

    # Body (compact, streamlined)
    draw.ellipse([18, 18, 42, 50], fill=RD_BODY)
    # Belly
    draw.ellipse([21, 24, 39, 46], fill=RD_BELLY)

    # Neck + head (forward-leaning)
    rect(img, 24, 10, 12, 14, RD_BODY)
    # Head (flat, pterosaur-like with crest)
    rect(img, 22, 4, 16, 10, RD_BODY)
    # Crest
    draw.polygon([(30,4),(26,0),(34,0),(36,4)], fill=RD_DARK)
    # Beak
    rect(img, 20, 10, 8, 4, RD_BEAK)
    # Eye
    rect(img, 34, 6, 5, 4, RD_EYE)
    rect(img, 36, 7, 2, 2, (0,0,0,255))

    # Legs (tucked under)
    rect(img, 22, 44, 6, 10, RD_BODY)
    rect(img, 32, 44, 6, 10, RD_BODY)
    rect(img, 20, 50, 8, 4, RD_DARK)
    rect(img, 30, 50, 10, 4, RD_DARK)

    # Attack: wind gust effect
    if frame == 2:
        for gx in range(0, 16, 4):
            draw.line([(gx, 30),(gx+2, 28)], fill=(200,230,255,150), width=1)
            draw.line([(60-gx, 30),(60-gx-2, 28)], fill=(200,230,255,150), width=1)

    return img

print("Generating Rodan sprites...")
sheet = new(180, 56)
for i in range(3):
    f = draw_rodan_frame(i)
    save(f, f"{OUT}/Characters/Rodan_Frame{i}.png")
    sheet.paste(f, (i*60, 0))
save(sheet, f"{OUT}/Characters/Rodan_Sheet.png")

# ─── MECHAGODZILLA (48×80, robot kaiju — silver steel) ───────────────────────
MG_STEEL  = (160, 165, 175, 255)
MG_DARK   = (90, 95, 105, 255)
MG_PANEL  = (140, 145, 155, 255)
MG_EYE    = (255, 30, 30, 255)
MG_MISSILE= (200, 80, 30, 255)
MG_GLOW   = (100, 200, 255, 255)

def draw_mechagodzilla_frame(frame=0):
    img = new(48, 80)

    # Tail (articulated segments)
    for tx, ty, tw, th in [(0,65,6,6),(4,68,5,5),(6,70,4,4)]:
        rect(img, tx, ty, tw, th, MG_DARK)
        rect(img, tx+1, ty+1, tw-2, th-2, MG_STEEL)

    # Legs (blocky, armored)
    rect(img, 10, 60, 11, 20, MG_STEEL)
    rect(img, 27, 60, 11, 20, MG_STEEL)
    # Panel lines on legs
    rect(img, 12, 64, 7, 1, MG_DARK)
    rect(img, 29, 64, 7, 1, MG_DARK)
    # Feet (wide, flat)
    rect(img, 8, 76, 15, 6, MG_DARK)
    rect(img, 25, 76, 15, 6, MG_DARK)

    # Body (armored torso)
    rect(img, 10, 28, 28, 34, MG_STEEL)
    # Chest plate
    rect(img, 14, 32, 20, 20, MG_PANEL)
    # Chest ray emitter
    rect(img, 20, 38, 8, 6, MG_DARK)
    rect(img, 22, 39, 4, 4, MG_GLOW)

    # Missile pods on shoulders
    rect(img, 6, 28, 6, 10, MG_DARK)
    rect(img, 36, 28, 6, 10, MG_DARK)
    for mx in [7, 38]:
        for my in range(30, 36, 3):
            rect(img, mx, my, 4, 2, MG_MISSILE)

    # Arms (mechanical)
    if frame == 2:
        rect(img, 38, 34, 10, 6, MG_STEEL)
        rect(img, 0, 34, 10, 6, MG_STEEL)
    else:
        rect(img, 38, 38, 8, 5, MG_STEEL)
        rect(img, 2, 38, 8, 5, MG_STEEL)

    # Neck
    rect(img, 18, 18, 12, 12, MG_STEEL)
    rect(img, 20, 20, 8, 8, MG_PANEL)

    # Head (blocky robot head)
    rect(img, 12, 4, 24, 18, MG_STEEL)
    # Head panels
    rect(img, 14, 6, 20, 14, MG_PANEL)
    # Visor (glowing red eyes)
    rect(img, 14, 8, 20, 6, MG_DARK)
    for ex in [16, 28]:
        rect(img, ex, 9, 4, 4, MG_EYE)
    # Mouth cannon
    rect(img, 18, 18, 12, 4, MG_DARK)
    if frame == 2:
        rect(img, 18, 18, 12, 3, MG_GLOW)

    # Dorsal fin (antenna array)
    for sx, sh in [(16, 8),(21, 10),(26, 8)]:
        rect(img, sx, 4-sh//4, 2, sh//4+2, MG_DARK)

    return img

print("Generating MechaGodzilla sprites...")
sheet = new(144, 80)
for i in range(3):
    f = draw_mechagodzilla_frame(i)
    save(f, f"{OUT}/Characters/MechaGodzilla_Frame{i}.png")
    sheet.paste(f, (i*48, 0))
save(sheet, f"{OUT}/Characters/MechaGodzilla_Sheet.png")

# ─── TITAN / SUPERMAN ARCHETYPE (36×64) ──────────────────────────────────────
TI_BLUE  = (20, 50, 180, 255)
TI_RED   = (180, 20, 20, 255)
TI_GOLD  = (230, 180, 20, 255)
TI_SKIN  = (220, 170, 120, 255)
TI_CAPE  = (160, 15, 15, 255)

def draw_titan_frame(frame=0):
    img = new(36, 64)
    draw = ImageDraw.Draw(img)

    # Cape (behind body)
    if frame != 1:  # no cape when punching
        draw.polygon([(8,18),(0,60),(36,60),(28,18)], fill=TI_CAPE)
    else:
        draw.polygon([(8,18),(4,50),(30,50),(28,18)], fill=TI_CAPE)

    # Legs
    rect(img, 8, 42, 8, 22, TI_BLUE)
    rect(img, 20, 42, 8, 22, TI_BLUE)
    # Boots
    rect(img, 7, 54, 10, 10, TI_RED)
    rect(img, 19, 54, 10, 10, TI_RED)

    # Body
    rect(img, 8, 18, 20, 26, TI_BLUE)
    # S-symbol (simplified)
    rect(img, 14, 22, 8, 10, TI_RED)
    rect(img, 15, 23, 6, 8, TI_GOLD)

    # Belt
    rect(img, 8, 42, 20, 3, TI_GOLD)

    # Arms
    if frame == 2:  # attack: laser eyes, arms raised
        rect(img, 0, 16, 8, 5, TI_BLUE)
        rect(img, 28, 16, 8, 5, TI_BLUE)
        # Laser eye beams
        draw.line([(16,6),(0,0)], fill=(255,50,50,200), width=2)
        draw.line([(20,6),(36,0)], fill=(255,50,50,200), width=2)
    elif frame == 1:  # punching
        rect(img, 28, 20, 8, 5, TI_SKIN)
        rect(img, 0, 24, 8, 5, TI_BLUE)
    else:
        rect(img, 0, 22, 8, 5, TI_BLUE)
        rect(img, 28, 22, 8, 5, TI_BLUE)

    # Neck + head
    rect(img, 14, 10, 8, 10, TI_SKIN)
    draw.ellipse([10, 2, 26, 16], fill=TI_SKIN)
    # Hair
    rect(img, 10, 2, 16, 5, (20,10,0,255))
    # Eyes
    rect(img, 13, 7, 4, 3, (50,100,200,255))
    rect(img, 19, 7, 4, 3, (50,100,200,255))

    return img

print("Generating Titan sprites...")
sheet = new(108, 64)
for i in range(3):
    f = draw_titan_frame(i)
    save(f, f"{OUT}/Characters/Titan_Frame{i}.png")
    sheet.paste(f, (i*36, 0))
save(sheet, f"{OUT}/Characters/Titan_Sheet.png")

# ─── IRONCLAD / IRON MAN ARCHETYPE (36×60) ───────────────────────────────────
IC_RED   = (180, 25, 25, 255)
IC_GOLD  = (215, 160, 20, 255)
IC_GLOW  = (100, 220, 255, 255)
IC_DARK  = (100, 15, 15, 255)

def draw_ironclad_frame(frame=0):
    img = new(36, 60)
    draw = ImageDraw.Draw(img)

    # Legs (armored)
    rect(img, 8, 40, 8, 20, IC_RED)
    rect(img, 20, 40, 8, 20, IC_RED)
    # Knee plates
    rect(img, 7, 46, 10, 4, IC_GOLD)
    rect(img, 19, 46, 10, 4, IC_GOLD)
    # Feet
    rect(img, 7, 56, 10, 4, IC_GOLD)
    rect(img, 19, 56, 10, 4, IC_GOLD)

    # Torso
    rect(img, 8, 18, 20, 24, IC_RED)
    # Chest arc reactor
    rect(img, 14, 22, 8, 8, IC_DARK)
    draw.ellipse([15, 23, 21, 29], fill=IC_GLOW)

    # Waist
    rect(img, 9, 40, 18, 4, IC_GOLD)

    # Arms
    if frame == 2:  # repulsor blast
        rect(img, 0, 20, 8, 5, IC_RED)
        rect(img, 28, 20, 8, 5, IC_RED)
        draw.ellipse([0-4, 20-2, 0+2, 20+4], fill=IC_GLOW)
        draw.ellipse([34-2, 20-2, 34+4, 20+4], fill=IC_GLOW)
    elif frame == 1:
        rect(img, 28, 18, 8, 5, IC_RED)
        rect(img, 0, 24, 8, 5, IC_RED)
    else:
        rect(img, 0, 22, 8, 5, IC_RED)
        rect(img, 28, 22, 8, 5, IC_RED)

    # Neck
    rect(img, 14, 10, 8, 9, IC_RED)

    # Head (helmet)
    rect(img, 10, 2, 16, 12, IC_RED)
    # Face plate (gold)
    rect(img, 11, 4, 14, 8, IC_GOLD)
    # Eye slits
    rect(img, 12, 5, 5, 3, IC_GLOW)
    rect(img, 19, 5, 5, 3, IC_GLOW)

    return img

print("Generating Ironclad sprites...")
sheet = new(108, 60)
for i in range(3):
    f = draw_ironclad_frame(i)
    save(f, f"{OUT}/Characters/Ironclad_Frame{i}.png")
    sheet.paste(f, (i*36, 0))
save(sheet, f"{OUT}/Characters/Ironclad_Sheet.png")

# ─── WEBSLINGER / SPIDER-MAN ARCHETYPE (32×56) ───────────────────────────────
WS_RED   = (180, 20, 20, 255)
WS_BLUE  = (20, 30, 150, 255)
WS_WEB   = (220, 220, 220, 150)
WS_DARK  = (120, 10, 10, 255)

def draw_webslinger_frame(frame=0):
    img = new(32, 56)
    draw = ImageDraw.Draw(img)

    # Legs (slender, acrobatic)
    if frame == 1:  # crouching
        rect(img, 6, 38, 7, 14, WS_BLUE)
        rect(img, 19, 36, 7, 16, WS_BLUE)
    else:
        rect(img, 6, 36, 7, 20, WS_BLUE)
        rect(img, 19, 36, 7, 20, WS_BLUE)
    # Boots
    rect(img, 5, 50, 9, 6, WS_RED)
    rect(img, 18, 50, 9, 6, WS_RED)

    # Body
    rect(img, 8, 18, 16, 20, WS_RED)
    # Web pattern (diagonal lines)
    for i in range(4):
        draw.line([(8+i*4, 18),(8, 18+i*4)], fill=WS_DARK, width=1)
        draw.line([(8+i*4, 36),(24, 36-i*4)], fill=WS_DARK, width=1)

    # Blue sides
    rect(img, 8, 18, 3, 20, WS_BLUE)
    rect(img, 21, 18, 3, 20, WS_BLUE)
    rect(img, 8, 34, 16, 4, WS_BLUE)

    # Arms
    if frame == 2:  # web shot
        rect(img, 0, 18, 8, 4, WS_RED)
        rect(img, 24, 18, 8, 4, WS_RED)
        draw.line([(0, 20),(0-8, 15)], fill=WS_WEB, width=1)
        draw.line([(32, 20),(32+8, 15)], fill=WS_WEB, width=1)
    else:
        rect(img, 0, 22, 8, 4, WS_RED)
        rect(img, 24, 22, 8, 4, WS_RED)

    # Neck + head (masked)
    rect(img, 12, 10, 8, 10, WS_RED)
    draw.ellipse([8, 2, 24, 16], fill=WS_RED)
    # Mask web lines
    draw.line([(16, 2),(8, 10)], fill=WS_DARK, width=1)
    draw.line([(16, 2),(24, 10)], fill=WS_DARK, width=1)
    draw.line([(16, 2),(16, 16)], fill=WS_DARK, width=1)
    # Eye lenses (white, large)
    draw.ellipse([9, 4, 15, 10], fill=(255,255,255,230))
    draw.ellipse([17, 4, 23, 10], fill=(255,255,255,230))

    return img

print("Generating Webslinger sprites...")
sheet = new(96, 56)
for i in range(3):
    f = draw_webslinger_frame(i)
    save(f, f"{OUT}/Characters/Webslinger_Frame{i}.png")
    sheet.paste(f, (i*32, 0))
save(sheet, f"{OUT}/Characters/Webslinger_Sheet.png")

# ─── THUNDERSTRIKE / THOR ARCHETYPE (36×64) ──────────────────────────────────
TS_ARMOR = (80, 120, 180, 255)
TS_CAPE  = (180, 15, 15, 255)
TS_GOLD  = (210, 170, 30, 255)
TS_SKIN  = (220, 175, 120, 255)
TS_HAIR  = (220, 200, 50, 255)
TS_HAMMR = (130, 135, 145, 255)

def draw_thunderstrike_frame(frame=0):
    img = new(36, 64)
    draw = ImageDraw.Draw(img)

    # Cape (flowing red)
    draw.polygon([(10,16),(2,60),(34,60),(26,16)], fill=TS_CAPE)

    # Legs
    rect(img, 8, 42, 8, 22, TS_ARMOR)
    rect(img, 20, 42, 8, 22, TS_ARMOR)
    # Greaves (gold)
    rect(img, 7, 50, 10, 12, TS_GOLD)
    rect(img, 19, 50, 10, 12, TS_GOLD)

    # Body
    rect(img, 8, 18, 20, 26, TS_ARMOR)
    # Chest disc (gold)
    rect(img, 13, 22, 10, 14, TS_GOLD)
    rect(img, 14, 23, 8, 12, TS_ARMOR)
    # Belt
    rect(img, 8, 42, 20, 3, TS_GOLD)

    # Arms
    if frame == 2:  # hammer raised / lightning
        rect(img, 28, 10, 8, 5, TS_SKIN)   # arm up
        rect(img, 0, 24, 8, 5, TS_ARMOR)
        # Hammer
        rect(img, 33, 2, 6, 8, TS_HAMMR)
        rect(img, 35, 8, 2, 6, TS_GOLD)
        # Lightning
        draw.line([(36, 10),(48, 0)], fill=(200,220,255,200), width=2)
    elif frame == 1:
        rect(img, 28, 20, 8, 5, TS_SKIN)
        rect(img, 0, 24, 8, 5, TS_ARMOR)
        # Hammer at side
        rect(img, 33, 20, 5, 8, TS_HAMMR)
        rect(img, 34, 26, 2, 5, TS_GOLD)
    else:
        rect(img, 0, 22, 8, 5, TS_ARMOR)
        rect(img, 28, 22, 8, 5, TS_ARMOR)

    # Neck + head
    rect(img, 14, 10, 8, 10, TS_SKIN)
    draw.ellipse([10, 2, 26, 16], fill=TS_SKIN)
    # Long blonde hair
    rect(img, 8, 4, 4, 12, TS_HAIR)
    rect(img, 24, 4, 4, 12, TS_HAIR)
    rect(img, 10, 14, 3, 6, TS_HAIR)
    rect(img, 23, 14, 3, 6, TS_HAIR)
    # Winged helmet
    rect(img, 10, 2, 16, 6, TS_ARMOR)
    # Wings on helmet
    draw.polygon([(10,2),(4,0),(6,6)], fill=(230,230,230,255))
    draw.polygon([(26,2),(32,0),(30,6)], fill=(230,230,230,255))
    # Eyes
    rect(img, 13, 7, 4, 3, (50,80,150,255))
    rect(img, 19, 7, 4, 3, (50,80,150,255))
    # Beard
    rect(img, 13, 14, 10, 4, TS_HAIR)

    return img

print("Generating Thunderstrike sprites...")
sheet = new(108, 64)
for i in range(3):
    f = draw_thunderstrike_frame(i)
    save(f, f"{OUT}/Characters/Thunderstrike_Frame{i}.png")
    sheet.paste(f, (i*36, 0))
save(sheet, f"{OUT}/Characters/Thunderstrike_Sheet.png")

# ─── BIOLLANTE (80×72, giant rose/plant kaiju) ───────────────────────────────
BI_GREEN = (40, 130, 50, 255)
BI_DARK  = (20, 70, 25, 255)
BI_THORN = (200, 220, 50, 255)
BI_MOUTH = (160, 40, 40, 255)
BI_SAP   = (80, 200, 80, 200)

def draw_biollante_frame(frame=0):
    img = new(80, 72)
    draw = ImageDraw.Draw(img)

    # Vine/roots at base
    for vx, vh in [(10,20),(25,15),(40,25),(55,18),(65,22)]:
        rect(img, vx, 52+max(0,20-vh), 5, vh, BI_DARK)
        # Thorns
        pixel(img, vx-1, 52+max(0,20-vh)+5, BI_THORN)

    # Main body (massive plant form)
    draw.ellipse([15, 20, 65, 65], fill=BI_GREEN)
    # Inner darker mass
    draw.ellipse([22, 28, 58, 58], fill=BI_DARK)

    # Rose petals (surrounding)
    petal_positions = [(10,15),(25,8),(40,6),(55,10),(68,18),(72,35),(68,52)]
    for px, py in petal_positions:
        draw.ellipse([px-8,py-6,px+8,py+6], fill=BI_GREEN)

    # Maw (giant mouth with teeth)
    draw.ellipse([20, 30, 60, 58], fill=BI_MOUTH)
    # Teeth
    for tx in range(22, 58, 6):
        rect(img, tx, 30, 4, 6, (230,220,190,255))  # upper teeth
        rect(img, tx, 52, 4, 5, (230,220,190,255))  # lower teeth

    # Eyes (glowing yellow)
    draw.ellipse([24, 22, 34, 30], fill=(255,220,0,255))
    draw.ellipse([46, 22, 56, 30], fill=(255,220,0,255))
    draw.ellipse([26, 23, 32, 28], fill=(0,0,0,255))
    draw.ellipse([48, 23, 54, 28], fill=(0,0,0,255))

    # Acid spit on attack
    if frame == 2:
        draw.line([(40, 44),(40, 65),(20, 72)], fill=BI_SAP, width=4)

    return img

print("Generating Biollante sprites...")
sheet = new(240, 72)
for i in range(3):
    f = draw_biollante_frame(i)
    save(f, f"{OUT}/Characters/Biollante_Frame{i}.png")
    sheet.paste(f, (i*80, 0))
save(sheet, f"{OUT}/Characters/Biollante_Sheet.png")

# ─── DESTOROYAH (52×80, dark crustacean demon) ───────────────────────────────
DY_BODY  = (90, 20, 30, 255)
DY_DARK  = (50, 10, 15, 255)
DY_HORN  = (160, 40, 50, 255)
DY_EYE   = (255, 80, 0, 255)
DY_GLOW  = (200, 40, 220, 255)

def draw_destoroyah_frame(frame=0):
    img = new(52, 80)
    draw = ImageDraw.Draw(img)

    # Wings/fins (fanned behind)
    draw.polygon([(4,20),(0,5),(12,10),(20,28)], fill=DY_DARK)
    draw.polygon([(48,20),(52,5),(40,10),(32,28)], fill=DY_DARK)

    # Tail
    draw.polygon([(8,70),(4,76),(2,80),(10,78),(14,72)], fill=DY_BODY)

    # Legs
    rect(img, 14, 60, 9, 18, DY_BODY)
    rect(img, 29, 60, 9, 18, DY_BODY)
    rect(img, 12, 74, 12, 6, DY_DARK)
    rect(img, 28, 74, 12, 6, DY_DARK)

    # Body (armored)
    rect(img, 12, 26, 28, 36, DY_BODY)
    # Armor plates
    for py in range(28, 60, 8):
        rect(img, 12, py, 28, 2, DY_DARK)

    # Claws/arms
    if frame == 2:
        rect(img, 40, 28, 12, 8, DY_BODY)
        rect(img, 0, 28, 12, 8, DY_BODY)
        rect(img, 48, 28, 6, 4, DY_HORN)  # claw
        rect(img, 0, 28, 4, 4, DY_HORN)
    else:
        rect(img, 38, 32, 10, 6, DY_BODY)
        rect(img, 4, 32, 10, 6, DY_BODY)

    # Neck
    rect(img, 18, 14, 16, 14, DY_BODY)

    # Head (crested, demonic)
    rect(img, 14, 4, 24, 14, DY_BODY)
    # Horn cluster
    for hx, hy, hw, hh in [(18,0,3,6),(24,0,4,8),(30,0,3,6),(22,-2,2,4),(26,-2,2,4)]:
        rect(img, hx, hy, hw, hh, DY_HORN)
    # Eyes (glowing orange)
    rect(img, 16, 6, 6, 5, DY_EYE)
    rect(img, 30, 6, 6, 5, DY_EYE)
    rect(img, 17, 7, 4, 3, (0,0,0,255))
    rect(img, 31, 7, 4, 3, (0,0,0,255))
    # Chest glowspot (micro-oxygen beam)
    if frame == 2:
        draw.ellipse([20, 40, 32, 52], fill=DY_GLOW)

    return img

print("Generating Destoroyah sprites...")
sheet = new(156, 80)
for i in range(3):
    f = draw_destoroyah_frame(i)
    save(f, f"{OUT}/Characters/Destoroyah_Frame{i}.png")
    sheet.paste(f, (i*52, 0))
save(sheet, f"{OUT}/Characters/Destoroyah_Sheet.png")

# ─── GIGAN (52×80, cyborg kaiju — buzzsaw) ───────────────────────────────────
GI_BODY  = (80, 90, 70, 255)
GI_METAL = (160, 165, 155, 255)
GI_SAW   = (200, 180, 30, 255)
GI_EYE   = (255, 0, 50, 255)
GI_HOOK  = (180, 170, 140, 255)

def draw_gigan_frame(frame=0):
    img = new(52, 80)
    draw = ImageDraw.Draw(img)

    # Crest/head fin
    draw.polygon([(26,0),(18,2),(16,8),(36,8),(34,2)], fill=GI_METAL)

    # Head (angular, visor eye)
    rect(img, 16, 4, 20, 16, GI_BODY)
    # Single visor eye (red)
    rect(img, 16, 8, 20, 6, GI_EYE)
    rect(img, 17, 9, 18, 4, (180,0,30,255))
    # Cyclops pupil
    rect(img, 24, 9, 4, 4, (0,0,0,255))
    # Beak
    rect(img, 22, 18, 8, 5, GI_HOOK)

    # Neck
    rect(img, 20, 18, 12, 10, GI_BODY)

    # Body
    rect(img, 14, 26, 24, 34, GI_BODY)
    # Buzzsaw in chest (center)
    r = 8
    cx, cy = 26, 42
    draw.ellipse([cx-r, cy-r, cx+r, cy+r], fill=GI_SAW)
    draw.ellipse([cx-r+2, cy-r+2, cx+r-2, cy+r-2], fill=GI_METAL)
    # Saw teeth
    for a in range(0, 360, 45):
        import math
        ax = int(cx + r * math.cos(math.radians(a)))
        ay = int(cy + r * math.sin(math.radians(a)))
        pixel(img, ax, ay, GI_SAW)

    # Blade arms (hooks instead of hands)
    if frame == 2:
        draw.polygon([(38,28),(52,24),(50,32),(40,34)], fill=GI_HOOK)
        draw.polygon([(14,28),(0,24),(2,32),(12,34)], fill=GI_HOOK)
    else:
        draw.polygon([(38,32),(48,28),(46,36),(38,38)], fill=GI_HOOK)
        draw.polygon([(14,32),(4,28),(6,36),(14,38)], fill=GI_HOOK)

    # Legs
    rect(img, 16, 58, 9, 20, GI_BODY)
    rect(img, 27, 58, 9, 20, GI_BODY)
    rect(img, 14, 74, 12, 6, GI_METAL)
    rect(img, 26, 74, 12, 6, GI_METAL)

    # Tail
    draw.polygon([(10,70),(0,78),(6,80),(14,72)], fill=GI_BODY)

    return img

print("Generating Gigan sprites...")
sheet = new(156, 80)
for i in range(3):
    f = draw_gigan_frame(i)
    save(f, f"{OUT}/Characters/Gigan_Frame{i}.png")
    sheet.paste(f, (i*52, 0))
save(sheet, f"{OUT}/Characters/Gigan_Sheet.png")

# ─── SPACEGODZILLA (52×84, crystal-armored clone) ────────────────────────────
SG_BODY   = (70, 40, 100, 255)
SG_CRYST  = (180, 100, 255, 255)
SG_DARK   = (45, 20, 65, 255)
SG_EYE    = (200, 100, 255, 255)
SG_BEAM   = (220, 150, 255, 255)

def draw_spacegodzilla_frame(frame=0):
    img = new(52, 84)
    draw = ImageDraw.Draw(img)

    # Crystal shoulder formations (large, dramatic)
    draw.polygon([(0,28),(0,10),(8,4),(14,14),(12,30)], fill=SG_CRYST)
    draw.polygon([(52,28),(52,10),(44,4),(38,14),(40,30)], fill=SG_CRYST)
    # Crystal facets
    draw.line([(2,22),(10,8)], fill=(255,200,255,200), width=1)
    draw.line([(50,22),(42,8)], fill=(255,200,255,200), width=1)

    # Tail (crystal-tipped)
    draw.polygon([(2,74),(0,78),(0,82),(6,80),(10,74)], fill=SG_BODY)
    pixel(img, 0, 84, SG_CRYST)

    # Legs
    rect(img, 14, 62, 10, 20, SG_BODY)
    rect(img, 28, 62, 10, 20, SG_BODY)
    rect(img, 12, 78, 14, 6, SG_DARK)
    rect(img, 26, 78, 14, 6, SG_DARK)

    # Body
    rect(img, 12, 28, 28, 36, SG_BODY)
    # Crystal chest plate
    draw.polygon([(12,28),(26,20),(40,28),(40,44),(26,50),(12,44)], fill=SG_CRYST)
    draw.polygon([(16,32),(26,26),(36,32),(36,42),(26,46),(16,42)], fill=SG_DARK)
    # Glow core
    draw.ellipse([22, 34, 30, 42], fill=SG_BEAM)

    # Arms
    if frame == 2:
        rect(img, 40, 30, 10, 5, SG_BODY)
        rect(img, 2, 30, 10, 5, SG_BODY)
    else:
        rect(img, 40, 34, 10, 5, SG_BODY)
        rect(img, 2, 34, 10, 5, SG_BODY)

    # Neck
    rect(img, 20, 16, 12, 14, SG_BODY)

    # Head (Godzilla-ish but purple/crystal)
    rect(img, 14, 4, 24, 16, SG_BODY)
    # Dorsal crystal spines (on head)
    for sx in [14, 20, 26, 32, 38]:
        rect(img, sx, 0, 3, 6, SG_CRYST)
    # Eyes
    rect(img, 30, 6, 7, 5, SG_EYE)
    rect(img, 32, 7, 3, 3, (0,0,0,255))
    # Jaw
    rect(img, 16, 16, 20, 5, SG_DARK)

    # Beam attack
    if frame == 2:
        draw.line([(26, 12),(26, -2)], fill=SG_BEAM, width=3)

    return img

print("Generating SpaceGodzilla sprites...")
sheet = new(156, 84)
for i in range(3):
    f = draw_spacegodzilla_frame(i)
    save(f, f"{OUT}/Characters/SpaceGodzilla_Frame{i}.png")
    sheet.paste(f, (i*52, 0))
save(sheet, f"{OUT}/Characters/SpaceGodzilla_Sheet.png")

# ─── HEDORAH (64×64, blob smog monster) ─────────────────────────────────────
HE_SLUDGE= (50, 75, 45, 255)
HE_DARK  = (25, 40, 20, 255)
HE_EYE   = (200, 220, 0, 255)
HE_DRIP  = (60, 100, 50, 200)

def draw_hedorah_frame(frame=0):
    img = new(64, 64)
    draw = ImageDraw.Draw(img)

    # Blob body (amorphous)
    blob_offset = 3 if frame == 1 else 0
    draw.ellipse([8, 16+blob_offset, 56, 58+blob_offset//2], fill=HE_SLUDGE)
    draw.ellipse([12, 20, 52, 54], fill=HE_DARK)

    # Lumps/protrusions
    draw.ellipse([6, 24, 24, 44], fill=HE_SLUDGE)
    draw.ellipse([40, 22, 58, 42], fill=HE_SLUDGE)
    draw.ellipse([22, 10, 42, 30], fill=HE_SLUDGE)

    # Drips at bottom
    for dx in [14, 26, 38, 50]:
        draw.polygon([(dx,56),(dx-3,64),(dx+3,64),(dx+1,56)], fill=HE_DRIP)

    # Eyes (compound, asymmetric)
    draw.ellipse([16, 18, 28, 28], fill=HE_EYE)
    draw.ellipse([36, 16, 52, 30], fill=HE_EYE)
    draw.ellipse([18, 20, 24, 26], fill=(0,0,0,255))
    draw.ellipse([39, 18, 48, 28], fill=(0,0,0,255))

    # Sludge attack
    if frame == 2:
        for sx in range(10, 55, 8):
            draw.polygon([(sx,54),(sx-4,64),(sx+4,64)], fill=HE_DRIP)

    return img

print("Generating Hedorah sprites...")
sheet = new(192, 64)
for i in range(3):
    f = draw_hedorah_frame(i)
    save(f, f"{OUT}/Characters/Hedorah_Frame{i}.png")
    sheet.paste(f, (i*64, 0))
save(sheet, f"{OUT}/Characters/Hedorah_Sheet.png")

# ─── ANGUIRUS (56×56, ankylosaur — spiky back) ───────────────────────────────
AN_BODY  = (100, 80, 55, 255)
AN_SPIKE = (130, 105, 60, 255)
AN_BELLY = (140, 120, 80, 255)
AN_EYE   = (255, 200, 0, 255)
AN_DARK  = (65, 50, 30, 255)

def draw_anguirus_frame(frame=0):
    img = new(56, 56)
    draw = ImageDraw.Draw(img)

    # Spiky armored shell (back)
    draw.ellipse([6, 10, 50, 44], fill=AN_BODY)
    # Spike row
    spike_positions = [(10,14,3,8),(16,8,3,10),(22,4,3,12),(28,2,4,12),(34,6,3,10),(40,10,3,8),(44,16,2,6)]
    for sx,sy,sw,sh in spike_positions:
        draw.polygon([(sx,sy+sh),(sx+sw//2,sy),(sx+sw,sy+sh)], fill=AN_SPIKE)

    # Belly (lighter)
    draw.ellipse([14, 30, 44, 50], fill=AN_BELLY)

    # Head (low to ground, snout)
    rect(img, 36, 24, 18, 10, AN_BODY)
    # Snout
    rect(img, 48, 26, 8, 6, AN_DARK)
    # Eye
    rect(img, 42, 24, 5, 4, AN_EYE)
    rect(img, 43, 25, 3, 2, (0,0,0,255))
    # Brow horn
    draw.polygon([(40,24),(38,18),(44,22)], fill=AN_SPIKE)

    # Legs (short, thick)
    rect(img, 10, 42, 8, 12, AN_BODY)
    rect(img, 22, 44, 8, 10, AN_BODY)
    rect(img, 36, 44, 8, 10, AN_BODY)
    rect(img, 8, 50, 10, 6, AN_DARK)
    rect(img, 20, 52, 10, 4, AN_DARK)
    rect(img, 34, 52, 10, 4, AN_DARK)

    # Tail (curled)
    draw.polygon([(8,40),(0,44),(0,50),(6,52),(10,46),(8,40)], fill=AN_BODY)

    # Rolling attack effect
    if frame == 2:
        draw.arc([4, 6, 52, 54], 0, 360, fill=(200,180,100,150), width=2)

    return img

print("Generating Anguirus sprites...")
sheet = new(168, 56)
for i in range(3):
    f = draw_anguirus_frame(i)
    save(f, f"{OUT}/Characters/Anguirus_Frame{i}.png")
    sheet.paste(f, (i*56, 0))
save(sheet, f"{OUT}/Characters/Anguirus_Sheet.png")

print("\n✅ All sprites generated!")
print(f"   Output: {OUT}/")
