import json, sys, math
ROOT = "E:/GodotProject/ninja-city-simulation/assets/data/"
LP, TP = ROOT + "village_layout.json", ROOT + "village_tuning.json"

def dump_layout(d):
    out = ["{"]
    keys = list(d.keys())
    for n, k in enumerate(keys):
        v = d[k]; comma = "," if n < len(keys) - 1 else ""
        if k in ("lots", "sprites"):
            out.append('\t"%s": {' % k)
            items = list(v.items())
            for m, (kk, vv) in enumerate(items):
                out.append('\t\t%s: %s%s' % (json.dumps(kk), json.dumps(vv), "," if m < len(items) - 1 else ""))
            out.append("\t}" + comma)
        elif k in ("map", "placements", "doors"):
            out.append('\t"%s": [' % k)
            for m, vv in enumerate(v):
                out.append('\t\t%s%s' % (json.dumps(vv), "," if m < len(v) - 1 else ""))
            out.append("\t]" + comma)
        else:
            out.append('\t"%s": %s%s' % (k, json.dumps(v), comma))
    return "\n".join(out) + "\n"

src = open(LP, encoding="utf-8", newline="").read()
d = json.loads(src)
print("layout roundtrip identical:", dump_layout(d) == src)
if "tile_frames" in d:
    sys.exit("already applied")

# --- map ---
rows = [list(r) for r in d["map"]]
def setc(i, j, c): rows[j][i] = c
for j in range(7, 15):
    setc(16, j, "r"); setc(17, j, "w")
setc(16, 12, "b"); setc(17, 12, "b")
for j in range(7, 13): setc(18, j, "#")
setc(4, 10, "#"); setc(4, 11, "#")
for j in (13, 14):
    for i in range(1, 7): setc(i, j, "f")
d["map"] = ["".join(r) for r in rows]
d["building_sprites"] = d["building_sprites"] + ["hospital"]
d["tile_names"] = d["tile_names"] + ["forest_dark", "riverbank"]
leg = d["tile_legend"]; leg["f"] = "forest_dark"; leg["r"] = "riverbank"; leg["b"] = "bridge"
nd = {}
for k, v in d.items():
    nd[k] = v
    if k == "tile_legend": nd["tile_frames"] = {"bridge": "water"}
d = nd
d["lots"]["academy"] = {"i": 12, "j": 7, "w": 4, "h": 4}
d["lots"]["market"] = {"i": 11, "j": 13, "w": 5, "h": 2}
d["lots"]["river"] = {"i": 16, "j": 7, "w": 2, "h": 8}

# --- placements ---
P = d["placements"]
before = len(P)
P = [p for p in P if not (p["sprite"] in ("post", "target") and 14 <= p["i"] < 19 and 1 <= p["j"] < 5)]
print("removed training props:", before - len(P))
for p in P:
    if p["sprite"] == "lantern" and (p["i"], p["j"]) == (16.9, 12.9): p["i"], p["j"] = 15.1, 12.9; print("moved lantern -> 15.1,12.9")
    if p["sprite"] == "lantern" and (p["i"], p["j"]) == (4.9, 12.9): p["j"] = 12.12; print("moved lantern -> 4.9,12.12")
    if p["sprite"] == "bench" and (p["i"], p["j"]) == (16.61, 11.54): p["i"], p["j"] = 18.5, 13.4; print("moved bench -> 18.5,13.4")
    if p["sprite"] == "crates" and (p["i"], p["j"]) == (4.41, 11.53): p["i"], p["j"] = 2.45, 10.45; print("moved crates -> 2.45,10.45")
new = []
for j in (1.5, 2.5, 3.5): new.append({"sprite": "training_post", "i": 16.5, "j": j})
new.append({"sprite": "memorial_stone", "i": 14.5, "j": 1.5})
new.append({"sprite": "bridge", "i": 17.0, "j": 12.5})
new.append({"sprite": "hospital", "i": 4.0, "j": 9.0})
# fenced forest: ring on the lot's boundary lines (lot i 1..6, j 13..14); front line at 14.9 so it sorts behind the row-15 houses
FB, FF = 13.0, 14.9
for i in range(2, 7):
    new.append({"sprite": "fence_i", "i": float(i), "j": FB})
    new.append({"sprite": "fence_i", "i": float(i), "j": FF})
for i in (1.0, 7.0):
    new.append({"sprite": "fence_j", "i": i, "j": round((FB + FF) / 2, 2)})
for i in (1.0, 7.0):
    for j in (FB, FF): new.append({"sprite": "fence_corner", "i": i, "j": j})
trees = [(1.55, 13.42, "tree_small"), (2.5, 13.5, "tree_big"), (3.55, 13.38, "tree_small"), (4.45, 13.48, "tree_big"),
         (5.5, 13.4, "tree_small"), (6.45, 13.52, "tree_big"), (1.95, 14.35, "tree_big"), (3.0, 14.42, "tree_small"),
         (4.0, 14.3, "tree_big"), (5.0, 14.45, "tree_small"), (6.0, 14.38, "tree_big")]
for i, j, s in trees: new.append({"sprite": s, "i": i, "j": j})
new.append({"sprite": "warning_sign", "i": 4.3, "j": 12.6})
P += new
d["placements"] = P

# --- doors ---
d["doors"].append({"i": 3, "j": 8, "door": [4, 10], "kind": "hospital"})

# --- sprites ---
S = d["sprites"]
S["tiles"]["frames"] = 11
man = json.load(open("E:/GodotProject/ninja-city-simulation/tools/art/landmarks_b.json"))
for n in ("training_post", "memorial_stone", "fence_i", "fence_j", "fence_corner", "warning_sign", "bridge", "hospital"):
    m = man[n]; S[n] = {"w": m["w"], "h": m["h"], "frames": m["frames"], "ax": m["ax"], "ay": m["ay"]}
S["bridge"]["sort_y"] = -36

# --- checks ---
legend = d["tile_legend"]
def name(i, j): return legend[d["map"][j][i]]
bad = []
for p in P:
    i, j = math.floor(p["i"]), math.floor(p["j"])
    if not (0 <= i < 20 and 0 <= j < 20): continue
    if name(i, j) in ("water", "riverbank", "bridge") and p["sprite"] != "bridge":
        bad.append(p)
    if name(i, j) in ("dirt", "cobble", "sand") and p["sprite"] not in ("lantern", "warning_sign", "bench", "plant", "barrel", "crates", "training_post", "memorial_stone") and not p["sprite"].startswith("wall"):
        bad.append(("on walk tile", p))
print("placements on water/walk tiles:", bad)
for j, r in enumerate(d["map"]): print("%2d %s" % (j, r))
open(LP, "w", encoding="utf-8", newline="\n").write(dump_layout(d))

# --- tuning (text edits) ---
t = open(TP, encoding="utf-8", newline="").read()
reps = [
 ('"walk_tiles": ["dirt", "cobble", "platform", "sand"],', '"walk_tiles": ["dirt", "cobble", "platform", "sand", "bridge"],'),
 ('"lots_on_street_ok": ["gate", "training"],', '"lots_on_street_ok": ["gate", "training", "river", "hospital"],'),
 ('"ninja": {"train": 0.32, "shop": 0.12, "platform": 0.16, "plaza": 0.12, "wander": 0.28},',
  '"ninja": {"train": 0.32, "shop": 0.12, "platform": 0.16, "plaza": 0.12, "hospital": 0.02, "wander": 0.26},'),
 ('"kunoichi": {"train": 0.18, "shop": 0.32, "platform": 0.18, "plaza": 0.12, "wander": 0.2},',
  '"kunoichi": {"train": 0.18, "shop": 0.3, "platform": 0.18, "plaza": 0.12, "hospital": 0.04, "wander": 0.18},'),
 ('"elder": {"train": 0, "shop": 0.3, "platform": 0.1, "plaza": 0.25, "wander": 0.35}',
  '"elder": {"train": 0, "shop": 0.27, "platform": 0.08, "plaza": 0.22, "hospital": 0.16, "wander": 0.27}'),
 ('"check_walkable_keys": ["kid_home_doors", "tag_centre", "spar_tile_a", "spar_tile_b", "spar_watch_tiles", "hawk_collect_tile", "cat_home"],',
  '"check_walkable_keys": ["kid_home_doors", "tag_centre", "spar_tile_a", "spar_tile_b", "spar_watch_tiles", "hawk_collect_tile", "cat_home", "train_post_spots", "train_free_tiles", "memorial_spot"],'),
 ('"spar_tile_a": [15, 3],', '"spar_tile_a": [17, 3],'),
 ('"spar_spot_a": [15.6, 3.0],', '"spar_spot_a": [17.6, 3.0],'),
 ('"spar_tile_b": [16, 2],', '"spar_tile_b": [18, 2],'),
 ('"spar_spot_b": [16.5, 2.1],', '"spar_spot_b": [18.5, 2.1],'),
 ('"spar_watch_tiles": [[14, 4], [15, 4], [17, 4], [18, 4], [13, 4]],', '"spar_watch_tiles": [[17, 4], [18, 4], [16, 4], [15, 4], [14, 4]],'),
 ('\t"train_pose_seconds": 0.45,\n', '\t"train_pose_seconds": 0.45,\n'
  '\t"train_post_spots": [[15.85, 1.5, 16.5, 1.5], [15.85, 2.5, 16.5, 2.5], [15.85, 3.5, 16.5, 3.5]],\n'
  '\t"train_free_tiles": [[17, 1], [18, 1], [18, 4]],\n'
  '\t"memorial_spot": [14.5, 2.25, 14.5, 1.5],\n'
  '\t"memorial_chance": 0.35,\n\t"memorial_min": 3,\n\t"memorial_max": 6,\n'
  '\t"hospital_min": 8,\n\t"hospital_max": 16,\n'),
]
for a, b in reps:
    c = t.count(a)
    if c != 1:
        print("TUNING MISS", c, a[:60]); continue
    t = t.replace(a, b)
json.loads(t)
assert "\r" not in t
open(TP, "w", encoding="utf-8", newline="\n").write(t)
for ty, w in json.loads(t)["activity_weights"].items(): print(ty, round(sum(w.values()), 4))
print("ok")
