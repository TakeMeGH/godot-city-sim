"""Story 009 throwaway: re-skins building placements with seeded variants, adds the sprite table entries."""
import json, math, random, re, sys
from collections import Counter

ROOT = "E:/GodotProject/ninja-city-simulation/assets/data/"
MAN = sys.argv[1]
man = json.load(open(MAN))
rng = random.Random(9)

path = ROOT + "village_layout.json"
text = open(path, newline="").read()
assert "\r" not in text
lay = json.loads(text)
TYPES = ["house_block", "house_hip", "tower", "shop"]
bld = [(n, p) for n, p in enumerate(lay["placements"]) if p["sprite"] in TYPES]
print("buildings", Counter(p["sprite"] for _, p in bld))

def tile(p):
    return (math.floor(p["i"]), math.floor(p["j"]))

# storey quotas (exact counts, shuffled with the seed)
hb = [k for k, (_, p) in enumerate(bld) if p["sprite"] in ("house_block", "house_hip")]
tw = [k for k, (_, p) in enumerate(bld) if p["sprite"] == "tower"]
sh = [k for k, (_, p) in enumerate(bld) if p["sprite"] == "shop"]
storeys = {}
total = len(bld)
n_hb = len(hb)
s3 = round(total * 0.15)
s1_hb = round(total * 0.50) - len(sh) - len(tw) // 2
q = [1] * s1_hb + [3] * s3
q += [2] * (n_hb - len(q))
rng.shuffle(q)
for k, s in zip(hb, q):
    storeys[k] = s
tq = [1] * (len(tw) // 2) + [2] * (len(tw) - len(tw) // 2)
rng.shuffle(tq)
for k, s in zip(tw, tq):
    storeys[k] = s
for k in sh:
    storeys[k] = 1

n_slate = round(total * 0.15)
n_red = (total - n_slate) * 45 // 100
roofs = ["slate"] * n_slate + ["red"] * n_red
roofs += ["terra"] * (total - len(roofs))
rng.shuffle(roofs)
walls = (["cream", "ochre", "white"] * total)[:total]
rng.shuffle(walls)

combo = {}
tiles = {k: tile(p) for k, (_, p) in enumerate(bld)}
def neighbours(k):
    ti, tj = tiles[k]
    return [m for m in combo if m != k and abs(tiles[m][0] - ti) <= 1 and abs(tiles[m][1] - tj) <= 1]
for k, (_, p) in enumerate(bld):
    want = (p["sprite"], storeys[k], roofs[k], walls[k])
    taken = {combo[m] for m in neighbours(k)}
    if want in taken:
        alts = [(p["sprite"], storeys[k], roofs[k], w) for w in ("cream", "ochre", "white")]
        alts += [(p["sprite"], storeys[k], r, w) for r in ("terra", "red") for w in ("cream", "ochre", "white")]
        want = next(a for a in alts if a not in taken)
    combo[k] = want
# verify neighbours over all pairs
for k in combo:
    for m in neighbours(k):
        assert combo[k] != combo[m], (k, m)

def detail_list(t):
    r = rng.random()
    out = []
    if t in ("house_block", "shop"):
        if r < 0.85:
            r2 = rng.random()
            tank = "roof_tank_round" if r2 < 0.65 else ("roof_tank_square" if r2 < 0.85 else "roof_tank_barrel")
            out.append({"sprite": tank, "point": 0})
        r3 = rng.random()
        sign_p = 0.4 if t == "shop" else 0.12
        if r3 < sign_p:
            out.append({"sprite": "roof_sign", "point": 1})
        elif r3 < sign_p + 0.35:
            out.append({"sprite": "roof_laundry", "point": 1})
    else:
        if r < 0.25:
            out.append({"sprite": "roof_sign", "point": 0})
        elif r < 0.45:
            out.append({"sprite": "roof_tank_barrel", "point": 0})
    return out

def js(v):
    return json.dumps(v, separators=(", ", ": "))

lines = text.split("\n")
new_by_index = {}
for k, (n, p) in enumerate(bld):
    t, s, r, w = combo[k]
    name = "%s_s%d_%s_%s" % (t, s, r, w)
    if t == "shop" and k == sh[0]:
        pass
    assert name in man, name
    new_by_index[n] = (name, detail_list(t))

# patch placement lines in order
start = lines.index('\t"placements": [')
n = 0
for li in range(start + 1, len(lines)):
    if lines[li] == "\t],":
        break
    if n in new_by_index:
        name, det = new_by_index[n]
        old = lay["placements"][n]["sprite"]
        line = lines[li].replace('"sprite": "%s"' % old, '"sprite": "%s"' % name, 1)
        if det:
            line = re.sub(r'\}(,?)$', lambda m: ', "details": %s}%s' % (js(det), m.group(1)), line, count=1)
        lines[li] = line
    n += 1
assert n == len(lay["placements"]), n

# sprite table: append manifest entries (sheets: w,h,frames,ax,ay,storeys,roof_height,detail_points)
end = len(lines) - 1
while lines[end] != "\t}":
    end -= 1
add = []
for name, m in man.items():
    if name in lay["sprites"]:
        continue
    e = {k: m[k] for k in ("w", "h", "frames", "ax", "ay")}
    if "type" in m:
        e.update({"type": m["type"], "storeys": m["storeys"], "roof_height": m["roof_height"], "detail_points": m["detail_points"]})
    add.append('\t\t"%s": %s' % (name, js(e)))
lines[end - 1] += ","
lines[end:end] = [",\n".join(add)]
out = "\n".join(lines)
lay2 = json.loads(out)
open(path, "w", newline="\n").write(out)

# report
placed = [p for p in lay2["placements"] if p["sprite"] in man and "type" in man[p["sprite"]]]
print("variants placed", len(placed), "distinct", len({p["sprite"] for p in placed}))
for key in ("type", "storeys", "roof", "wall"):
    print(key, Counter((man[p["sprite"]]["type"], man[p["sprite"]][key]) if key == "storeys" else man[p["sprite"]][key] for p in placed))
print("storeys all", Counter(man[p["sprite"]]["storeys"] for p in placed))
print("details", Counter(d["sprite"] for p in placed for d in p.get("details", [])))
print("blocks/shops with tank", sum(1 for p in placed if man[p["sprite"]]["type"] in ("house_block", "shop") and any(d["sprite"].startswith("roof_tank") for d in p.get("details", []))))
print("sprites", len(lay2["sprites"]))

# tuning: storey_px after window_glows
tp = ROOT + "village_tuning.json"
tt = open(tp, newline="").read()
assert "\r" not in tt
if '"storey_px"' not in tt:
    tt = re.sub(r'^(\t"window_glows": .*,)$', lambda m: m.group(1) + '\n\t"storey_px": 14,', tt, count=1, flags=re.M)
json.loads(tt)
open(tp, "w", newline="\n").write(tt)
print("storey_px", json.loads(tt)["storey_px"])
