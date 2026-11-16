-- Villager looks + roles generator (story 010). Reads base bodies from assets/art/src,
-- writes <body>_looks.aseprite / role_<name>.aseprite and PNG strips. Never touches base files.
local ROOT="E:/GodotProject/ninja-city-simulation/assets/art/"
local PREV=VILLAGER_PREVIEW_DIR or nil
local PC=app.pixelColor
local LOG={}
local function log(s) LOG[#LOG+1]=s end

local function hx(s) s=s:gsub("#","")
  local a=255 if #s==8 then a=tonumber(s:sub(7,8),16) end
  return PC.rgba(tonumber(s:sub(1,2),16),tonumber(s:sub(3,4),16),tonumber(s:sub(5,6),16),a) end
local function key(v) return string.format("%02X%02X%02X",PC.rgbaR(v),PC.rgbaG(v),PC.rgbaB(v)) end
local function withA(c,v) return PC.rgba(PC.rgbaR(c),PC.rgbaG(c),PC.rgbaB(c),PC.rgbaA(v)) end

-- visit opaque pixels: fn(xs,ys,v,xl,yl) -> new value or nil   (xs/ys sprite coords, xl/yl cel-local)
local function px(c,fn)
  local img,pos=c.img,c.pos
  for y=0,img.height-1 do for x=0,img.width-1 do
    local v=img:getPixel(x,y)
    if PC.rgbaA(v)>0 then local nv=fn(x+pos.x,y+pos.y,v,x,y) if nv then img:drawPixel(x,y,nv) end end
  end end
end
local function mapfn(map) local m={} for k,t in pairs(map) do m[k]=hx(t) end
  return function(v) local c=m[key(v)] if c then return withA(c,v) end end end
local function rows(img,ox,oy,rws,leg)
  for j,r in ipairs(rws) do for i=1,#r do local ch=r:sub(i,i) local x,y=ox+i-1,oy+j-1
    if x>=0 and y>=0 and x<img.width and y<img.height then
      if ch=="_" then img:drawPixel(x,y,0) elseif leg[ch] then img:drawPixel(x,y,hx(leg[ch])) end end end end
end
local function eraseRows(img,y0,y1) for y=y0,y1 do for x=0,img.width-1 do img:drawPixel(x,y,0) end end end

local function load(name)
  local s=app.open(ROOT.."src/"..name..".aseprite")
  local d={w=s.width,h=s.height,n=#s.frames,dur={},layers={}}
  for fi=1,#s.frames do d.dur[fi]=s.frames[fi].duration end
  for _,l in ipairs(s.layers) do
    local L={name=l.name,opacity=l.opacity,cels={}}
    for fi=1,#s.frames do local c=l:cel(fi)
      if c then local full=Image(s.width,s.height,ColorMode.RGB)
        full:drawImage(c.image,Point(0,0))  -- keep cel-local coords, full canvas size
        L.cels[fi]={img=full,pos=Point(c.position.x,c.position.y),op=c.opacity} end end
    d.layers[#d.layers+1]=L
  end
  s:close()
  return d
end
local function clone(d)
  local o={w=d.w,h=d.h,n=d.n,dur=d.dur,layers={}}
  for _,L in ipairs(d.layers) do local N={name=L.name,opacity=L.opacity,cels={}}
    for fi,c in pairs(L.cels) do N.cels[fi]={img=c.img:clone(),pos=Point(c.pos.x,c.pos.y),op=c.op} end
    o.layers[#o.layers+1]=N end
  return o
end
local function layer(d,name) for _,L in ipairs(d.layers) do if L.name==name then return L end end end
local function upperDy(d,fi) return layer(d,"upper").cels[fi].pos.y end
-- new empty layer whose cels follow the upper cel (bob) ; inserted below `before` or on top
local function addLayer(d,name,before)
  local L={name=name,opacity=255,cels={}}
  for fi=1,d.n do L.cels[fi]={img=Image(d.w,d.h,ColorMode.RGB),pos=Point(0,upperDy(d,fi)),op=255} end
  if before then for i,M in ipairs(d.layers) do if M.name==before then table.insert(d.layers,i,L) return L end end end
  d.layers[#d.layers+1]=L return L
end
local function remapAll(d,map,excl)
  local f=mapfn(map)
  for _,L in ipairs(d.layers) do for fi,c in pairs(L.cels) do
    px(c,function(xs,ys,v,xl,yl) if excl and excl(L.name,fi,xl,yl) then return nil end return f(v) end) end end
end

-- sprite output -----------------------------------------------------------
local function newSprite(d)
  local s=Sprite(d.w,d.h,ColorMode.RGB)
  local first=s.layers[1]
  for fi=2,d.n do s:newEmptyFrame() end
  for fi=1,d.n do s.frames[fi].duration=d.dur[fi] end
  return s,first
end
local function addTo(s,d,group)
  for _,L in ipairs(d.layers) do
    local l=s:newLayer() l.name=L.name l.opacity=L.opacity
    if group then l.parent=group end
    for fi,c in pairs(L.cels) do local cel=s:newCel(l,s.frames[fi],c.img,c.pos) cel.opacity=c.op or 255 end
  end
end
local function strip(s)
  local im=Image(s.width*#s.frames,s.height,ColorMode.RGB)
  for fi=1,#s.frames do im:drawSprite(s,fi,Point((fi-1)*s.width,0)) end
  return im
end
local function savePng(im,path)
  local o=Sprite(im.width,im.height,ColorMode.RGB)
  o.cels[1].image=im o:saveCopyAs(path) o:close()
end

-- palettes ----------------------------------------------------------------
local HAIR={
  black={"5D566F","3A3048","2A2238","16101C"}, blond={"F4DC7A","D9A93E","B8862E","8A5A22"},
  brown={"B07A4A","7A4A2C","63391F","4A2A1E"}, pink={"F4A6C8","D46A9E","B04E84","7E3462"},
  teal={"7ED6C8","3A9A98","2C7A7E","1F5462"}, silver={"E8E8EE","B8B6C6","9A98AC","6E6C84"},
  plumblack={"7A5270","4A2E44","3A2238","1E1424"}, orange={"D88A4A","A85A2A","8A4826","6E3A1E"},
  grey={"E8E4DC","B8B4B0","8C8B90","6A6A70"}, white={"F6F4EE","DAD8DE","BCBAC6","908EA0"},
  darkgrey={"A8A6B0","7E7C8A","5E5C6A","403E4C"}, sandy={"E6D6B0","BCA680","94805E","6A5A42"},
  auburn={"D8704A","A8402E","88322A","5E1E22"}}
local SKIN={light={"F6D0A8","E4A87E","B8735E"},medium={"EDBC86","C98A58","8E5236"},deep={"AE7650","84502F","56301F"}}
local SKINK={"F6D0A8","E4A87E","B8735E"}

local BODY={
 ninja={hairK={"5D566F","3A3048","16101C"},hidx={1,2,4},front={1,2,3,4,9,10},
   outK={"778EB1","4A5F91","2D3662","1E2448"},
   excl=function(ln,fi,x,y) return ln=="upper" and y>=7 and y<=10 and x>=5 and x<=14 end,
   OUT={navy={"778EB1","4A5F91","2D3662","1E2448"},green={"7FAE6A","4E7F48","2E5232","1A3322"},plum={"A86E8E","7A4466","4E2646","2E1630"}}},
 kunoichi={hairK={"7A5270","4A2E44","1E1424"},hidx={1,2,4},front={1,2,3,4},
   outK={"B07BAE","914E87","622F55","311526","6E3A62","4A2244"},
   excl=function(ln,fi,x,y) return ln=="upper" and y<=8 end,  -- back-view headband underline uses 622F55
   OUT={plum={"B07BAE","914E87","622F55","311526","6E3A62","4A2244"},teal={"6EB8B4","3E8A8C","28585E","16323A","33606A","1E3A44"},
        green={"8EBC74","5A8C4E","365C34","1C301E","44604A","26382A"},red={"CC7E6E","A4504A","6A2E32","3A161E","643238","3E1E26"}}},
 elder={hairK={"E8E4DC","B8B4B0","8C8B90","6A6A70"},hidx={1,2,3,4},front={1,2,3,4},
   outK={"D8B98A","B08A5E","7A5A46","5E3F33"},
   OUT={tan={"D8B98A","B08A5E","7A5A46","5E3F33"},slate={"A8B4C8","7A889E","4E5A70","2E3448"},
        moss={"B0C490","7E9662","506640","34402A"},plum={"C8A0B8","9A6C8A","66425C","3E2638"}}},
 kid={hairK={"D88A4A","A85A2A","6E3A1E"},hidx={1,2,4},front={1,2,3,4},
   outK={"94B794","609F68","3F744C","21452F"},
   excl=function(ln,fi,x,y) return ln=="upper" and y>=5 and y<=7 and x>=3 and x<=12 end,
   OUT={green={"94B794","609F68","3F744C","21452F"},orange={"F4B07A","DC7A48","A84A30","5E2420"},
        blue={"9CC0E8","5A86C8","3A5C98","1E2E5A"},yellow={"F4E290","DCB444","A07E2A","5A4416"}}},
}
local function isFront(b,fi) for _,f in ipairs(BODY[b].front) do if f==fi then return true end end return false end

-- one combined remap: hair, skin, outfit (outfit honours the eye exclusion)
local function recolour(d,b,hair,skin,outfit)
  local B=BODY[b]
  local m1={}
  if hair then for i,k in ipairs(B.hairK) do m1[k]=HAIR[hair][B.hidx[i]] end end
  if skin then for i,k in ipairs(SKINK) do m1[k]=SKIN[skin][i] end end
  local m2={}
  if outfit then for i,k in ipairs(B.outK) do m2[k]=B.OUT[outfit][i] end end
  local f1,f2=mapfn(m1),mapfn(m2)
  for _,L in ipairs(d.layers) do for fi,c in pairs(L.cels) do
    px(c,function(xs,ys,v,xl,yl)
      local r=f1(v) if r then return r end
      if B.excl and B.excl(L.name,fi,xl,yl) then return nil end
      return f2(v) end) end end
end

-- hair styles (applied on the upper cel in cel-local coords, before recolour) -----------
local A="2A1E2E"
local STYLE={}
STYLE.topknot=function(d)  -- ninja: smooth dome + topknot
  local leg={A=A,B="3A3048",C="5D566F",D="16101C"}
  for fi,c in pairs(layer(d,"upper").cels) do eraseRows(c.img,0,4)
    rows(c.img,0,0,{"...........AAA..........","..........ABCBA.........",".......AAABCBBAAAA......",
      "....AAABCCBBBBBBBDAAAA..","...ABCCBBBBBBBBBBBBBBDA."},leg) end
end
STYLE.buns=function(d)  -- kunoichi: twin buns on the crown
  local leg={A=A,B="4A2E44",C="7A5270"}
  for fi,c in pairs(layer(d,"upper").cels) do
    rows(c.img,2,0,{".AAA..........AAA.","ABCBA........ABCBA","ABBBB........BBBBA",".A................"},leg) end
end
STYLE.bowl=function(d)  -- kid: rounded bowl cut
  local leg={A=A,B="A85A2A",C="D88A4A"}
  for fi,c in pairs(layer(d,"upper").cels) do eraseRows(c.img,0,1)
    rows(c.img,0,0,{"......AAAAAAA.....","....AABCCBBBBAA..."},leg) end
end
local ELDER_TOP={"..........AAA...........",".........AWWJA..........","........AAAAAAA.........",
  "......AASSGGGGGAA.......",".....ASSGGGGGGGGFA......"}
STYLE.bald=function(d)  -- elder: no hat, bald dome, white topknot, tufts and brows
  for fi,c in pairs(layer(d,"upper").cels) do
    if isFront("elder",fi) then eraseRows(c.img,0,8)
      local r={} for _,x in ipairs(ELDER_TOP) do r[#r+1]=x end
      r[#r+1]="....AWWGGGGGGGGGWWA....." r[#r+1]="....AWJGWWGGGWWGJWA....."
      rows(c.img,0,2,r,{A=A,S="F6D0A8",G="E4A87E",F="B8735E",W="E8E4DC",J="B8B4B0"})
    else eraseRows(c.img,0,7)
      local r={} for _,x in ipairs(ELDER_TOP) do r[#r+1]=x end
      r[#r+1]="....AWWWWWWWWWWWWJA....."
      rows(c.img,0,2,r,{A=A,S="F6D0A8",G="E4A87E",F="B8735E",W="8C8B90",J="6A6A70"})
    end end
end

-- looks ---------------------------------------------------------------------
local LOOKS={
 ninja={{"black","spiky","light","navy"},{"blond","spiky","medium","green"},{"brown","topknot","deep","plum"},
        {"black","topknot","medium","navy"},{"teal","spiky","light","plum"},{"silver","spiky","deep","green"},
        {"blond","topknot","light","plum"},{"brown","spiky","deep","navy"}},
 kunoichi={{"plumblack","long","light","plum"},{"pink","buns","light","teal"},{"brown","long","deep","green"},
        {"teal","buns","medium","red"},{"plumblack","buns","medium","green"},{"brown","buns","light","red"},
        {"pink","long","deep","teal"},{"auburn","long","medium","plum"}},
 elder={{"grey","hat","light","tan"},{"white","bald","medium","slate"},{"darkgrey","hat","deep","moss"},
        {"white","hat","light","plum"},{"grey","bald","deep","tan"},{"sandy","bald","light","moss"},
        {"darkgrey","bald","medium","plum"},{"sandy","hat","medium","slate"}},
 kid={{"orange","spiky","light","green"},{"black","bowl","medium","blue"},{"blond","spiky","deep","orange"},
        {"pink","bowl","light","yellow"},{"black","spiky","deep","green"},{"orange","bowl","medium","blue"},
        {"teal","spiky","medium","orange"},{"blond","bowl","light","green"}},
}
MANIFEST=MANIFEST or {}

function build_looks(b)
  local base=load(b)
  local s,first=newSprite(base)
  local groups={}
  for n,lk in ipairs(LOOKS[b]) do
    local d=clone(base)
    if STYLE[lk[2]] then STYLE[lk[2]](d) end
    recolour(d,b,lk[1],lk[3],lk[4])
    local g=s:newGroup() g.name=string.format("look%d %s-%s %s %s",n,lk[1],lk[2],lk[3],lk[4])
    addTo(s,d,g) groups[n]=g
  end
  s:deleteLayer(first)
  for n,g in ipairs(groups) do
    for m,h in ipairs(groups) do h.isVisible=(m==n) end
    local im=strip(s)
    savePng(im,ROOT..b.."_look"..n..".png")
    local lk=LOOKS[b][n]
    MANIFEST[b.."_look"..n]={body=b,role="",hair=lk[1].."_"..lk[2],skin=lk[3],outfit=lk[4],w=s.width,h=s.height,frames=#s.frames}
  end
  for m,h in ipairs(groups) do h.isVisible=(m==1) end
  s:saveAs(ROOT.."src/"..b.."_looks.aseprite")
  s:close()
  log(b.." looks done")
end

-- roles ---------------------------------------------------------------------
local function finishRole(d,name,body,hair,skin,outfit)
  local s,first=newSprite(d) addTo(s,d,nil) s:deleteLayer(first)
  s:saveAs(ROOT.."src/role_"..name..".aseprite")
  savePng(strip(s),ROOT.."role_"..name..".png")
  MANIFEST["role_"..name]={body=body,role=name,hair=hair,skin=skin,outfit=outfit,w=s.width,h=s.height,frames=#s.frames}
  s:close() log("role "..name.." done")
end

function build_guard()
  local d=load("ninja")
  local up=layer(d,"upper")
  local mask=mapfn({F6D0A8="F2F0EA",E4A87E="D6D4CE",B8735E="9C9AA6",FFFFFF=A,["2D3662"]="D6D4CE"})
  for fi,c in pairs(up.cels) do if isFront("ninja",fi) then
    px(c,function(xs,ys,v,x,y) if y>=7 and y<=12 and x>=4 and x<=15 then return mask(v) end end) end end
  remapAll(d,{["778EB1"]="7A8090",["4A5F91"]="4C5262",["2D3662"]="2C303E",["1E2448"]="1A1C26",
    B23C3A="8A8E9C",E0624A="B8BCC8",["7A2A36"]="5A5E6C"})
  -- painted stripe goes on after the armour remap so it keeps its red
  for fi,c in pairs(up.cels) do if isFront("ninja",fi) then
    rows(c.img,9,7,{"RR","RR","RR","RR","RR"},{R="A8323A"}) end end
  recolour(d,"ninja",nil,"deep",nil)
  local sp=addLayer(d,"spear","upper")
  local shaft={".A.","AGA","AFA","AFA","AMA"} for i=5,23 do shaft[#shaft+1]="AWA" end shaft[#shaft+1]=".A."
  for fi,c in pairs(sp.cels) do rows(c.img,21,0,shaft,{A=A,G="DDDFE0",F="A8B0BC",M="B23C3A",W="9A6A3E"}) end
  local gr=addLayer(d,"grip",nil)
  for fi,c in pairs(gr.cels) do rows(c.img,21,16,{"II","LL"},{I=SKIN.deep[2],L=SKIN.deep[3]}) end
  finishRole(d,"guard","ninja","black_spiky_masked","deep","steel_armour")
end

function build_teacher()
  local d=load("ninja")
  local up=layer(d,"upper")
  for fi=1,d.n do local dy=upperDy(d,fi)
    for _,L in ipairs(d.layers) do local c=L.cels[fi] if c then
      local f=mapfn({["383C4C"]="6E7A46",["25283A"]="465030",["5D6473"]="9AA46A"})
      px(c,function(xs,ys,v) if ys==19+dy then return f(v) end end) end end end
  recolour(d,"ninja","silver","medium",nil)
  remapAll(d,{["778EB1"]="9AA46A",["4A5F91"]="6E7A46",["2D3662"]="465030",["1E2448"]="2A321E",
    B23C3A="3E4C7C",E0624A="5C6EA0",["7A2A36"]="262E50"},BODY.ninja.excl)
  for fi,c in pairs(up.cels) do
    rows(c.img,0,20,{"...AQPPPPPPPPEEEEA......","...AAAAAAAAAAAAAAA......"},{A=A,Q="9AA46A",P="6E7A46",E="465030"})
    if isFront("ninja",fi) then rows(c.img,6,8,{"AAGAAAGA","AGGAAGGA"},{A=A,G="C8DCE8"}) end end
  local sc=addLayer(d,"scroll",nil)
  for fi,c in pairs(sc.cels) do rows(c.img,15,19,{"AAAAAA","AMPPMA","AMCCMA","AAAAAA"},{A=A,M="B23C3A",P="EDE3C8",C="C2B08C"}) end
  finishRole(d,"teacher","ninja","silver_spiky","medium","olive_long_vest")
end

function build_shopkeeper()
  local d=load("kunoichi")
  local up=layer(d,"upper")
  local crown=mapfn({["7A5270"]="E8946A",["4A2E44"]="C8643E",["1E1424"]="8A3A2A"})
  local band5=mapfn({["2D3662"]="C8643E",DDDFE0="E8946A",A8B0BC="C8643E",["6C7A9E"]="C8643E"})
  local band6=mapfn({["622F55"]="8A3A2A",["2D3662"]="8A3A2A",DDDFE0="C8643E",A8B0BC="8A3A2A",["6C7A9E"]="8A3A2A"})
  for fi,c in pairs(up.cels) do
    px(c,function(xs,ys,v,x,y) if y<=4 then return crown(v) elseif y==5 then return band5(v) elseif y==6 then return band6(v) end end)
    rows(c.img,19,4,{"AA..","BBA.","BSBA","AAAA"},{A=A,B="C8643E",S="8A3A2A"}) end
  local apron=mapfn({B07BAE="EEE6D2",["914E87"]="D6C8AA",["622F55"]="A8967A",["311526"]="7E6E58",["6E3A62"]="EEE6D2",
    ["4A2244"]="D6C8AA",D0A040="A8967A",F0D27A="D6C8AA",["8A5E24"]="7E6E58"})
  local string_=mapfn({D0A040="D6C8AA",F0D27A="EEE6D2",["8A5E24"]="A8967A"})
  local sleeve=mapfn({B07BAE="F6D0A8",["914E87"]="E4A87E",["622F55"]="B8735E",["311526"]="B8735E"})
  for fi=1,d.n do local dy=upperDy(d,fi) local front=isFront("kunoichi",fi)
    for _,L in ipairs(d.layers) do local c=L.cels[fi] if c then
      px(c,function(xs,ys,v)
        local y=ys-dy
        if front and xs>=6 and xs<=13 and y>=15 and y<=21 then return apron(v) end
        if y==18 then return string_(v) end
        if (y==16 or y==17) and (xs<=4 or xs>=18) then return sleeve(v) end end) end end end
  recolour(d,"kunoichi","brown","light","teal")
  finishRole(d,"shopkeeper","kunoichi","brown_long_headscarf","light","teal_apron")
end

function build_cook()
  local d=load("elder")
  local up=layer(d,"upper")
  for fi,c in pairs(up.cels) do
    local W,J="E8E4DC","B8B4B0"
    local r={"........AAAAAAA.........","......AASSGGGGGAAAAA....",".....AHHHHHHHHHHhHHhA..."}
    if isFront("elder",fi) then eraseRows(c.img,0,8)
      r[#r+1]="....AWWhhhhhhhhhWWAhA..." r[#r+1]="....AWJGWWGGGWWGJWAAA..."
    else eraseRows(c.img,0,7) W,J="8C8B90","6A6A70"
      r[#r+1]="....AWWhhhhhhhhhWJAhA..." end
    rows(c.img,0,4,r,{A=A,S="F6D0A8",G="E4A87E",F="B8735E",W=W,J=J,H="F2F0EA",h="D6D4CE"}) end
  recolour(d,"elder","darkgrey","medium",nil)
  remapAll(d,{D8B98A="F2F0EA",B08A5E="D6D4CE",["7A5A46"]="9C9AA6",["5E3F33"]="2D3662"})
  local tw=addLayer(d,"towel",nil)
  for fi,c in pairs(tw.cels) do rows(c.img,4,13,{"AAAA","ATtA","ATtA","ATtA","AUUA","AAAA"},{A=A,T="BCD8EC",t="8CB0D0",U="3E5C8A"}) end
  finishRole(d,"ramen_cook","elder","darkgrey_bald_white_headband","medium","white_cook")
end

function run_all(which)
  for _,w in ipairs(which) do
    if w=="guard" then build_guard() elseif w=="teacher" then build_teacher()
    elseif w=="shopkeeper" then build_shopkeeper() elseif w=="ramen_cook" then build_cook()
    else build_looks(w) end
  end
  print(table.concat(LOG,"\n"))
end
