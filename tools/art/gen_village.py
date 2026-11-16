"""Throwaway generator for story 008: writes village_layout.json and patches village_tuning.json."""
import json
import math
import random
import re

ROOT = "E:/GodotProject/ninja-city-simulation/assets/data/"
N = 20
rng = random.Random(8)

# ---------------------------------------------------------------- ground map
grid = [["."] * N for _ in range(N)]


def put(i, j, ch):
    grid[j][i] = ch


MAIN = 9
PLATFORM_J, TRACK_J, WATER_J = 16, 17, 18
for j in range(0, 16):
    put(MAIN, j, "#")                      # main street, gate (j=0) to the platform
for i in range(1, 14):
    put(i, 2, "#")                         # back lane
    put(i, 4, "#")                         # cross street 1
for i in range(1, 19):
    put(i, 6, "#")                         # cross street 2 (north of the plaza)
for i in range(1, 17):
    put(i, 12, "#")                        # cross street 3 (south of the plaza, stops at the river)
for j in range(7, 12):
    for i in range(7, 12):
        put(i, j, "+")                     # plaza
for j in range(1, 5):
    for i in range(14, 19):
        put(i, j, "T")                     # training yard (sand)
for i in range(1, 19):
    put(i, PLATFORM_J, "P")
for i in range(N):
    put(i, TRACK_J, "=")
put(MAIN, 16, "P")
put(2, WATER_J, "w")
put(3, WATER_J, "w")
rows = ["".join(r) for r in grid]

# ---------------------------------------------------------------- lots
lots = {
    "gate": {"i": 9, "j": 0, "w": 1, "h": 1},
    "training": {"i": 14, "j": 1, "w": 5, "h": 4},
    "market": {"i": 11, "j": 13, "w": 6, "h": 2},
    "academy": {"i": 12, "j": 7, "w": 5, "h": 4},
    "hospital": {"i": 1, "j": 7, "w": 5, "h": 4},
    "forest": {"i": 1, "j": 13, "w": 6, "h": 2},
    "river": {"i": 17, "j": 7, "w": 2, "h": 8},
}


def in_lot(i, j):
    for lot in lots.values():
        if lot["i"] <= i < lot["i"] + lot["w"] and lot["j"] <= j < lot["j"] + lot["h"]:
            return True
    return False


names = list(lots)
for a in range(len(names)):
    for b in range(a + 1, len(names)):
        A, B = lots[names[a]], lots[names[b]]
        assert (A["i"] + A["w"] <= B["i"] or B["i"] + B["w"] <= A["i"] or
                A["j"] + A["h"] <= B["j"] or B["j"] + B["h"] <= A["j"]), (names[a], names[b])

# ---------------------------------------------------------------- buildings
building_rows = {
    1: list(range(1, 9)) + list(range(10, 14)),
    3: list(range(1, 9)) + list(range(10, 14)),
    5: list(range(1, 9)) + list(range(10, 19)),
    11: list(range(1, 7)) + list(range(12, 17)),
    15: list(range(1, 9)) + [10] + list(range(14, 19)),
}
SKIP = 0.2
placements = []
doors = []
decor_cycle = ["plant", "barrel", "crates", "bench", "tree_small", "plant", "barrel", "crates"]
decor_n = 0
n_buildings = 0
for j, slots in building_rows.items():
    for i in slots:
        assert grid[j][i] == "." and not in_lot(i, j), (i, j)
        assert grid[j + 1][i] in "#P+", (i, j)
        if rng.random() < SKIP:
            sprite = decor_cycle[decor_n % len(decor_cycle)]
            decor_n += 1
            placements.append({"sprite": sprite, "i": round(i + 0.5 + rng.uniform(-0.12, 0.12), 2),
                               "j": round(j + 0.55 + rng.uniform(-0.1, 0.1), 2)})
            continue
        near_plaza = abs(i - MAIN) <= 4 and j in (5, 11)
        if near_plaza and rng.random() < 0.7:
            sprite, kind = "shop", "shop"
        else:
            roll = rng.random()
            sprite = "house_block" if roll < 0.4 else ("house_hip" if roll < 0.8 else "tower")
            kind = "home"
        placements.append({"sprite": sprite, "i": i + 0.5, "j": j + 0.5})
        doors.append({"i": i, "j": j, "door": [i, j + 1], "kind": kind})
        n_buildings += 1
# station
placements.append({"sprite": "station", "i": 12.0, "j": 15.5})
for di in (11, 12, 13):
    doors.append({"i": di, "j": 15, "door": [di, 16], "kind": "station"})
n_buildings += 1
doors.sort(key=lambda d: (d["j"], d["i"]))
print("buildings", n_buildings, "homes", sum(d["kind"] == "home" for d in doors),
      "shops", sum(d["kind"] == "shop" for d in doors))

# lanterns on street corners
lantern_pts = []
for j, xs in {2: [4.9, 8.1, 10.1], 4: [4.9, 8.1, 10.1, 13.1], 6: [4.9, 8.1, 10.1, 13.9, 16.9],
              12: [4.9, 8.1, 10.1, 13.9, 16.9]}.items():
    for x in xs:
        lantern_pts.append((x, j + 0.9))
for x in (3.5, 8.5, 15.5):
    lantern_pts.append((x, 16.2))
for x, y in lantern_pts:
    placements.append({"sprite": "lantern", "i": x, "j": y})
print("lanterns", len(lantern_pts))

# plaza and street clutter
for sprite, x, y in [("bench", 7.4, 7.6), ("bench", 11.5, 7.6), ("plant", 7.5, 11.0), ("plant", 11.4, 11.0),
                     ("barrel", 6.4, 8.5), ("crates", 6.5, 9.7), ("bench", 12.0, 12.8), ("plant", 8.5, 13.5),
                     ("barrel", 10.4, 14.3), ("crates", 7.5, 14.5), ("bench", 3.5, 15.9)]:
    placements.append({"sprite": sprite, "i": x, "j": y})

# training yard props
for x in (14.6, 15.6, 16.6):
    placements.append({"sprite": "post", "i": x, "j": 1.5})
placements.append({"sprite": "target", "i": 17.6, "j": 1.7})

# trees inside the wall, in gaps
for sprite, x, y in [("tree_big", 6.5, 8.4), ("tree_small", 6.4, 10.3), ("tree_big", 7.9, 13.6),
                     ("tree_small", 10.6, 13.7), ("tree_big", 17.5, 5.2 + 0.0)]:
    if sprite == "tree_big" and (x, y) == (17.5, 5.2):
        continue
    placements.append({"sprite": sprite, "i": x, "j": y})

# the wall ring
wall = []
for i in range(1, N - 1):
    for j in (0, N - 1):
        if (i, j) == (MAIN, 0):
            continue
        wall.append({"sprite": "wall_i", "i": i + 0.5, "j": j + 0.5})
for j in range(1, N - 1):
    for i in (0, N - 1):
        if j == TRACK_J:
            continue
        wall.append({"sprite": "wall_j", "i": i + 0.5, "j": j + 0.5})
for i in (0, N - 1):
    for j in (0, N - 1):
        wall.append({"sprite": "wall_corner", "i": i + 0.5, "j": j + 0.5})
placements += wall

# giant tree ring outside the wall
ring = []
step = 1.3
a = -3.4
cols = []
while a < N + 3.4:
    cols.append(a)
    a += step
for x in cols:
    for y in cols:
        px = x + rng.uniform(-0.3, 0.3)
        py = y + rng.uniform(-0.3, 0.3)
        if -0.9 <= px <= N + 0.9 and -0.9 <= py <= N + 0.9:
            continue
        if px < -3.2 or px > N + 3.3 or py < -3.2 or py > N + 3.3:
            continue
        if (px < 0 or px > N) and TRACK_J - 0.9 <= py <= TRACK_J + 1.8:
            continue                      # keep the track corridor clear
        if py < 0 and abs(px - (MAIN + 0.5)) < 1.3:
            continue                      # keep the road out of the gate clear
        ring.append({"sprite": "tree_big" if rng.random() < 0.62 else "tree_small",
                     "i": round(px, 2), "j": round(py, 2)})
print("ring trees", len(ring))
placements += ring

# ---------------------------------------------------------------- write layout
src = json.load(open(ROOT + "village_layout.json"))
sprites = src["sprites"]
sprites["wall_i"] = {"w": 64, "h": 48, "frames": 1, "ax": 32, "ay": 32}
sprites["wall_j"] = {"w": 64, "h": 48, "frames": 1, "ax": 32, "ay": 32}
sprites["wall_corner"] = {"w": 64, "h": 64, "frames": 1, "ax": 32, "ay": 48}


def js(v):
    return json.dumps(v, separators=(", ", ": "))


out = ["{"]
out.append('\t"size": %d,' % N)
out.append('\t"tile_width": 64,')
out.append('\t"tile_height": 32,')
out.append('\t"ground_margin": 10,')
out.append('\t"track_row": %s,' % (TRACK_J + 0.5))
out.append('\t"flower_rule": ' + js(src["flower_rule"]) + ",")
out.append('\t"building_sprites": ' + js(src["building_sprites"]) + ",")
out.append('\t"tile_names": ' + js(src["tile_names"]) + ",")
out.append('\t"tile_legend": ' + js(src["tile_legend"]) + ",")
out.append('\t"lots": {')
out.append(",\n".join('\t\t"%s": %s' % (k, js(v)) for k, v in lots.items()))
out.append("\t},")
out.append('\t"map": [')
out.append(",\n".join('\t\t"%s"' % r for r in rows))
out.append("\t],")
out.append('\t"placements": [')
out.append(",\n".join("\t\t" + js(p) for p in placements))
out.append("\t],")
out.append('\t"doors": [')
out.append(",\n".join("\t\t" + js(d) for d in doors))
out.append("\t],")
out.append('\t"sprites": {')
out.append(",\n".join('\t\t"%s": %s' % (k, js(v)) for k, v in sprites.items()))
out.append("\t}")
out.append("}")
text = "\n".join(out) + "\n"
json.loads(text)
open(ROOT + "village_layout.json", "w", newline="\n").write(text)
print("map:")
for j, r in enumerate(rows):
    print("%2d %s" % (j, r))

# ---------------------------------------------------------------- tuning
homes = [d for d in doors if d["kind"] == "home" and d["door"][1] in (6, 12)]
homes.sort(key=lambda d: abs(d["door"][0] - 9) + abs(d["door"][1] - 9))
kid_doors = []
for d in homes:
    if len(kid_doors) < 3 and all(abs(d["door"][0] - k[0]) + abs(d["door"][1] - k[1]) > 3 for k in kid_doors):
        kid_doors.append(d["door"])
print("kid doors", kid_doors)

types = ["ninja"] * 15 + ["kunoichi"] * 8 + ["elder"] * 7
random.Random(3).shuffle(types)

tt = open(ROOT + "village_tuning.json", newline="").read()


def setv(key, value):
    global tt
    pat = re.compile(r'^(\t"%s": ).*?(,?)$' % re.escape(key), re.M)
    assert pat.search(tt), key
    tt = pat.sub(lambda m: m.group(1) + js(value) + m.group(2), tt, count=1)


for key, value in {
    "drift_x": 250, "drift_y": 115, "cam_range_x": 320, "cam_range_y": 185, "cam_range_up_extra": 25,
    "start_offset_y": -30, "drift_centre_offset_y": -50,
    "train_stop_i": 15.8, "train_enter_i": -8, "train_exit_i": 44, "train_platform_min_i": 8,
    "residents": 30, "villager_types": types, "night_watch": 3,
    "kid_home_doors": kid_doors, "tag_centre": [9, 9], "tag_radius": 5,
    "rooftop_rows": [1, 3, 5, 11],
    "spar_tile_a": [15, 3], "spar_spot_a": [15.6, 3.0], "spar_tile_b": [16, 2], "spar_spot_b": [16.5, 2.1],
    "spar_watch_tiles": [[14, 4], [15, 4], [17, 4], [18, 4], [13, 4]],
    "hawk_perch_tile": [12.0, 15.5], "hawk_collect_tile": [14, 16],
    "cat_home": [17, 6], "cat_bird_row": 6, "cat_bird_min_i": 10, "cat_bird_max_i": 13,
}.items():
    setv(key, value)
if '"check_walkable_keys"' not in tt:
    tt = tt.replace(
        '\t"kid_speed": 2.3,',
        '\t"check_walkable_keys": ["kid_home_doors", "tag_centre", "spar_tile_a", "spar_tile_b", "spar_watch_tiles", '
        '"hawk_collect_tile", "cat_home"],\n'
        '\t"check_inside_keys": ["spar_spot_a", "spar_spot_b", "hawk_perch_tile"],\n'
        '\t"lots_on_street_ok": ["gate", "training"],\n\t"kid_speed": 2.3,')
json.loads(tt)
open(ROOT + "village_tuning.json", "w", newline="\n").write(tt)
print("tuning ok")
