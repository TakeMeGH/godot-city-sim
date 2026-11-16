local ROOT = "E:/GodotProject/ninja-city-simulation/assets/art/"
local SRC = ROOT.."src/"
local S = "C:/Users/abdul/AppData/Local/Temp/claude/85495e6675f63099/e41ff82d-1617-46c5-a737-0b013a0c8e1f/scratchpad/"
local pc = app.pixelColor
local function col(h) return pc.rgba(tonumber(h:sub(1,2),16), tonumber(h:sub(3,4),16), tonumber(h:sub(5,6),16), 255) end
local function rowsImage(rows, legend)
  local h=#rows local w=#rows[1]
  local im=Image(w,h,ColorMode.RGB)
  for y=1,h do assert(#rows[y]==w, "row width "..y) for x=1,w do local c=legend[rows[y]:sub(x,x)] if c then im:drawPixel(x-1,y-1,col(c)) end end end
  return im
end
local K="4A3434"
local D = {}
D.tank_square = rowsImage({
  "......KK......",
  "....KKHHKK....",
  "..KKHHTTTTKK..",
  "KHHTTTTTTTTttK",
  "KLTTTTTTTtttRK",
  "KLLLTTTtttRRRK",
  "KLLLLLTtRRRRRK",
  "KLLLLLLRRRRRRK",
  "KLLLLLLRRRRRRK",
  "KMLLLLLRRRRRSK",
  "KLMMLLLRRRSSRK",
  "KLLLMMLRSSRRRK",
  "KLLLLLMSRRRRRK",
  ".KLLLLLRRRRRK.",
  ".KKKLLLRRRKKK.",
  ".K..KKLRKK..K.",
  ".K....KK....K.",
  ".K....KK....K.",
  ".K....KK....K.",
  "......KK......",
  "......KK......",
}, {K=K, H="E6EBF0", T="C4CCD6", t="A8B2C0", L="9CA6B6", M="7E889C", R="6E768A", S="565E72"})
D.tank_barrel = rowsImage({
  "...KKKKKKKK...",
  ".KKTTTTTTTtKK.",
  "KTTTTTTTTTtttK",
  "KTTTTTTTTttttK",
  "KLKKttttddKKDK",
  "KLLLKKKKKKDDDK",
  "KHHHHHHGGGGGGK",
  "KLLLLMMMMMMDDK",
  "KLLLLMMMMMMDDK",
  "KHHHHHHGGGGGGK",
  "KLLLLMMMMMMDDK",
  ".KKLLMMMMMDKK.",
  "...KKKKKKKK...",
}, {K=K, T="D8A468", t="B8834E", d="8E5A36", L="B07444", M="8E5634", D="6A3C26", H="A6A2A4", G="6E6A78"})
D.laundry = rowsImage({
  "KK....................KK",
  "PK....................PK",
  "PKKK................KKPK",
  "PK..KKKK........KKKK..PK",
  "PK.KRRRrKKKKKKKKBBbK..PK",
  "PK.KRRRrKKWWWwKKBBbK..PK",
  "PK..KRrK.KWWWwKKBBbK..PK",
  "PK..KRrK.KWWWwKKBbbK..PK",
  "PK..KKKK.KWWWwKKKKKK..PK",
  "PK.......KWWWwK.......PK",
  "PK.......KwwwwK.......PK",
  "PK.......KKKKKK.......PK",
  "PK....................PK",
  "PK....................PK",
  "PK....................PK",
  "KK....................KK",
}, {K=K, P="8A5A3E", R="E0624A", r="B23C3A", W="F6EAD0", w="D8CCB4", B="5A7AB8", b="3E5A94"})
D.sign = rowsImage({
  "KK.........",
  "PKKKKKKKKKK",
  "PK.KCCCCcK.",
  "PK.KCCCCcK.",
  "PK.KCCMCcK.",
  "PK.KCMCMcK.",
  "PK.KMCCCMK.",
  "PK.KCMCMcK.",
  "PK.KCCMCcK.",
  "PK.KCCCCcK.",
  "PK.KCCCCcK.",
  "PK.KCCCCcK.",
  "PK.KCCKCcK.",
  "PK.KCK.KcK.",
  "PK.KK...KK.",
  "PK.........",
  "PK.........",
  "PK.........",
  "KK.........",
}, {K=K, P="8A5A3E", C="C8402E", c="9A2E26", M="F6EAD0"})
D.tank_round = Image{fromFile=S.."tank_round_extracted.png"}
local order = {"tank_round","tank_square","tank_barrel","laundry","sign"}
local man = {}
local pw, ph = 0, 0
for _,n in ipairs(order) do pw = pw + D[n].width + 2 ph = math.max(ph, D[n].height) end
local prev = Image(pw, ph, ColorMode.RGB) local px = 0
for _,n in ipairs(order) do
  local im = D[n]
  local spr = Sprite(im.width, im.height, ColorMode.RGB)
  local L = spr.layers[1] L.name = "detail"
  if L:cel(1) then spr:deleteCel(L,1) end
  spr:newCel(L, 1, im, Point(0,0))
  spr:saveAs(SRC.."roof_"..n..".aseprite")
  spr:close()
  im:saveAs(ROOT.."roof_"..n..".png")
  local ax, ay = math.floor(im.width/2), im.height-1
  man[#man+1] = string.format('  "roof_%s": {"w": %d, "h": %d, "frames": 1, "ax": %d, "ay": %d}', n, im.width, im.height, ax, ay)
  prev:drawImage(im, Point(px, ph-im.height)) px = px + im.width + 2
  print(n.." "..im.width.."x"..im.height.." anchor "..ax..","..ay)
end
prev:saveAs(S.."prev/details_preview.png")
-- merge manifest
local f = io.open(S.."building_variants_buildings.json","r") local txt = f:read("a") f:close()
txt = txt:gsub("\n}%s*$", ",\n"..table.concat(man, ",\n").."\n}\n")
local o = io.open(S.."building_variants.json","w") o:write(txt) o:close()
print("manifest written")
