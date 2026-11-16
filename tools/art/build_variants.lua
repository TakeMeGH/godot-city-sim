local ROOT = "E:/GodotProject/ninja-city-simulation/assets/art/"
local SRC = ROOT.."src/"
local DRY = DRY_RUN or false
local pc = app.pixelColor
local CLEAR = pc.rgba(0,0,0,0)
local function hx(c) return string.format("%02X%02X%02X", pc.rgbaR(c), pc.rgbaG(c), pc.rgbaB(c)) end
local function col(h, a) return pc.rgba(tonumber(h:sub(1,2),16), tonumber(h:sub(3,4),16), tonumber(h:sub(5,6),16), a or 255) end
local function set(list) local t={} for _,v in ipairs(list) do t[v]=true end return t end
local function op(c) return pc.rgbaA(c) > 0 end
local function rgb2hsl(r,g,b) r,g,b=r/255,g/255,b/255 local mx=math.max(r,g,b) local mn=math.min(r,g,b) local l=(mx+mn)/2 local h,s=0,0
  if mx~=mn then local d=mx-mn s = (l>0.5) and d/(2-mx-mn) or d/(mx+mn)
    if mx==r then h=(g-b)/d+((g<b) and 6 or 0) elseif mx==g then h=(b-r)/d+2 else h=(r-g)/d+4 end h=h*60 end
  return h,s,l end
local function hue2rgb(p,q,t) if t<0 then t=t+1 end if t>1 then t=t-1 end if t<1/6 then return p+(q-p)*6*t end if t<1/2 then return q end if t<2/3 then return p+(q-p)*(2/3-t)*6 end return p end
local function hsl2hex(h,s,l) h=(h%360)/360 s=math.max(0,math.min(1,s)) l=math.max(0,math.min(1,l)) local r,g,b
  if s==0 then r,g,b=l,l,l else local q=(l<0.5) and l*(1+s) or l+s-l*s local p=2*l-q r=hue2rgb(p,q,h+1/3) g=hue2rgb(p,q,h) b=hue2rgb(p,q,h-1/3) end
  return string.format("%02X%02X%02X", math.floor(r*255+0.5), math.floor(g*255+0.5), math.floor(b*255+0.5)) end
local function hexhsl(h) return rgb2hsl(tonumber(h:sub(1,2),16), tonumber(h:sub(3,4),16), tonumber(h:sub(5,6),16)) end

local ROOFSET = set{"F6B080","FFC080","F09058","E07A48","D8683E","C85A36","B04A32","A04230","9E4129","A83E2A","D8563A","7A2E2E","5A2420"}
local TRIM = set{"D8563A","B04A32","A83E2A","7A2E2E"}
local WALLSET = set{"FBF0D8","EFDCB8","DCC69E","D8C2A0","C8AE8C","B49878","A88E7A"}
local OCHRE = {FBF0D8="F8DCA4",EFDCB8="ECC68A",DCC69E="D8B070",D8C2A0="D8B47A",C8AE8C="C79F5F",B49878="AE8A4E"}
do local h1,s1,l1=hexhsl("B49878") local h2,s2,l2=hexhsl("AE8A4E") local h,s,l=hexhsl("A88E7A") OCHRE["A88E7A"]=hsl2hex(h+(h2-h1), s+(s2-s1), l+(l2-l1)) end
local CANON = {} for k,v in pairs(OCHRE) do CANON[v]=k end
local ROOFS = {"terra","red","slate"}
local WALLS = {"cream","ochre","white"}
local function roofMap(h6, v)
  if v=="terra" then return h6 end
  local h,s,l = hexhsl(h6)
  if v=="red" then return hsl2hex(h-20, s*0.95, l-0.04) end
  return hsl2hex(222-(h-15)*1.5, 0.10+s*0.14, l)
end
local function wallMap(h6, v)
  if v=="cream" then return h6 end
  if v=="ochre" then return OCHRE[h6] end
  local h,s,l = hexhsl(h6)
  if l >= 0.70 then return hsl2hex(48, 0.30, l) end
  return hsl2hex(218, 0.14, l)
end
if PRINT_RAMPS then
  for _,v in ipairs({"red","slate"}) do local s=v..":" for k,_ in pairs(ROOFSET) do s=s.." "..k.."->"..roofMap(k,v) end print(s) end
  for _,v in ipairs({"ochre","white"}) do local s=v..":" for k,_ in pairs(WALLSET) do s=s.." "..k.."->"..wallMap(k,v) end print(s) end
end

local function newImg(w,h) return Image(w,h,ColorMode.RGB) end
local function layerImgs(spr, name)
  for _,L in ipairs(spr.layers) do if L.name==name then
    local out={} for f=1,#spr.frames do local im=newImg(spr.width,spr.height) local c=L:cel(f)
      if c then for it in c.image:pixels() do local v=it() if op(v) then im:drawPixel(it.x+c.position.x, it.y+c.position.y, v) end end end
      out[f]=im end
    return out, L.opacity end end
  return nil, 255
end

local TANKCOL = set{"F0EEF4","E8E6EE","C5C4CF","9B9AA6","5A5866","A83E2A","D8563A"}
local function xl(y) return 76-2*y end
local function xr(y) return 2*y-11 end
local function extractTank(R)
  local im = newImg(24,26)
  for y=18,37 do for x=31,45 do local c=R:getPixel(x,y)
    if op(c) and TANKCOL[hx(c)] and not (hx(c)=="5A5866" and x<=31 and y>=24) then im:drawPixel(x-26,y-15,c) end end end
  local add = {}
  for y=0,25 do for x=0,23 do if not op(im:getPixel(x,y)) then
    for _,d in ipairs({{1,0},{-1,0},{0,1},{0,-1}}) do local nx,ny=x+d[1],y+d[2]
      if nx>=0 and nx<24 and ny>=0 and ny<26 then local n=im:getPixel(nx,ny) if op(n) and hx(n)~="5A5866" then add[#add+1]={x,y} break end end end end end end
  for _,p in ipairs(add) do im:drawPixel(p[1],p[2],col("5A5866")) end
  local x0,y0,x1,y1=99,99,-1,-1
  for y=0,25 do for x=0,23 do if op(im:getPixel(x,y)) then x0=math.min(x0,x) y0=math.min(y0,y) x1=math.max(x1,x) y1=math.max(y1,y) end end end
  local out = newImg(x1-x0+1, y1-y0+1)
  for y=y0,y1 do for x=x0,x1 do out:drawPixel(x-x0,y-y0,im:getPixel(x,y)) end end
  return out, x0+26, y0+15
end
local function removeTank(R, D)
  for y=17,39 do for x=29,47 do local c=R:getPixel(x,y)
    if op(c) and TANKCOL[hx(c)] then
      local a,b = xl(y), xr(y)
      if x<a or x>b then R:drawPixel(x,y,CLEAR)
      elseif x<=a+1 or x>=b-1 then R:drawPixel(x,y,CLEAR) D:drawPixel(x,y,col("C8C0B2"))
      elseif x<=a+3 or x>=b-3 then R:drawPixel(x,y,col("5A5866"))
      else R:drawPixel(x,y,col("8A8278")) end
    end end end
end

local function computeB(cfg, L, W, H0)
  local b = {}
  if cfg.bmode=="trim" then
    local im=L.walls[1]
    for x=0,W-1 do for y=0,H0-1 do local c=im:getPixel(x,y) if op(c) and TRIM[hx(c)] then b[x]=y+cfg.trimOff break end end end
    local fill={} for x=0,W-1 do if b[x]==nil then for d=1,2 do if b[x-d] then fill[x]=b[x-d] break elseif b[x+d] then fill[x]=b[x+d] break end end end end
    for x,v in pairs(fill) do b[x]=v end
  elseif cfg.bmode=="roof" then
    local R,Wl=L.roof[1],L.walls[1]
    for x=0,W-1 do local m=nil for y=0,H0-1 do if op(R:getPixel(x,y)) then m=y end end
      if m then for y=m+1,H0-1 do if op(Wl:getPixel(x,y)) then b[x]=m+1 break end end end end
  else for x=cfg.bx0,cfg.bx1 do b[x]=cfg.bconst end end
  return b
end

local function extrude(im, W, H0, k, Hb, B, kind, cfg)
  local Hn = H0 + k*Hb
  local out = newImg(W, Hn)
  for x=0,W-1 do
    local b = B[x]
    if kind=="shadow" then b = 0 end
    if k==0 or kind=="details" then b = nil end
    for r=0,Hn-1 do
      local px = CLEAR
      if b==nil or r < b then if r < H0 then px = im:getPixel(x,r) end
      elseif r >= b + k*Hb then px = im:getPixel(x, r-k*Hb)
      elseif kind~="shadow" then
        local off=(r-b)%Hb
        local sy=b+off
        if sy < H0 then px = im:getPixel(x,sy) end
        if kind=="walls" then
          for _,s in ipairs(cfg.subs or {}) do
            if x>=s.x0 and x<=s.x1 and off>=s.minOff then
              if s.mode=="col" then local sx=x+s.dx local sb=B[sx] if sb then px=im:getPixel(sx, sb+off) end
              elseif s.all or (op(px) and ((not s.only) or s.only[hx(px)])) then px=im:getPixel(x, s.ref) end
            end
          end
          if cfg.peak and off==Hb-1 and x>=cfg.peak.x0 and x<=cfg.peak.x1 then local pp=im:getPixel(x,b-1) if op(pp) and cfg.peak.cols[hx(pp)] then px=pp end end
        end
      end
      if op(px) then out:drawPixel(x,r,px) end
    end
  end
  return out
end
local function split(im, pred)
  local a,r = newImg(im.width,im.height), newImg(im.width,im.height)
  for it in im:pixels() do local c=it() if op(c) then if pred[hx(c)] then a:drawPixel(it.x,it.y,c) else r:drawPixel(it.x,it.y,c) end end end
  return a,r
end
local function recolor(im, fn, v)
  local o=newImg(im.width,im.height) local cache={}
  for it in im:pixels() do local c=it() if op(c) then local h=hx(c) if not cache[h] then cache[h]=fn(h,v) end o:drawPixel(it.x,it.y,col(cache[h],pc.rgbaA(c))) end end
  return o
end
local function mapImg(im, map)
  for it in im:pixels() do local c=it() if op(c) then local m=map[hx(c)] if m then im:drawPixel(it.x,it.y,col(m,pc.rgbaA(c))) end end end
end
local function build(W, Hn, layers, nframes)
  local spr = Sprite(W, Hn, ColorMode.RGB)
  for f=2,nframes do spr:newEmptyFrame() end
  local first = spr.layers[1]
  for i,ly in ipairs(layers) do
    local L = (i==1) and first or spr:newLayer()
    L.name = ly.name
    if ly.opacity then L.opacity = ly.opacity end
    for f=1,nframes do if L:cel(f) then spr:deleteCel(L,f) end spr:newCel(L, f, ly.imgs[f], Point(0,0)) end
    L.isVisible = (ly.visible ~= false)
  end
  return spr
end
local function showVariant(spr, rv, wv)
  for _,L in ipairs(spr.layers) do local kind,v = L.name:match("^(%a+)_(%a+)$")
    if kind=="wall" then L.isVisible=(v==wv) elseif kind=="trim" or kind=="roof" then L.isVisible=(v==rv) end end
end
local function sheetOf(spr, W, Hn)
  local s = newImg(W*2, Hn)
  for f=1,2 do s:drawSprite(spr, f, Point((f-1)*W, 0)) end
  return s
end

local TYPES = {
  {name="house_block", ax=32, ay=64, Hb=14, storeys={1,2,3}, bmode="trim", trimOff=-2, tank=true,
    subs={{x0=14,x1=23,mode="col",dx=-10,minOff=0}}},
  {name="house_hip", ax=34, ay=66, Hb=14, storeys={1,2,3}, bmode="roof",
    subs={{x0=12,x1=22,mode="col",dx=10,minOff=7}}},
  {name="tower", ax=32, ay=66, Hb=14, storeys={1,2}, bmode="const", bconst=55, bx0=16, bx1=48,
    subs={{x0=23,x1=29,mode="row",ref=56,minOff=0,only=set{"3A2626","4A5F91","6E4232","5A3A2A","2D3662"}},
          {x0=16,x1=20,mode="row",ref=57,minOff=8,all=true},
          {x0=44,x1=48,mode="row",ref=57,minOff=6,all=true}},
    peak={x0=33,x1=47,cols=set{"4A5F91","3A4A6E","FFC860"}}},
  {name="shop", ax=32, ay=64, Hb=14, storeys={1}, bmode="trim", trimOff=-2, tank=true, canon=true, subs={}},
}
if ONLY then local t={} for _,c in ipairs(TYPES) do if c.name==ONLY then t[#t+1]=c end end TYPES=t end
if ONLY_STOREY then for _,c in ipairs(TYPES) do c.storeys={ONLY_STOREY} end end

local manifest = {}
local tankImg, tankPt = nil, nil
for _,cfg in ipairs(TYPES) do
  local orig = app.open(SRC..cfg.name..".aseprite")
  local W,H0 = orig.width, orig.height
  local L, OP = {}, {}
  for _,n in ipairs({"shadow","walls","details","roof"}) do L[n],OP[n] = layerImgs(orig, n) end
  orig:close()
  if not L.details then L.details={newImg(W,H0),newImg(W,H0)} OP.details=255 end
  if cfg.tank then
    if not tankImg then local tim,tx,ty = extractTank(L.roof[1]) tankImg=tim
      local tax=math.floor(tim.width/2) local tay=tim.height-1 tankPt={tx+tax-cfg.ax, ty+tay-cfg.ay}
      print("tank "..tim.width.."x"..tim.height.." at "..tx..","..ty.." point "..tankPt[1]..","..tankPt[2]) end
    for f=1,2 do removeTank(L.roof[f], L.details[f]) end
  end
  if cfg.canon then for f=1,2 do mapImg(L.walls[f], CANON) end end
  local B = computeB(cfg, L, W, H0)
  if PRINT_B then local bs="" for x=0,W-1 do bs=bs..(B[x] and tostring(B[x]) or "-").."," end print(cfg.name.." b: "..bs) end
  for _,s in ipairs(cfg.storeys) do
    local k = s-1
    local Hn = H0 + k*cfg.Hb
    local E = {}
    for _,n in ipairs({"shadow","walls","details","roof"}) do E[n]={} for f=1,2 do E[n][f]=extrude(L[n][f], W, H0, k, cfg.Hb, B, n, cfg) end end
    local wallI, trimI, baseI, roofI, roofB = {},{},{},{},{}
    for f=1,2 do
      local w, rest = split(E.walls[f], WALLSET)
      local t, base = split(rest, ROOFSET)
      wallI[f],trimI[f],baseI[f] = w,t,base
      roofI[f], roofB[f] = split(E.roof[f], ROOFSET)
    end
    local layers = {{name="shadow", imgs=E.shadow, opacity=OP.shadow}, {name="base", imgs=baseI, opacity=OP.walls}}
    for _,wv in ipairs(WALLS) do layers[#layers+1]={name="wall_"..wv, imgs={recolor(wallI[1],wallMap,wv),recolor(wallI[2],wallMap,wv)}, visible=(wv=="cream"), opacity=OP.walls} end
    for _,rv in ipairs(ROOFS) do layers[#layers+1]={name="trim_"..rv, imgs={recolor(trimI[1],roofMap,rv),recolor(trimI[2],roofMap,rv)}, visible=(rv=="terra"), opacity=OP.walls} end
    layers[#layers+1]={name="details", imgs=E.details, opacity=OP.details}
    layers[#layers+1]={name="roofbase", imgs=roofB, opacity=OP.roof}
    for _,rv in ipairs(ROOFS) do layers[#layers+1]={name="roof_"..rv, imgs={recolor(roofI[1],roofMap,rv),recolor(roofI[2],roofMap,rv)}, visible=(rv=="terra"), opacity=OP.roof} end
    local spr = build(W, Hn, layers, 2)
    local ay = cfg.ay + k*cfg.Hb
    local R1 = E.roof[1]
    local rh, pts
    if cfg.tank then
      local mn,mx=nil,nil for y=0,Hn-1 do local c=R1:getPixel(32,y) if op(c) and hx(c)=="8A8278" then mn=mn or y mx=y end end
      rh = ay - math.floor((mn+mx)/2)
      pts = {{tankPt[1], tankPt[2]-k*cfg.Hb}, {-10, -24-k*cfg.Hb}}
    elseif cfg.name=="house_hip" then
      local top=nil for y=0,Hn-1 do if op(R1:getPixel(cfg.ax,y)) then top=y break end end
      rh = ay-top pts={{0,-rh}}
    else
      local top=nil for y=0,Hn-1 do local n=0 for x=0,W-1 do if op(R1:getPixel(x,y)) then n=n+1 end end if n>=8 then top=y break end end
      rh = ay-top
      local t2=nil for y=0,Hn-1 do if op(R1:getPixel(cfg.ax-7,y)) then t2=y break end end
      pts={{-7, t2-ay}}
    end
    local ptxt={} for _,p in ipairs(pts) do ptxt[#ptxt+1]="["..p[1]..", "..p[2].."]" end
    for _,rv in ipairs(ROOFS) do for _,wv in ipairs(WALLS) do
      showVariant(spr, rv, wv)
      local nm = cfg.name.."_s"..s.."_"..rv.."_"..wv
      local sh = sheetOf(spr, W, Hn)
      if not DRY then sh:saveAs(ROOT..nm..".png") end
      if PREVIEW_DIR and (rv=="terra" or wv=="cream") then sh:saveAs(PREVIEW_DIR..nm..".png") end
      manifest[#manifest+1] = {nm, string.format('{"w": %d, "h": %d, "frames": 2, "ax": %d, "ay": %d, "type": "%s", "storeys": %d, "roof": "%s", "wall": "%s", "roof_height": %d, "detail_points": [%s]}',
        W, Hn, cfg.ax, ay, cfg.name, s, rv, wv, rh, table.concat(ptxt,", "))}
      if s==1 and rv=="terra" and ((wv=="cream" and not cfg.canon) or (wv=="ochre" and cfg.canon)) then
        local o = Image{fromFile=ROOT..cfg.name..".png"} local d=0
        for y=0,math.min(o.height,sh.height)-1 do for x=0,math.min(o.width,sh.width)-1 do if o:getPixel(x,y)~=sh:getPixel(x,y) then d=d+1 end end end
        print(nm.." vs original "..cfg.name..".png ("..o.width.."x"..o.height.."): "..d.." px differ")
      end
    end end
    showVariant(spr, "terra", cfg.canon and "ochre" or "cream")
    if not DRY then spr:saveAs(SRC..cfg.name.."_s"..s..".aseprite") end
    print(cfg.name.."_s"..s..": "..W.."x"..Hn.." anchor "..cfg.ax..","..ay.." roof_height "..rh.." pts "..table.concat(ptxt,", "))
    spr:close()
  end
end
if MANIFEST_OUT then
  local f = io.open(MANIFEST_OUT, "w") f:write("{\n") for i,m in ipairs(manifest) do f:write('  "'..m[1]..'": '..m[2]..(i<#manifest and ",\n" or "\n")) end f:write("}\n") f:close()
end
if tankImg and TANK_OUT then tankImg:saveAs(TANK_OUT) end
print("done "..#manifest)
