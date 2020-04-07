pico-8 cartridge // http://www.pico-8.com
version 18
__lua__
cartdata "picodepon_high_scores"
hiscores = {dget(0), dget(1),
  dget(2)}

function hexstr2array(s, off)
 local a = {}
 off = off or 0
 for i = 1, #s do
  add(a, tonum(
    '0x' .. sub(s, i, i)) + off)
 end
 return a
end


function resethiscores()
 for i = 1, 3 do
  hiscores[i] = 0
  dset(i - 1, 0)
 end
end


function palt00()
 palt(0, false)
end

function palt131()
 palt(13, true)
end

bounceframecount = 10
coyotehangtime = 12
manualraiserepeatframes = 5
squashholdframes = 3
flashframes = 45
flashandfaceframes = 71
popoffset = 9
boardxpos = {3, 77}

blocktileidxs = {
  1, 17, 33, 49, 8, 24, 40
}

autoraisespeedstart = {
 60, 20, 12,
}

autoraisespeeddec = {
 1000, 600, 600,
}

autoraiseholdmult = {
 60, 45, 30,
}

garbageprob = {
 32, 64, 96
}

garbagesizes = {
 {3, 1}, {4, 1}, {5, 1},
 {6, 1}, {6, 2},
}

garbagerange = {
 2, 4, 5
}

function defconsts()
 shakesmall = hexstr2array(
  "010011001110001111")
 shakelarge = hexstr2array(
  "010101010101010010010011001100111023332111456665422269abbbba8"
 )

 bubdeltax = hexstr2array(
  "444444444444444444444444444444444444444400112222333343443434344445558",
  -4
 )
 
 bubdeltay = hexstr2array(
  "555554545454544544445444444444444445444481233444444544455455555577777",
  -4
 )
end

gs_mainmenu = 0
gs_selectmenu = 1
gs_gamestart = 2
gs_gameplay = 3
gs_gameend = 4

function _init()
 frame = 2
 pframe = 1
 cstate = 0
 prevcstate = 0
 squashframe = 0
 squashcount = 0

 defconsts()

 g_numplayers = 1
 g_levels = {2, 2}
 g_wins = {0, 0}
 
 g_chars = {1, 4}
 
 menuitem(2, "reset hi scores",
   resethiscores)

 startmainmenu()
end


function _update60()
 pframe = frame
 frame += 1
 
 prevcstate = cstate
 cstate = btn()
 
 if g_gamestate == gs_mainmenu
   then
  mainmenu_step()
 elseif g_gamestate
   == gs_selectmenu then
  selectmenu_step()
 else
  
  if g_gamestate == gs_gameplay
    then
   
   if g_musicstate !=
     g_anysquashed then
    g_musicstate = g_anysquashed
    if g_musicstate then
     music '15'
    else
     music '0'
    end
   end

   g_anysquashed = false

   g_ticks += 1
   if g_ticks >= 60 then
    g_ticks = 0
    g_seconds += 1
    
    if g_seconds >= 60 then
     g_seconds = 0
     g_minutes += 1
    end
   end
  end
 
  
  updategame()
 end
 
 if g_gamestate == gs_gameend
   then
  
  if g_gamecount < 180 then
   g_gamecount += 1
  else
   for i = 1, g_numplayers do
    if newpress(4, i - 1) or
      newpress(5, i - 1) then
      
      startselectmenu()
      break
    end
   end
  end
     
 end

end

function _draw()
 cls()
 
 if g_gamestate == gs_mainmenu
   then
  mainmenu_draw()
 elseif g_gamestate == 
   gs_selectmenu then
  selectmenu_draw()  
 else
  rectfill(0, 0, 127, 127, 5)
  
  
  if g_numplayers == 2 then
   for i = 1, 4 do
    map (0, 0, (i - 1) * 16,
      -boards[1].raiseoffset,
        2, 17)
    map (2, 0, 64 + (i - 1) * 16,
      -boards[2].raiseoffset,
        2, 17)
   end
  else
   for i = 1, 9 do
    map (4, 0, (i - 1) * 16,
      -boards[1].raiseoffset,
        2, 17)
   end
  end
  
  palt00()

  foreach(boards, board_draw)


  if #boards > 1 then
   wins_draw(53, 33)
   
   
   char_draw(g_chars[1],
    charidlefr(boards[1]),
      41, 0, true)
   char_draw(g_chars[2],
    charidlefr(boards[2]),
      66, 0)
   
   clock_draw(54, 24)
  else
   clock_draw(70, 82)
  end
  
  palt()
  
  foreach(matchbubs,
    matchbub_draw)

 if g_trans then
  trans(g_trans)
 end

 end
end


function wins_draw(x, y)
 rectfill(
    x + 1, y - 1, x + 20,
      y + 13, 1)
  
 rectfill(
   x + 2, y + 6, x + 9,
     y + 12, 12)
 
 rectfill(
   x + 11, y + 6, x + 19,
     y + 12, 14)
     
 print("wins", x + 4, y, 7)
 
 local p = function(x, y, v)
  if v < 10 then
   x += 2
  end
  print(v, x, y, 7)
 end
 
 p(x + 3, y + 7, g_wins[1])
 p(x + 12, y + 7, g_wins[2])
 
 if g_gamestate == gs_gameend
   and g_gamecount < 18 then
  palt(12, true)
  puff_draw(x + 7, y + 4,
    g_gamecount)
  palt(12, false)
 end
 
end

function clock_draw(x, y)
 rectfill(x - 2, y - 1,
   x + 21, y + 5, 1)
 
 local s = ''
 if g_minutes < 10 then
  s = s .. "0"
 end
 s = s .. g_minutes .. ":"
 if g_seconds < 10 then
  s = s .. "0"
 end
 
 s = s .. g_seconds
 print(s, x, y, 7)
end


function mainmenu_step()
 if newpress(2, 0) then
  if g_numplayers == 2 then
   g_numplayers = 1
  end
 end
 if newpress(3, 0) then
  if g_numplayers == 1 then
   g_numplayers = 2
  end
 end
 
 for c in all(clouds) do
  c.x += c.speed
  if c.x + c.w * 8 < 0 then
   
   del(clouds, c)
   add(clouds,
     rndcloud(128, c.y))
  end
 end
 
 if newpress(5, 0) then
  startselectmenu()
 end
end

function solo_draw(x, y)
 palt131()
 palt00()
 spr(85, x, y, 3, 2)
 spr(86, x + 24, y, 1, 2)
 palt()
end

function vs_draw(x, y)
 palt131()
 palt00()
 spr(88, x, y, 1, 2)
 spr(85, x + 8, y, 1, 2)
 palt()
end


function cloud_new(
  sx, sy, w, h, x, y, speed)
  
 local c = {
  sx = sx,
  sy = sy,
  w = w,
  h = h,
  x = x,
  y = y,
  speed = speed,
  tx = flr(rnd(10)) + 6,
  ty = flr(rnd(4)) + 5
 }
 
 return c
end

function cloud_draw(c)
 palt00()
 map(c.tx, c.ty, c.x, c.y,
   c.w, c.h)
 palt()
 pal(1, 0)
 map(c.sx, c.sy, c.x, c.y,
   c.w, c.h)
 pal()
end

clouddefs = {
 {6, 0, 6, 4},
 {12, 0, 4, 3},
 {16, 0, 5, 3},
 {17, 3, 3, 2}
}

function rndcloud(x, y)
 local def = clouddefs[
   flr(rnd(#clouddefs)) + 1]

 return cloud_new(
   def[1], def[2], def[3],
     def[4], x, y,
       -rnd(0.25) - 0.25)
end

clouds = {
 rndcloud(30, 7, -1),
 rndcloud(90, 45, -1),
}

function mainmenu_draw()
 rectfill(0, 0, 127, 86, 12)
 rectfill(0, 86, 127, 88, 5)
 rectfill(0, 89, 127, 128, 13)
 
 
 for c in all(clouds) do
  cloud_draw(c)
 end
 
 
 local drawlogo = function(y)
  spr(112, 1, y, 3, 1)
  spr(115, 26, y, 2, 1)
  spr(117, 43, y, 2, 1)
  spr(71, 1, y + 11, 8, 1)
 end
 
 pal(7, 0)
 pal(6, 0)
 drawlogo(67)
 pal()
 drawlogo(66)
 
 line(0, 86, 128, 86, 0)
 solo_draw(45, 92)
 vs_draw(45, 110)
 
 local y = 95
 if g_numplayers > 1 then
  y = 112
 end
 spr(15, 36, y)
end

function startmainmenu()
	g_gamestate = gs_mainmenu
	music "20"
end

function startselectmenu()
 g_gamestate = gs_selectmenu
 g_accepted = {0, 0}
 menuitem(1)
 matchsfx(1)
 music '-1'
end

function selectmenu_step()
 
 local acceptedmin = 3
 local acceptedmax = 0
 
 local fields = {
  {g_levels, 3},
  {g_chars, 8},
 }
 for i = 1, g_numplayers do
  
  acceptedmin = min(
    acceptedmin, g_accepted[i])
  
  acceptedmax = max(
    acceptedmax, g_accepted[i])
  
  if g_accepted[i] > 0 then
   if newpress(4, i - 1) then
    g_accepted[i] -= 1
   end
  end
  
  if g_accepted[i] < 2 then
   
   if newpress(5, i - 1) then
     g_accepted[i] += 1
     sfx '1'
   end
  end
  
  if g_accepted[i] < 2 then
   local f = fields[
     g_accepted[i] + 1]
   
   local cidx = i - 1

   if newpress(0, cidx) then
    if f[1][i] > 1 then
     f[1][i] -= 1
     sfx '3'
    end
   end
   
   if newpress(1, cidx) then
    if f[1][i] < f[2] then
     f[1][i] += 1
     sfx '3'
    end
   end
   
   if newpress(2, cidx) then
    if f[1][i] > 4 then
     f[1][i] -= 4
     sfx '3'
    end
   end
   
   if newpress(3, cidx) then
    if f[1][i] + 4 <= f[2] then
     f[1][i] += 4
     sfx '3'
    end
   end

  end
  
 end
 
 if acceptedmin == 2 then
  startgame()
 end
 
 if acceptedmax == 0 then
  for i = 1, g_numplayers do
   if newpress(4, i - 1) then
    startmainmenu()
   end
  end
 end
 
end

function char_draw(
  idx, fr, x, y, flp)
 rectfill(x, y,
    x + 21, y + 21, 1)
  
 rect(x + 1, y + 1,
    x + 20, y + 20, 6)
  
 spr(126 + 2 * idx + 32 * fr,
   x + 3, y + 3, 2, 2, flp)
  
end

function hiscore_draw(x, y)
 drawlabeledtext(x, y,
    "hi score",
       hiscores[g_levels[1]])
end


names = {
 "jelpi",
 "bal",
 "dancer",
 "space8",
 "ana",
 "madlne",
 "rainy",
 "lqdrm",
}


function selectmenu_draw()
 rectfill(0, 0, 127, 20, 13)
 
 levelselect_draw(1, 1, 25)
 
 if g_numplayers == 1 then
  solo_draw(3, 3)
  hiscore_draw(65, 35)
 else
  levelselect_draw(2, 65, 25)
  vs_draw(3, 3)
 end

 rectfill(0, 50,  127, 127, 1)
 
 line(0, 50, 127, 50, 1)
 

 local drawcurs = function(
   x, y, c, p)
  
  pal(7, c)
  palt131()
  palt00()
  
  local off = 0
  if p then
   if (frame + p) % 32 < 16 then
    off = 1
   end
  end
  
  spr(16, x - 4 - off,
    y - 4 - off)
  
  spr(16, x + 18 + off,
    y - 4 - off, 1, 1, true,
      false)
  
  
  spr(16, x  - 4 - off,
    y + 18 + off, 1, 1, 
      false, true)
  
  spr(16, x + 18 + off,
    y + 18 + off, 1, 1, 
      true, true)
  
  
  pal()
  palt() 
 end
 
 for i = 1, 8 do
  local x = 2 + (i - 1) * 32
  local y = 56
  if i > 4 then
   y += 34
   x -= 128
  end

  palt00()
  
  local fr = 0
  for j = 1, 2 do
   if g_accepted[j] == 2 and
     g_chars[j] == i then
    fr = 2
   end
  end
  
  char_draw(i, fr, x + 3, y)
  print(names[i], x + 4,
    y + 24, 6)
  local f1 = function(j, c)
   if j > g_numplayers then
    return
   end
   if i == g_chars[j] and
     g_accepted[j] > 0 then
    local p
    if g_accepted[j] == 1 then
     p = 0
    end
    drawcurs(x + 3, y, c, p)
   end
  end

  if (frame + 8) % 32 < 16 then
   f1(1, 12)
   f1(2, 14)
  else
   f1(2, 14)
   f1(1, 12)
  end
  
 end
 

end


lvlnames = {
 "easy", "med", "hard"}

lvlcolors = {3, 9, 8}
playercolors = {12, 14}
function levelselect_draw(
  idx, x, y)
  
 spr(68 + idx, x, y)
 y += 10
 
 if g_accepted[idx] == 0 then
  rect(x - 1, y - 1, x + 55,
    y + 9, playercolors[idx])
 end
 
 for i = 1, 3 do
  local bgcolor = 0
  local fgcolor = 1
  
  if g_levels[idx] == i then
   bgcolor = lvlcolors[i]
   fgcolor = 0
  end
  
  rectfill(x, y, x + 18, y + 8,
    bgcolor)
  
  rect(x, y, x + 18, y + 8, 1)
  
  local xx = x + 2
  if i == 2 then
   xx += 2
  end
  print(lvlnames[i],
    xx, y + 2, fgcolor)
  x += 18
 end
 
end








function startgame()
 
 menuitem(1, "cancel game", 
   startselectmenu)
 
 g_gamestate = gs_gamestart
 g_gamecount = 0
 
 g_minutes = 0
 g_seconds = 0
 g_ticks = 0
 
 g_musicstate = false

 matchbubs = {}
 boards = {}
 boards[1] = board_new()

 if g_numplayers > 1 then
  boards[2] = board_new()
  boards[1].target = boards[2]
  boards[2].target = boards[1]
 end

 local s = rnd(31767)
 local nlrd =
   boards[1].nextlinerandomseed
 for i = 1, #boards do
  local b = boards[i]
  b.idx = i
  b.level = g_levels[i]
  b.autoraisespeed = 
    autoraisespeedstart[
      g_levels[i]]
  
  b.garbageprob =
    garbageprob[b.level]
  if b.level == 3 then
   b.blocktypecount = 6
  end
  srand(s)
  board_fill(b, 6)
  b.nextlinerandomseed = nlrd
  if #boards > 1 then
   b.x = boardxpos[i]
   b.contidx = i - 1
  end
  
 end

 

end

bs_idle = 0
bs_matching = 1
bs_swapping = 2
bs_coyote = 3
bs_postclearhold = 4
bs_garbage = 5
bs_garbagematching = 6

bounceframes = {
 0, 3, 3, 3,
 4, 4, 4, 4, 2, 2, 2, 0
}

squashframes = {
 2, 0, 3, 4, 3, 0
}

function block_new()
 return {
  btype=0,
  state=bs_idle,
  count=0,
  count2=0,
  fallframe=0,
  chain=0,
  fallenonce=false,
  garbagex=0,
  garbagey=0,
  garbagewidth=0,
  garbageheight=0,
 }
end

cs_idle = 0
cs_swapping = 1

function board_new()
 local b = {}

 b.blocks = {}
 for i = 1, 13 do
  local row = {}
  b.blocks[i] = row
  
  for j = 1, 6 do
   row[j] = block_new()
  end
 end

 b.blocktypecount = 5


 b.cursx = 0
 b.cursy = 6
 b.cursstate = cs_idle
 b.curscount = 0
 b.cursrepeatpause = 0
 b.cursrepeatcount = 0
 b.cursbumpx = 0
 b.cursbumpy = 0
 b.contidx = 0
 
 b.rowstart = 0
 b.raiseoffset = 0
 b.manualraise = 0

 b.nextlinerandomseed =
   rnd(32767)
 
 b.x = 8
 b.y = 32
 
 b.matchrecs = {}
 
 b.autoraisehold = 0
 b.autoraisecounter = 0
 b.autoraisespeed = 60
 
 b.autoraisedeccounter
   = 0

 b.shakecount = 0
 
 b.pendinggarbage = {}
 b.pendingoffset = 0
 
 b.toppedoutframecount = 0
 
 b.score = 0

 return b
end


function board_getrow(b, idx)
 return b.blocks[(
   (idx + b.rowstart - 1) % 13
     ) + 1]
    
end

function board_fill(b, startidx)
 local horzruntype = 0
 local vertruntype = 0
 for y = 13, startidx, -1 do
  local row = board_getrow(b, y)
  for x = 1, 6 do
   if (x == 3 or x == 4) and
     y < 10 then
    goto cont
   end
   
   
   horzruntype = 0
   if x > 2 then
    if row[x - 2].btype ==
      row[x - 1].btype then
     horzruntype =
       row[x - 1].btype
    end
   end
   vertruntype = 0
   if y < 11 then
    local row2 =
      board_getrow(b, y + 1)
    local row3 =
      board_getrow(b, y + 2)
  
      
    if row2[x].btype ==
      row3[x].btype then
     vertruntype =
       row2[x].btype
    end 
   end
   
   
   
   
   if horzruntype > 0 or
     vertruntype > 0 then
   
    local types = {}
    for t = 1, b.blocktypecount
      do
     if t != horzruntype and
       t != vertruntype then
      types[#types + 1] = t
     end
    end
 
    row[x].btype = types[
      flr(rnd(#types)) + 1]
  
   else    
    row[x].btype =
      flr(rnd(
        b.blocktypecount)) + 1
   end
  
   
   ::cont::
   
  end
 end
 
 
end

function board_addgarbage(b,
  x, y, width, height,
    forcey, forceh)
 
 for yy = y - (height - 1), y do
  
  if yy > 0 then
   local row =
     board_getrow(b, yy)
   
   for xx = x, x + width - 1 do
    local bk = row[xx]
    
    bk.state = bs_garbage
    bk.garbagex = xx - x
    bk.garbagey = -(yy - y)
    bk.garbagewidth = width
    bk.garbageheight = height
    bk.btype = 10
    bk.fallenonce = false
    bk.fallframe = frame
    if forcey then
     bk.garbagey = forcey
    end
    if forceh then
     bk.garbageheight = forceh
    end
   end
  end 
 end

end


function _cursdir(b, bidx)
 
 if not press(bidx, b.contidx)
   then return end
  
 if newpress(bidx, b.contidx)
   then
  b.cursrepeatpause = 0
  b.cursrepeatcount = 0
 end

 if b.cursrepeatpause == 0
   then
  if b.cursrepeatcount == 0
    then
   b.cursrepeatcount = 1
   b.cursrepeatpause = 8

  else
   b.cursrepeatpause = 0
  end
  return true
 else
  b.cursrepeatpause -= 1
 end

end

function stateisswappable(s)
 if s == bs_idle
   or s == bs_postclearhold
   then
  return true
 end
end

function hasblock(bk, bkbelow)
 if not bk then
  return
 end
 if bk.btype > 0 and
   (not bkbelow or
     bkbelow.btype > 0)
   then
  return true
 end
end

function canswap(bk, bkbelow)
 if bk.btype == 0 or (
    not bkbelow
    or bkbelow.btype > 0
    ) then
  return true
 end
end

function board_getcursblocks(
  b, below)
 local off = 1
 if below then
  off += 1
 end
 local row =
    board_getrow(b, b.cursy
      + off)
 
 return row[b.cursx + 1],
   row[b.cursx + 2]
end

cursshakeframes =
  hexstr2array("00112211", -1)

function board_cursinput(b)
 if g_gamestate != gs_gameplay
   then
  return
 end

 b.cursbumpx = 0
 b.cursbumpy = 0
 
 if b.cursstate != cs_idle then
  return
 end
 
 if newpress(5, b.contidx) then
  local bk1, bk2 =
    board_getcursblocks(b)
   
  local bk1below
  local bk2below
  if b.cursy < 12 then
   bk1below, bk2below =
     board_getcursblocks(b, 1)
  end
  
  if stateisswappable(bk1.state)
    and stateisswappable(
      bk2.state)
    and (hasblock(bk1, bk1below)
     or hasblock(bk2, bk2below))
    and (canswap(bk1, bk1below)
     and canswap(bk2, bk2below))
    then
   
   bk1.state = bs_swapping
   bk2.state = bs_swapping
   b.cursstate = cs_swapping
   b.curscount = 0
   sfx '9'
   return
  else   
   maskpress(bnot(shl(1, 5)),
     b.contidx)
   
   if (
     stateisswappable(bk1.state)
     and hasblock(bk1, bk1below)
     and canswap(bk1, bk1below)
     ) or (
     stateisswappable(bk2.state)
     and hasblock(bk2, bk2below)
     and canswap(bk2, bk2below)
     ) then
    
    b.cursbumpx = 
      cursshakeframes[
        (frame % 8) + 1]
   end
  end
 
 
 
 end
 
 
 if b.cursy > 0 and
   (not (b.cursy == 1
     and b.raiseoffset > 3))
   and _cursdir(b, 2) then
  b.cursy -= 1
  sfx '3'
 end
 
 if b.cursy < 11 and
   _cursdir(b, 3) then
  b.cursy += 1
  sfx '3'
 end
 
 if b.cursx > 0 and
    _cursdir(b, 0) then
  b.cursx -= 1
  sfx '3'
 end
 
 if b.cursx < 4 and
   _cursdir(b, 1) then
  b.cursx += 1
  sfx '3'
 end
 
end



function board_raise(b)
 local toprow =
   board_getrow(b, 1)

 for i = 1, 6 do
  if toprow[i].btype > 0 then
   b.manualraise = 0
   return
  end
 end

 b.raiseoffset += 1
 
 if b.raiseoffset == 8 then
  b.raiseoffset = 0
  if b.cursy > 0 then
   b.cursy -= 1
  end
  b.rowstart =
    (b.rowstart + 1) % 13
  
  b.nextlinerandomseed += 1
  srand(b.nextlinerandomseed)
  
  local botrow =
    board_getrow(b, 13)
  
  local runlen = 0
  local lasttype = 255
  for i = 1, 6 do
   local t = flr(
     rnd(b.blocktypecount))
   
   if t == lasttype then
    runlen += 1
    if runlen > 2 then
     t = t + flr(rnd(
       b.blocktypecount - 1)
         ) + 1
     t = t % b.blocktypecount
     runlen = 1
    end
   else
    runlen = 1
   end
   
   if rnd(128) < 8 then
    t = 6
   end 
   
   botrow[i].count = 0
   botrow[i].chain = 0
   botrow[i].state = bs_idle
   botrow[i].btype = t + 1
   lasttype = t
  end
  
  for mrec in all(b.matchrecs)
    do
   mrec.y -= 1
  end
  
  if not b.target then
   if rnd(256) < 
     b.garbageprob then

    local s =
      garbagesizes[
        flr(rnd(
          garbagerange[
            b.level])) + 1]

    board_appendgarbage(b,
      s[1], s[2])
   end
  end
  
 
 elseif b.raiseoffset == 2 then
  if b.cursstate == cs_idle and
    b.cursy == 0 then
   b.cursy = 1
  end
 end

end

function runrec_new()
 return {btype=0, len=0}
end

function matchrec_new()
 return {
  x=0,
  y=0,
  dur=0,
  chain=0,
  seqidx=0,
  puffcount=255,
 }
end


function board_step(b)
 if g_gamestate != gs_gameplay
   then
  return
 end

 b.autoraisedeccounter += 1
 if b.autoraisedeccounter >=
   autoraisespeeddec[
     b.level] then
  
  b.autoraisedeccounter = 0
  if b.autoraisespeed > 3 then
    b.autoraisespeed -= 1
  elseif b.garbageprob < 96 then
   b.garbageprob += 2
  end
 end
 
 if b.autoraisehold > 0 then
  b.autoraisehold -= 1
 end

 if press(4, b.contidx) then
  
  local raise = true
  if b.raiseoffset == 0 then
   if newpress(4, b.contidx)
     then
    b.manualraise =
      manualraiserepeatframes
   else
    b.manualraise -= 1
    if b.manualraise > 0 then
     raise = false
    end
   end
  else
   b.manualraise =
     manualraiserepeatframes
  end
  
  if raise then
   board_raise(b)
  end
 elseif b.raiseoffset > 0 and
   b.manualraise > 0 then
   board_raise(b)
 else
  b.manualraise = 0

  if #b.matchrecs == 0
    and b.autoraisehold == 0
    then
   b.autoraisecounter += 0.5
   if b.autoraisecounter >=
     b.autoraisespeed then
    b.autoraisecounter = 0
    board_raise(b)
   end
  
  end
  
 end
 
 board_cursinput(b)
 
 if b.cursstate == cs_swapping
   then
  local bk1, bk2 =
    board_getcursblocks(b)
  
  if b.curscount < 3 then
   b.curscount += 1
  else
   b.cursstate = cs_idle
   local t = bk1.btype
   bk1.btype = bk2.btype
   bk2.btype = t
   bk1.state = bs_idle
   bk2.state = bs_idle
   
   
   
   function postswap(x, y)
    local bmid = board_getrow(
      b, y)[x]
    
    local bdown
    if y < 13 then
     bdown = board_getrow(
      b, y + 1)[x]
    end
    
    local bup
    if y > 1 then
     bup = board_getrow(
      b, y - 1)[x]
    end
    
    if bmid.btype > 0 then
     if bdown then
      if bdown.btype == 0 then
       bdown.state = bs_coyote
       bdown.count =
         coyotehangtime
      end
     end
     bmid.count = 0
    else
     if bup then
      if bup.btype > 0 then
       bmid.state = bs_coyote
       bmid.count = coyotehangtime
      end
     end
    end
   end
   
   postswap(b.cursx + 1,
     b.cursy + 1)
   postswap(b.cursx + 2,
     b.cursy + 1)
     

   maskpress(bnot(7),
     b.contidx)
   
  end
 end
 
 -- board scan
 local rows = {}
 for i = 1, 13 do
  rows[i] = board_getrow(b, i)
 end
 
 local horzrun = runrec_new()
 local vertruns = {}
 
 for i = 1, 6 do
  vertruns[i] = runrec_new()
 end
 
 local newmatchminx = 7
 local newmatchminy = 13
 
 local matchseqmap = {}
 local newmatchseqs = {}
 
 local newmatchchainmax = 0
 local garbagefallarea = 0
 
 local metalcount = 0
 
 local checkhorzrun =
   function(x1, y1)
  if horzrun.len < 3 then
   return
  end
  
  if horzrun.btype == 7 then
   metalcount += horzrun.len
  end
  
  local matchseq = {}
  add(newmatchseqs, matchseq)
  local row = board_getrow(
    b, y1)
  local pad = flashandfaceframes
  local dur = pad +
      horzrun.len * popoffset
  
  
  local chainmax = 0
  
  local rx = x1 - horzrun.len
  newmatchminy = min(
     newmatchminy, y1)
  
  for r = 1, horzrun.len do
   local runbk =
     row[rx]
   
   runbk.state = bs_matching
   runbk.count = 0
   runbk.count2 = pad

   matchseqmap[
     rx + shl(y1, 4)] =
       matchseq

   local mrec = matchrec_new()
   mrec.x = rx
   mrec.y = y1
   mrec.dur = dur
   mrec.seqidx = r - 1
   add(matchseq, mrec)
   
   chainmax = max(chainmax,
     runbk.chain + 1)
   mrec.chain = chainmax
   newmatchminx = min(
     newmatchminx, rx)
     
   pad += popoffset
   rx += 1
  end
  
  --if chainmax > 1 then
   for mrec in all(matchseq) do
    mrec.chain = chainmax
   end
  --end
  
  newmatchchainmax = max(
    newmatchchainmax, chainmax)
 end
 
 local checkvertrun = function(
   x1, y1)
  if vertruns[x1].len < 3 then
   return
  end
  local runlen =
    vertruns[x1].len
  local runlendur =
    runlen * popoffset
  
  newmatchminx = min(
     newmatchminx, x1)
     
  local pad = flashandfaceframes
  local dur = pad + runlendur
  local ry = y1
  local chainmax = 0
  local crosschainmax = 0
  local runoffset = 0
  local runbtype =
    vertruns[x1].btype
  
  local hmatchseq
  
  for r = 1, runlen do
   local runbk =
     board_getrow(b, ry)[x1]
   
   local key = x1 + shl(ry, 4)
   if not hmatchseq and
     matchseqmap[key] then
    hmatchseq =
      matchseqmap[key]
    
    pad = hmatchseq[1].dur
    dur = pad + runlendur
    
    for mrec in all(hmatchseq)
      do
     mrec.dur = dur
    end
    
    chainmax = max(chainmax,
      hmatchseq[1].chain)
   else
    if runbk.btype == 7 then
     metalcount += 1
    end
    chainmax = max(chainmax,
      runbk.chain + 1)
   end
     
   
   ry += 1
  end
 
  local matchseq
  if hmatchseq then
   matchseq = hmatchseq

   for mrec in all(matchseq) do
    mrec.chain = chainmax
   end

   runoffset = #matchseq - 1
  else
   matchseq = {}
   add(newmatchseqs, matchseq) 
  end
  
  local mrec
  ry = y1
  for r = 1, runlen do
   local runbk =
     board_getrow(b, ry)[x1]
   
   if runbk.state ==
     bs_matching then
    goto cont
   end
   
   runbk.state = bs_matching
   runbk.count = 0
   runbk.count2 = pad
   
   mrec = matchrec_new()
   mrec.x = x1
   mrec.y = ry
   mrec.dur = dur
   mrec.chain = chainmax
   mrec.seqidx =
     r - 1 + runoffset
   add(matchseq, mrec)
   
   newmatchminy = min(
     newmatchminy, ry)
   
   ::cont::
   
   ry += 1
   pad += popoffset
  end
  
  newmatchchainmax = max(
    newmatchchainmax, chainmax)
 
 end
 
 local prevrow
 local row
 for y = 12, 1, -1 do
  row = rows[y]
  horzrun.len = 0
  horzrun.btype = 0
  for x = 1, 6 do
   
   local bk = row[x]
   if bk.state == bs_coyote or
     bk.state ==
       bs_postclearhold
     then
    bk.count -= 1
    if bk.count <= 0 then
     bk.state = bs_idle
    end
   end
  
   if bk.state == bs_idle
     and bk.btype > 0 then
    
    if prevrow then
    
     local bkbelow = prevrow[x]

     if bkbelow.state == bs_idle
       and bkbelow.btype == 0
       then
       
      bkbelow.btype = bk.btype
      bkbelow.fallframe =
        frame
      bkbelow.count = 0
      bkbelow.chain = bk.chain
      
      bk.btype = 0
      bk.count = 0
      bk.chain = 0
      
      horzrun.len = 0
      horzrun.btype = 0
      
      goto cont
      
     end
    end
    
    -- was falling but stopped
    if bk.fallframe ==
      pframe then
     bk.count =
       bounceframecount
     --sfxdrop
     sfx '10'
    else
     -- not falling
     if bk.count > 0 then
      bk.count -= 1
      
      -- chainresetcount
      if bk.count == 7 then
       bk.chain = 0
      end
     
     end
    
     
    end
    
    if (bounceframecount -
      bk.count) < 2 then
     
     checkhorzrun(x, y)
     horzrun.btype = 0
     horzrun.len = 1
     
     checkvertrun(x, y + 1)
     vertruns[x].btype = 0
     vertruns[x].len = 1
    
    else
     
     if horzrun.btype ==
       bk.btype then
      horzrun.len += 1
     else
      checkhorzrun(x, y)
      horzrun.btype = bk.btype
      horzrun.len = 1
     end
     
     if vertruns[x].btype ==
       bk.btype then
      vertruns[x].len += 1
      
      if y == 1 then
       checkvertrun(x, 1)
      end
     else
      checkvertrun(x, y + 1)
      vertruns[x].btype =
        bk.btype
      vertruns[x].len = 1
     end
     
     
    end
    
   else
    checkhorzrun(x, y)
    horzrun.btype = 0
    horzrun.len = 0
    
    checkvertrun(x, y + 1)
    vertruns[x].btype = 0
    vertruns[x].len = 0
    
    if prevrow and
      bk.state == bs_garbage and
      bk.garbagex == 0 then
      
      
      local clearbelow = true
      for i = x,
        x + bk.garbagewidth - 1
        do
       local bbk = prevrow[i]
       if bbk.state != bs_idle
         or bbk.btype != 0 then
        clearbelow = false
        break
       end
      end
      
      if clearbelow then
       for i = x,
         x + bk.garbagewidth - 1
         do
        prevrow[i] = row[i]
        row[i] = block_new() 
        prevrow[i].fallframe =
          frame
       end     
       
       if y == 1 and
         bk.garbagey <
          bk.garbageheight - 1
          then
        board_addgarbage(b, x, 1,
          bk.garbagewidth, 1,
          bk.garbagey + 1,
          bk.garbageheight)
       end
      
      else
       if bk.fallframe ==
         pframe then
         
        sfx '10'
       elseif bk.garbagey == 0
         and not bk.fallenonce
         then
        bk.fallenonce = true
        garbagefallarea = 
          garbagefallarea +
            bk.garbagewidth *
            bk.garbageheight
            
        
       end
      end
      
    end
    
   end
   
   ::cont::
   
  end
  checkhorzrun(7, y)
  prevrow = row
 end
 
 local matchcount = 0
 
 
 if #newmatchseqs > 0 then
  local seqidxstartr = {0}
  
  for ms in all(newmatchseqs)
    do
   matchcount += #ms
   for j = 1, #ms do
    local m = ms[j]
    add(b.matchrecs, m)
    
    local _breakgarb =
      function(xo, yo)
     if board_getrow(b,
       m.y + yo)[
         m.x + xo].state ==
           bs_garbage then
      
      board_breakgarbage(
       b, m.x + xo, m.y + yo,
         m.dur, m.chain,
           seqidxstartr) 
     end
    end
    
    
    -- left
    if m.x > 1 then
     _breakgarb(-1, 0)
    end
    
    if m.x < 6 then
      _breakgarb(1, 0)
    end
    
    if m.y > 1 then
     _breakgarb(0, -1)
    end
    
    if m.y < 12 then
     _breakgarb(0, 1)
    end
    
   end
   
  end
  --transfer to active match
 end
 
 local activematches = {}
 
 for m in all(b.matchrecs) do 
  local keep = true
  if m.dur > 0 then
   local bk = board_getrow(b,
     m.y)[m.x]
   
   bk.count = bk.count + 1
   
   if bk.count >= m.dur then
    m.dur = 0
    -- postclearholdframes
    bk.count = 3
    if bk.state == bs_matching
      then
     bk.state =
       bs_postclearhold
     
     
     bk.btype = 0
     bk.chain = 0
     
     -- walk up and max chain
     for y = m.y - 1, 1, -1 do
      local runbk =
        board_getrow(b, y)[m.x]
       
      if runbk.btype == 0 or
        (runbk.state != bs_idle
        and runbk.state !=
          bs_garbage) then
       break
      end
      
      runbk.chain = max(
        runbk.chain, m.chain)
     end
     
    elseif bk.state ==
      bs_garbagematching then
     bk.state =
       bs_postclearhold 
     bk.chain = max(bk.chain,
       m.chain)
     
     bk.fallframe = frame
    
    end
   elseif bk.count == bk.count2
     then
    m.puffcount = 0
    --sfxpop
    sfx(8, -1, min(
      m.seqidx, 31), 1)
   end
  
  end
  
  if m.puffcount != 255 then
   if m.puffcount >= 18 then
    if m.dur == 0 then
     keep = false
     
    end
   else
    m.puffcount += 1
   end
  end
  
  
  if keep then
   add(activematches, m)
  end
 end
 
 b.matchrecs = activematches
 
 local holdtotal = 0
 
 local lastbub
 
 local buboffset = 0
 
 
 local mx =
    (newmatchminx - 1) * 8
      + b.x - 4
 local my =
    (newmatchminy - 1) * 8
      + board_getyorg(b) - 4
 
 
 if metalcount >= 3 then  
  matchcount -= metalcount
  if matchcount <= 0 then
   newmatchchainmax = 0
  end
  
  
  local bub = matchbub_new(
    0, matchcount, mx, my)
  add(matchbubs, bub)
  
  bub.matchcount = 0
  bub.matchchain =
    metalcount - 2

  matchsfx(bub.matchchain)

  if b.target then
   bub.target = b.target 
  else
   bub.target = b
   bub.targetpos =
     {70, b.y}
  end
    
 end

 
 if matchcount > 3 then
  lastbub = matchbub_new(
    0, matchcount, mx, my)
  add(matchbubs, lastbub)
 
  buboffset = 11
  holdtotal = matchcount - 1
 end
 
 if newmatchchainmax > 1 then
  
  my -= buboffset
  
  lastbub = matchbub_new(1,
    newmatchchainmax, mx, my)
  add(matchbubs, lastbub)
  
  if holdtotal == 0 then
   holdtotal = 2
  end
  
  holdtotal *= newmatchchainmax
  
 end
 
 if holdtotal > 0 then
  holdtotal = holdtotal *
    autoraiseholdmult[b.level]
   
  b.autoraisehold += holdtotal
  
 end
 
 if lastbub then
  if b.target then
   lastbub.target = b.target
  else
   lastbub.target = b
   lastbub.targetpos =
     {70, b.y}
  end
  
  lastbub.matchcount = 
    matchcount
  lastbub.matchchain =
    newmatchchainmax

  matchsfx(newmatchchainmax)

 end
 
 if garbagefallarea > 0 then
  if garbagefallarea > 4 then
   b.shakevalues = shakelarge
  else
   b.shakevalues = shakesmall
  end
  b.shakecount = #b.shakevalues
 end
 
 board_pendingstep(b)
 
 local anyattop = false
 local toprow =
   board_getrow(b, 1)
 for i = 1, 6 do
  if toprow[i].btype > 0 then
   anyattop = true
   break
  end
 end
 
 if anyattop then
  if b.autoraisehold == 0 and
    #b.matchrecs == 0 then
   b.toppedoutframecount += 1
   
   -- toppedoutboardframelimit
   if b.toppedoutframecount >=
     120 then
    board_lose(b) 
   end
  end
 else
  b.toppedoutframecount = 0  
 end
 
 
end


function matchsfx(n)
 local length = n + 2
 if length >= 7 then length = 9 end
 sfx(4, -1, 0, length)
end

function board_lose(b)
 b.lose = true
 music '-1'
 sfx(7)
 if b.target then
  g_wins[b.target.idx] += 1 
 end
 
 for i = 1, 13 do
  local row = board_getrow(b, i)
  for j = 1, 6 do
   local bk = row[j]
   if bk.btype > 0 then
    if bk.state != bs_garbage
      and bk.state !=
        bs_garbagematching
      then
     bk.state = bs_matching
      
    else
     bk.state =
       bs_garbagematching
    end
    bk.count2 = 100
    bk.count = flashframes + 2
   end
  end
 end
 
 g_gamestate = gs_gameend
 g_gamecount = 0
 
 matchbubs = {}
 
 b.shakevalues = shakelarge
 b.shakecount = #shakelarge
 
 
end

function block_draw(b, x, y, ry,
  squashed)
 if b.btype == 0
   or b.bstate == bs_swapping
   then
  return
 end
 
 if b.state == bs_idle then
  local idx = blocktileidxs[
    b.btype]
  
  if b.count > 0 then
   idx += bounceframes[b.count]
  elseif squashed then
   idx = idx + squashframes[
     squashframe + 1]
  end

  spr(idx, x, y)
 
 
 elseif b.state == bs_matching
   then
  
  local idx = blocktileidxs[
    b.btype]
  
  if b.count < flashframes then
   if frame % 2 == 0 then
    idx += 6
   end
  elseif b.count < b.count2 then
   idx += 5
  else
   return
  end
  
  spr(idx, x, y)
 
 elseif b.state == bs_garbage
   then
  
  
  if b.garbagex == 0 and
    b.garbagey == 0 then
   
   local top = y -
     (b.garbageheight - 1) * 8
   
   local right = x +
     b.garbagewidth * 8 - 1
   
   local left = x
   local bottom = y + 7
   
   local bg = 0
   local fg = 5
   if b.btype > 10 then
    bg = 5
    fg = 0
   end
   
   rectfill(left, top, right,
     bottom, bg)
   rect(left + 1, top + 1,
     right - 1, bottom - 1, fg)
   
   palt131()
   
   local idx = 31
   if (frame % 120) < 10 then
    idx = 47
   end
   
   spr(idx,
     (right - left) / 2 +
     left - 3,
     (bottom - top) / 2 +
     top - 3, 1, 1,
      frame % 320 < 160
       )
    
   palt(13, false)
  
  end
    
 
 elseif b.state ==
   bs_garbagematching then
  
  local idx = 62
  if b.count < flashframes then
   if frame % 2 == 0 then
    idx = 63
   end
  elseif b.count < b.count2 then
  else
   idx = blocktileidxs[
    b.btype]

  end
  
  spr(idx, x, y)
  
 end
 
end

function board_getyorg(b)
 local y = b.y - b.raiseoffset
 
 if b.shakevalues then
  y = y - b.shakevalues[
    max(1, min(b.shakecount,
      #b.shakevalues))] / 2
 end

 return y
end

function puff_draw(x, y, pc)
 
 local n = pc / 17
 local g = n * 16
 local d = (n^0.75) * 16
 spr(48, x - d, y - d + g)
 spr(48, x + d, y - d + g)
 spr(48, x - d, y + d + g)
 spr(48, x + d, y + d + g)

end

function board_draw(b)
 local x = b.x
 local y = b.y
  
 palt(0, true)
 local lvlpos = 8
 if x < 63 then
  spr(69, 0, 0)
 else
  lvlpos = 111
  spr(70, 121, 0)
 end
 
 
 rectfill(lvlpos, 0,
   lvlpos + 8, 8,
   lvlcolors[b.level])
 rect(lvlpos, 0,
   lvlpos + 8, 8, 1)
 
 spr(120 + b.level, lvlpos + 1,
  1)
 
 
 palt00()
 
 
 rectfill(x - 2, y - 1,
   x + 1 + 6 * 8,
   y + 1 + 12 * 8, 13)
 
 rect(x - 1, y,
   x + 6 * 8,
   y + 1 + 12 * 8, 1)
   
 rect(x - 2, y - 1,
   x + 1 + 6 * 8,
   y + 1 + 12 * 8, 7)
   
 
 local r1 = board_getrow(b, 1)
 local r2 = board_getrow(b, 2)
 local squashed = {}

 local _sqtest = function(bk)
  if bk.btype > 0
    and bk.fallframe != frame
      then
   return true
  end
 end
 
 for i = 1, 6 do
  squashed[i] = (
    _sqtest(r1[i]) or
      _sqtest(r2[i]))
  if squashed[i] then
   g_anysquashed = true
  end
 end
 
 clip(0, y, 128, 128 - y)
 
 y -= b.raiseoffset
 
 if b.shakecount > 0 and
   b.shakevalues then
  
  b.shakecount -= 1
  y = y - b.shakevalues[
    b.shakecount + 1] / 2
 else
  b.shakevalues = nil
 end
 
 local yy = y
 
 -- draw blocks
 for ty = 1, 13 do
  local row = board_getrow(b, ty)
  local xx = x
  
  for tx = 1, 6 do
   local bk = row[tx]
   
   block_draw(bk, xx, yy, ty,
     squashed[tx])
   
   xx += 8
  end
 
  yy += 8
 end
 
 
 -- shadow
 palt(0, true)
 map(6, 4, x, yy - 8, 6, 1)
 palt00()
 
 clip()
 
 palt(12, true)
 for m in all(b.matchrecs) do 
  if m.puffcount != 255 and 
    m.puffcount < 18 then
  
   puff_draw((m.x - 1) * 8 + x,
     (m.y - 1) * 8 + y,
       m.puffcount)
   
  end
 
 end
 palt(12, false)
 
 if b.autoraisehold > 0 then
  local top = max(b.y, 128 -
    (b.autoraisehold / 2))
    
  local x = b.x - 2
  if b.x > 63 then
   x = b.x + 49
  end
  
  line(x, top, x, 127, 11) 
 
 end
 
 -- draw cursors
 if g_gamestate != gs_gameend
   then
  local cx = x + b.cursx * 8
  local cy = y + b.cursy * 8
  
  cx += b.cursbumpx
  cy += b.cursbumpy
  
  if b.cursstate == cs_swapping
    then
   local bk1, bk2 =
      board_getcursblocks(b)
    
   if bk1.btype > 0 then
    local idx = blocktileidxs[
      bk1.btype]
    
    spr(idx, cx + b.curscount * 2,
      cy)
   end
   
   if bk2.btype > 0 then
    local idx = blocktileidxs[
      bk2.btype]
      
    spr(idx, cx + 8
      - b.curscount * 2, cy)
   end
   
  end
  
  local off = 0
  if frame % 32 < 15 then
   off = 1
  end
  
  palt131()
  spr(16, cx - 4 - off,
    cy - 4 - off)
  spr(16, cx - 4 - off,
    cy + 3 + off, 1, 1,
      false, true)
  spr(16, cx + 12 + off,
    cy - 4 - off, 1, 1,
      true, false)
  spr(16, cx + 12 + off,
    cy + 3 + off, 1, 1,
      true, true)
  spr(32, cx + 4,
    cy - 4 - off, 1, 1)
  spr(32, cx + 4,
    cy + 3 + off, 1, 1,
      false, true)
 end
 
 board_drawpending(b)
 palt(13, false)
 
 if g_gamestate == gs_gamestart
   then
  
  local num =
    flr(g_gamecount/60)
  
  local w = 2
  local x = b.x + 16
  local y = b.y + 36
  
  if num == 2 then
   w = 1
   x += 6
  end
  
  palt131()
  spr(80 + num * 2, x, y,
    w, 2)
  palt(13, false)
  
 end
 
 
 if g_gamestate == gs_gameend
   then
  
  palt131()
  local y = b.y + 32
  local x = b.x + 10
  if b.lose then
   local s =
     sin(frame / 60) - 0.5
   x += s * 3
   spr(87, x, y, 1, 2)
   spr(86, x + 7, y, 1, 2)
   spr(85, x + 14, y, 1, 2)
   spr(89, x + 21, y, 1, 2)
   
  else
   local s =
     sin(frame / 30)
   y += s * 6
   x += 4
   spr(90, x, y, 2, 2)
   spr(92, x + 15, y, 1, 2)
   
  end
  palt(13, false)
  
  if g_gamecount >= 160 then
   local yy = 114 +
     (180 - g_gamecount)
   
   rect(31, yy - 1, 97, yy + 7,
    0)
   rectfill(32, yy, 96,
     yy + 6, 1)
   print("❎ to continue",
     34, yy + 1, 7)
   
  end
 end
 
 if not b.target then
  board_drawsolohud(b)
 end
 
end

function charidlefr(b)
 if b.shakevalues then
  return 3
 end
 if frame % 120 > 59 then
  
  if g_gamestate == gs_gameend
    then
    
   if b.lose then
    return 3
   end
   
   return 2
  elseif b.autoraisehold > 0 then
   return 2
  end
  
  return 1
 end
 return 0
end


function drawlabeledtext(
   x, y, label, value)
  local w = #label * 5
  local wf = w + 19
  rectfill(x, y,
    x + wf, y + 8, 1)

  print(label, x + 2, y + 2, 7)
  x += w - 2
  rectfill(x, y + 1,
    x + 20, y + 7, 13)

  print(value,
    x + 2, y + 2, 7)
end



function board_drawsolohud(b)
 local x = b.x + 60
 local y = b.y
 
 hiscore_draw(18, 0)
 
 drawlabeledtext(x, y,
   "score", b.score, 0)
 drawlabeledtext(x, y + 12,
   "speed",
     61 - b.autoraisespeed, 12)


 char_draw(g_chars[1],
   charidlefr(b), 68, 56)
 
 
 
end

function board_breakgarbage(
  b, x, y, basedur, chain,
    seqidxstartr)
 local bk =
   board_getrow(b, y)[x]
 
 if bk.state != bs_garbage then
  return 0
 end
 
 chain = max(bk.chain, chain)
 
 x -= bk.garbagex
 y += bk.garbagey
 
 bk = board_getrow(b, y)[x]
 
 if bk.state != bs_garbage then
  return 0
 end
 
 bk.state = bs_garbagematching
 
 local w = bk.garbagewidth
 local h = bk.garbageheight
 
 -- trim off top
 if y < h then
  local extrarows = h - y
  h -= extrarows
  --todo, prepend rest
 end
 
 local numblocks = w * h
 
 local hmax = 12
 local wmax = 6
 
 local dur = basedur + (
   numblocks * popoffset)
 local pad = basedur
 
 local maxdur = dur
 --local maxdurtmp = nil
 
 local matchrecs = {}
 
 local seqidx = seqidxstartr[1]
 seqidxstartr[1] += numblocks
 
 for i = 0, h - 1 do
  if y < 1 then
   break
  end
  local rx = x + (w - 1)
  
  local bk = board_getrow(
    b, y)[rx]
  
  
  local _check = function
    (xx, xo, yo)
   local bk2 =
     board_getrow(b, y + yo)[
       xx + xo]
   
   if bk2.state == bs_garbage
     and bk2.btype ==
       bk.btype then
    return max(
      board_breakgarbage(b,
        xx + xo, y + yo, dur,
          chain,
            seqidxstartr),
              maxdur)
   end
   
   return maxdur
  end
  
  
  -- check left
  if x > 1 then
   maxdur = _check(x, -1, 0)
  end
  
  
  -- check right
  if rx < wmax then
   maxdur = _check(rx, 1, 0)
  end
  
  for j = 0, w - 1 do
   
   bk = board_getrow(b, y)[rx]
   
   --check down
   if i == 0 and y < 12 then
    maxdur = _check(rx, 0, 1) 
   end
   
   --check up
   if y > 1 and i == h - 1 then
    maxdur = _check(rx, 0, -1)
   end
   
   
   local m = matchrec_new()
   m.x = rx
   m.y = y
   m.dur = dur
   m.chain = chain
   seqidx += 1
   m.seqidx = seqidx
   bk.count = 0
   bk.count2 = pad
   bk.btype = flr(rnd(
     b.blocktypecount)) + 1
   bk.state =
     bs_garbagematching
   rx -= 1
   pad += popoffset
   
   add(b.matchrecs, m)
   add(matchrecs, m)
  end
  
  y -= 1
 end
 
 if maxdur > dur then
  for mrec in all(matchrecs) do
   mrec.dur = maxdur
  end
 end
 
 return maxdur   
end

function _press(
  bidx, cidx, state)
 if cidx > 0 then
  bidx += 8
 end
 local i = shl(1, bidx)
 
 if band(i, state) > 0 then
  return true
 end
 
end

function press(bidx, cidx)
  return _press(
    bidx, cidx, cstate)
end

function newpress(bidx, cidx)
 if not press(bidx, cidx) then
  return
 end

 if _press(bidx, cidx,
   prevcstate) then
  return
 end
 
 return true
end

function maskpress(bidx, cidx)
 local v
 if cidx > 0 then
  v = shl(bidx, 8) + 255
 else
  v = shl(255, 8) + bidx
 end
 
 cstate = band(cstate, v)

end

function updategame()
 squashcount =
   (squashcount + 1) % 3
 
 if squashcount == 0 then
  squashframe =
    (squashframe + 1) % 6
 end
 
 if g_gamestate == gs_gamestart
   then
  
  if g_gamecount < 180 then
   if g_gamecount % 60 == 0 then
    sfx '5'
   end

   g_gamecount += 1
   
   if g_gamecount == 180 then
    g_gamestate = gs_gameplay
    sfx '6'
    music '0'
   end

   g_trans = flr((20 -
     g_gamecount) / 4)
  end
  
  return
 end
 
 foreach(boards, board_step)
 
 local newmatchbubs = {}
 for mb in all(matchbubs) do
  mb.count += 1
  
  if mb.count == 40 then
   if not mb.target then
    goto skip
   end
  
  elseif mb.count == 77 then
   
   local gt = mb.matchcount
   if gt < 10 then
    gt -= 1
   end
   
   gt *= mb.matchchain
   
   local sendfnc = 
     board_appendgarbage
     
   if mb.targetpos then
     sendfnc =
       board_addtoscore
   end
   
   if mb.matchcount == 0 then
    for i = 1, mb.matchchain do
     if mb.targetpos then
      sendfnc(
        mb.target, 9, 1)
     else
      sendfnc(
        mb.target, 6, 1).metal =
         true
     end
    end
    
   elseif gt <= 6 then
    sendfnc(
      mb.target, gt, 1)
   else
    local rem = gt % 6
    if rem == 0 or rem >= 3
      then
     
     sendfnc(
       mb.target, 6,
         flr(gt / 6))
     
     if rem > 0 then
      sendfnc(
        mb.target, rem, 1
          ).count = 0
     end
    else
     local dur = 60
     
     local trimtotal = gt - 3
     while trimtotal > 0 do
      if trimtotal < 6 then
       sendfnc(
        mb.target, trimtotal, 1
          ).count = dur
       break
      else
       sendfnc(
        mb.target, 6, 1
          ).count = dur
       
       trimtotal -= 6
      end
      dur = 0
     end
     
    end
   end
   
   goto skip
  elseif mb.count == 69 then
   if mb.target then
    
    if mb.targetpos then
     mb.dx = 
       (mb.targetpos[1] - 
         mb.x) / 8
     mb.dy = 
       (mb.targetpos[2] - 
         mb.y) / 8
    else
     mb.dx = (mb.target.x + 2 - 
       mb.x) / 8
     
     mb.dy = (mb.target.y - 16 - 
       mb.y) / 8  
    end
   end
  end
  
  if mb.dx then
   mb.x += mb.dx
   mb.y += mb.dy
  else
   
   mb.y = mb.y -
    bubdeltay[mb.count] / 2
   
   local div = 2
   if mb.x > 64 then
    div = -2
   end
   mb.x = mb.x +
     bubdeltax[mb.count] / div
   
  end
  
  add(newmatchbubs, mb)
  ::skip::
 end
 matchbubs = newmatchbubs
 
end



function matchbub_new(
  bubtype, value, x, y)
 return {
  bubtype = bubtype,
  value = value,
  x = x,
  y = y,
  count = 0
 }
end

function matchbub_draw(mb)
 if mb.count > 40 then
  if frame % 3 == 0 then
   pal(5, 7)
  end
  spr(61, mb.x, mb.y)
  pal(5, 5)
  return
 end
 
 palt131()
 palt00()
 local offset = 7
 local textoffset = 6
 local bgs = 64
 if mb.bubtype > 0 then
  pal(3, 8)
  if mb.bubtype == 2 then
   pal(3, 1)
   bgs = 67
  end
  
  offset = 8
  textoffset = 8
 end

 spr(bgs, mb.x, mb.y)
 spr(bgs, mb.x +
   offset, mb.y,
     1, 1, true, false)
 
 spr(bgs + 1, mb.x, mb.y + 8)
 spr(bgs + 1, mb.x + offset,
    mb.y + 8, 1, 1, true, false)
 
 if mb.bubtype > 0 then
  spr(66, mb.x + 4, mb.y + 6)
 end
 
 local v = mb.value
 if v > 9 then
  v = "+"
 elseif v == 0 then
  v = "!"
 end
 print(v,
   mb.x + textoffset,
     mb.y + 6, 0)
 
 print(v,
   mb.x + textoffset,
     mb.y + 5, 7)
 
 pal()
 palt()
end


function pendinggarbage_new(
  width, height, forcex)
 
 local pg = {
  count = 60,
  width = width,
  height = height,
  forcex = forcex
 }
 
 if height > 1 then
  pg.bub = matchbub_new(
    2, height, 0, 0)
 end
 
 return pg
end

function board_appendgarbage(b,
  width, height, forcex)
 
 local pg = pendinggarbage_new(
   width, height, f0rcex)
 add(b.pendinggarbage, pg)
 
 return pg 
end


function board_addtoscore(b,
  width, height)
 b.score += width * height

	local l = g_levels[1]
 hiscores[l] = max(
   hiscores[l],
     b.score)

 dset(l - 1, hiscores[l])

 return {}
end

function board_pendingstep(b)

 if b.pendingoffset > 0 then
  b.pendingoffset -= 1
 end
 
 
 while #b.pendinggarbage > 0 do
  local pg =
    b.pendinggarbage[1]
  
  if pg.count > 0 then
   pg.count -= 1
   return
  end 
  
  local row =
    board_getrow(b, 1)
  
  local dropx
  if b.forcex then
   for i = b.forcex,
     b.forcex + pg.width - 1 do
    
    if row[i].state != bs_idle
      or row[i].btype > 0 then
     return
    end  
    dropx = b.forcex
   end
  else
   local possiblespots = {}
   
   for i = 1, 7 - pg.width do
    
    for j = 1, pg.width do
     local bk = row[i + j - 1]
     
     if bk.state != bs_idle or
       bk.btype != 0 then
      goto cont 
     end
     
    end  
    
    add(possiblespots, i)
    
    ::cont::
   end
   
   if #possiblespots > 0 then
    dropx = possiblespots[
      flr(rnd(
        #possiblespots)) + 1]
   end
  end
  
  if not dropx then
   return
  end
  
  del(b.pendinggarbage, pg)
  
  board_addgarbage(b, dropx, 1,
    pg.width, pg.height)
  b.pendingoffset += 8
  
  if pg.metal then
   local row =
     board_getrow(b, 1)
   
   for i = 1, 6 do
    row[i].btype = 11
   end
  end
  
  
 end
 
end

function board_drawpending(b)
 local x = b.x
   + b.pendingoffset
 
 if b.idx > 1 then
  x += 10
 end

 local y = b.y - 11
 for i = 1, min(4,
   #b.pendinggarbage) do
  
  palt131()
  --palt00()
  
  local pg =
    b.pendinggarbage[i]
  
  if pg.bub then
   
   pg.bub.x = x - 1
   pg.bub.y = y - 5
   
   matchbub_draw(pg.bub)
   x += 11
   
   palt00()
  else
   
   spr(53 + pg.width, x, y)
   x += 9
  end
  
  
 end

end


function trans(s)
 if s<1 then
  return
 end
 s=2^s
 local b,m,o =
   0x6000,
   15,
   s/2-1+(32*s)

 for y=0,128-s,s do
  for x=0,128-s,s do
   local a=b+x/2
   local c=band(peek(a+o),m)
   c=bor(c,shl(c,4))
   for i=1,s do
    memset(a,c,s/2)
    a+=64
   end
  end
  b+=s*64
 end
end

__gfx__
0000000082222220505050508222222082828220888888200222222087777778e222222010000000e2222220e2eee220eeeeee2002222220e777777e00700000
000000002282822005050505222222202888882028888820222222227787877822eee22010000000222222202eeeee202eeeee202222222277eee77e00770000
00700700288888205050505022222220288888202288822022822822788888782eeeee2011000000222222202eeeee202eeeee2022e22e227eeeee7e00717000
00077000288888200505050528828820228882202228222022822822788888782eeeee20110000002eeeee202eeeee2022eee22022e22e227eeeee7e00711700
00077000228882205050505088888880222822202222222022222222778887782eeeee2001100000eeeeeee022eee22022222220222222227eeeee7e00717100
007007002228222005050505288888202222222022222220228888227778777822eee22000110000eeeeeee0222222202222222022eeee2277eee77e00771000
000000002222222050505050228882202222222022222220222222227777777822222220000111002eeeee202222222022222220222222227777777e00710000
0000000000000000050505050000000000000000000000000222222088888888000000000000000000000000000000000000000002222220eeeeeeee00100000
ddddddddc111111000000000c1111110c11c1110c1ccc11001111110c777777ca999999000000000a9999990aaaaaa90aaaaaa9009999990a777777adddddddd
dddddddd111c1110001110001111111011ccc1101ccccc1011111111777c777c9aaaaa9000000000999999909aaaaa9099aaa990999999997aaaaa7adddddddd
dd00000d11ccc11000001100111111101ccccc1011ccc11011c11c1177ccc77c9aaaaa90000000009999999099aaa99099aaa99099a99a997aaaaa7adddddddd
dd07770d1ccccc10000001101111111011ccc110111c111011c11c117ccccc7c99aaa990000000009999999099aaa990999a999099a99a9977aaa77ad17dd17d
dd07000d11ccc110000000111ccccc10111c1110111111101111111177ccc77c99aaa99000000000aaaaaaa0999a9990999999909999999977aaa77ad77dd77d
dd070ddd111c111000000011ccccccc0111111101111111011cccc11777c777c999a9990000000009aaaaa90999999909999999099aaaa99777a777adddddddd
dd000ddd11111110000000011ccccc101111111011111110111111117777777c999999900000000099aaa9909999999099999990999999997777777adddddddd
dddddddd000000000000000100000000000000000000000001111110cccccccc000000000000000000000000000000000000000009999990aaaaaaaadddddddd
ddddddddb333333000000001b3333330b33b3330b3bbb33003333330b777777b65555550000000006555555065565550655655500555555067777776dddddddd
dddddddd333b3330000000013333333033bbb33033bbb33033333333777b777b55565550000000005555555055565550555655505555555577767776dddddddd
d00000dd33bbb330000000013333333033bbb3303bbbbb3033b33b3377bbb77b55565550000000005555555055565550555555505565565577767776dddddddd
d07770dd33bbb33000000001333333303bbbbb303bbbbb3033b33b3377bbb77b55565550000000005566655055555550555655505565565577767776dddddddd
d00700dd3bbbbb30000000013bbbbb303bbbbb3033333330333333337bbbbb7b55555550000000005566655055565550555555505555555577777776d55dd55d
dd070ddd3bbbbb3000000001bbbbbbb0333333303333333033bbbb337bbbbb7b55565550000000005555555055555550555555505566665577767776dddddddd
dd000ddd3333333000000001bbbbbbb03333333033333330333333337777777b55555550000000005566655055555550555555505555555577777776dddddddd
dddddddd000000000000000100000000000000000000000003333330bbbbbbbb00000000000000000000000000000000000000000555555066666666dddddddd
cccccccc94444440cccccccc9444444099949940999999400444444097777779dddddddddddddddddddddddddddddddd0000000d005555005555555555555555
cccccccc49949940cccccccc4444444049999940449994404444444479979979dddddddddddddddddddddddddddddddd0101010d051111505000000557777775
ccc76ccc49999940cccccccc4444444044999440499999404494494479999979ddddddddd00000dd0000000d0000000d0000000d515555155050050557577575
cc7665cc44999440cccccccc9994999049999940499499404494494477999779ddddddddd01010dd0101010d0101010d5010105d515555155050050557577575
cc6655cc49999940cccccccc99999990499499404444444044444444799999790000000dd00000dd0000000d0000000d0000000d515555155000000557777775
ccc55ccc49949940cccccccc99999990444444404444444044999944799799790101010dd01010dd5010105d0101010d0101010d515555155055550557555575
cccccccc44444440cccccccc99949990444444404444444044444444777777790000000dd00000ddd00000dd0000000d0000000d051111505000000557777775
cccccccc00000000cccccccc00000000000000000000000004444440999999995555555dd55555ddd55555dd5555555d5555555d005555005555555555555555
dddddddddd7333337d7dddddddddddddd050000011111110222222207777700770077770077770000077777007777700007777700077770077000770cccccc11
dddddddddd733333070dddddddddddddd05000001ccccc102eeeee207777770770777770777777000077777707777700007777770777777077700770cccc1170
dddddddddd733333707ddddddd000000d05000001c111c10211111207700770770770000770077000077007707700000007700770770077077770770ccc17700
dddd7777dd0733330d0dddddd0555555d05555551cc1cc102e1e1e206666660660660000660066000066006606666000006666660660066066666660cc170000
ddd73333ddd07777ddddddddd0500000dd0000001cc1cc102e1e1e206666600660660000660066000066006606600000006666600660066066066660c1700000
dd733333dddd0000ddddddddd0500000dddddddd1c111c10211111206600000660666660666666000066666606666600006600000666666066006660c1700000
dd733333ddddddddddddddddd0500000dddddddd1ccccc102eeeee20660000066006666006666000006666600666660000660000006666006600066010000000
dd733333ddddddddddddddddd0500000dddddddd1111111022222220000000000000000000000000000000000000000000000000000000000000000010000000
dddddddddddddddddddddddddddddddddddddddddd00000ddd000ddd0000dddd0000000d0000000d0000d0000d0000dd00000ddd11cccccc0000000110000000
ddd00000000dddddddd00000000ddddd00000dddd077770dd07770dd0770dddd0770770d0777770d0770d0770d0770dd077770dd0011cccc0000000110000000
ddd077777770ddddddd077777770dddd07770ddd0777770d0777770d0770dddd0770770d0777770d0770d0770d0770dd0777770d00001ccc0000001cc1000000
ddd0777777770dddddd0777777770ddd07770ddd0770000d0770770d0770dddd0770770d0770000d0770d0770d0770dd0770770d000001cc0000001cc1000000
ddd0000000770dddddd0000000770ddd00770ddd0770555d0770770d0770dddd0770770d0770555d0770d0770d0770dd0770770d0000001c000001cccc100000
ddd5555550770dddddd5555550770ddd50770ddd07700ddd0770770d0770dddd0770770d077000dd0770d0770d0770dd0770770d0000001c00001cccccc10000
dddd000000770dddddddd00000770dddd0770ddd077770dd0770770d0770dddd0770770d077770dd0770d0770d0770dd0770770d000000010011cccccccc1100
dddd077777705ddddddd077777770dddd0770ddd5077770d0770770d0770dddd0770770d077770dd077000770d0770dd0770770d0000000111cccccccccccc11
dddd07777770ddddddd0777777705dddd0770dddd500770d0770770d0770dddd0770770d077000dd077070770d0770dd0770770d000000001111111100000000
dddd000000770dddddd077000005ddddd0770dddddd0770d0770770d0770dddd0770770d077055dd077070770d0770dd0770770d000000000000000000000000
dddd555550770dddddd07705555dddddd0770ddd0000770d0770770d0770000d0777770d0770000d077070770d0770dd0770770d000000000000000000000000
ddd0000000770dddddd0770000000ddd007700dd0777770d0777770d0777770d5077705d0777770d077777770d0770dd0770770d000000000000000000000000
ddd0777777770dddddd0777777770ddd077770dd0777705d5077705d0777770dd50705dd0777770d507707705d0770dd0770770d000000000000000000000000
ddd0777777705dddddd0777777770ddd077770dd000005ddd50005dd0000000ddd505ddd0000000dd5000005dd0000dd0000000d000000000000000000000000
ddd000000005ddddddd0000000000ddd000000dd55555ddddd555ddd555555ddddd5dddd5555555ddd55555ddd5555dd5555555d000000000000000000000000
ddd55555555dddddddd5555555555ddd555555dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd000000000000000011111111
00000000000000000000000000007070000000000000007000000000000000000000000000000000000000000000000000000000000000000000000100000000
000070000000000000000000000007070000000000070000000000000c000c000e000e000011110001101100010001000d000d00000111000000000100000000
70000000000077777000000000777000000070007777777007700000000000000000000000100000011111000100010000000000001177000000001100100000
70070000000000007000000000000000007700000007000000070070000c000c000e000e001100000101010001111100000d000d011700000000001100100000
77700077777000007007777707777700777000000707070000000700000000000000000000100000010001000100010000000000117000000000011000110000
700000000000000070000000000700000070000070070070000070000c000c000e000e000011110001000100010001000d000d00117000000000110000011000
70000000000077777000000000070000007000000007000000070000000000000000000000000000000000000000000000000000170000000011100000001111
07777000000000000000000000700000000000000070000007700000000c000c000e000e000000000000000000000000000d000d170000000000000000000011
cccccccccccccccc33333333333333330000000000000000222214412222222299999999999999992808220822082222eeeeeeeeeeeeeeee8888888888888888
cccccccccccccccc33333333300000330000000000000000222114411111122299999900099999992080822082088222eeeeeeeeeeeeeeee8842222288888888
ccccffccccccffcc33333330000000030007777777777000221499999999412299999012209999992208008908208822eeee222222222eee8844222228888888
ccccffccccccffcc333333300000000000077777777770002149999aaaa9941299900122440099992220990999990822eee22222222222ee8242249924888888
ccffffffffffffcc333333344444400000077677776770002199999aaaaa991299010124440409992829229f92229882ee222222222222ee842ffff992488888
ccffffffffffffcc33333336774444400007676776767000221dddddddaa99129990102440409999282900fff0009988ee22ff22222222ee84fffff112f88888
cc11ffffff11ffcc33333347074677440007777777777000221cccc777ca988199990100040009992820707f07070908ee21fff1222222ee84ffff1ff2988888
cc11ffffff11ffcc33222247744707440007777777777000221c1cc7c7ca988199908012410809992220077f00777f80ee21fff1f2f22eee8811fff1f4288888
cceeffffffffeecc32222044444777400007777777777000221c1cc7c7ca9881999080eef7000999220f77ff0777fe82eeeffffff2feeeee888f1ffff4288888
cceeffffffffeecc12442004224444400007776676777000221cccc777ca988199900200000f0099220efffffffff982eeeefffee2eeeeee8888ffff92288888
cccccc222222cccc11444000024444000007777777777000221ddddcccaa94129990f05670d0109920ffff4fffff9982eeeee888888eeeee8888ff4442211888
cccccc222222cccc111111000000000200077777777770002199999aaaaa99129990000000a7909920fffffffff99008eeeee8887788eeee8888844242111118
cccccc888888cccc111111111000002277600777777006772199194aaaaa99129999901240a79099220ff020ff900118eeeee2887788eeee8888884449111111
cccccc888888cccc1111111111244442777777777777777722111155555111229999900040dd10998220ffff900ccc11eeee222e222eeeee8888811299111111
ccccccffccffcccc31111111111444447777777777777777222221d5ddd512229999999900000099822200ff0cccc011eeeeeeeeeeeeeeee88881111f1111111
ccccccffccffcccc33331111111144417777777777777777222221d5dddd5122999999999999999928220100cc000111eeeeeeeeeeeeeeee8888111111111111
cccccccccccccccc33333333333333330000000000000000222214412222222299999999999999992808220822082222eeeeeeeeeeeeeeee8888888888888888
cccccccccccccccc33333333000003330000000067770000222114411111122299999900099999992080822082088222eeee222222222eee8888888888888888
cccccccccccccccc33333300000000330000677777770000221499999999412299999012209999992208008908208822eee22222222222ee8888442222288888
ccccffccccccffcc333333000000000300777777776760002149999aaaa9941299900122440099992220990999990822ee222222222222ee8888244222248888
ccccffccccccffcc333333444444000300777677767670002199999aaaaa9912990101244404099928299229f9222882ee22ff22222222ee888444ff49224888
ccffffffffffffcc33333367444444000077676777777000221dddddddaa991299901024404099992829f00fff009988ee21fff1222222ee88842ffff9924888
ccffffffffffffcc33333407746744400067777777777000221cccc777ca988199990100040009992820707ff7070908ee21fff1f2f22eee8888fffffff2f888
cc11ffffff11ffcc33222477740774400007777777777600221cccc777ca988199908012410809992220770f07707f80eeeffffff2feeeee888811ff11f29888
cc11ffffff11ffcc32220444447774000007777777677700221111ccccca9881999080eef7000099220977ff0777ff82eeeefffee2eeeeee88888f1ffff42888
cceeffffffffeecc12440042244444030006776676777700221cccc777ca98819999020000d01099220eeffffffffe82eeeee888888eeeee88888fffff942888
cceeffffffffeecc11440002244440020000777777777700221ddddcccaa94129990005670a79099209ffff4fffff982eeeee8887788eeee888888f444222188
cccccc222222cccc111110000000002200007777777700672199999aaaaa99129990f00000a79099209fffffffff9008eeee28887788eeee8888884424221111
ccccff888888cccc111111110000022200000077777777772199194aaaaa99129999001240dd10992209ff020ff00118eeee2288888eeeee8888812444911111
ccccff888888cccc111111111124444200677777777777772211115555511122999990120000009928209ffff0011cc1eeeee22ee22eeeee888811119f911111
ccccccccccffcccc31111111111444447777777777777777222221d5ddd5122299999000999999992822009f01cccc11eeeeeeeeeeeeeeee888811111f111111
ccccccccccffcccc33331111111144417777777777777777222221d5dddd51229999999999999999228201001cc00111eeeeeeeeeeeeeeee8888111111111111
ccccffccccccffcc33333333000003337000777007000070222221122222222299999999999999992808220822082222eeeeeeeeeeeeeeee8888888888888888
ccccffccccccffcc33333300000000330000070077700000222214412222222299990000099999992080822082088222eeeeeeeeeeeeeeee8888888244288888
ccffffffffffffcc33333300000000037707000007007077222114411111122299901244209999992208008908208822eee222222222eeee8888882242222888
cc111fffff111fcc33333344444400037700000000000077221499999999412299901244409999992220990999990822ee222222222222ee8888884242222288
cc1f1fffff1f1fcc333333000444440377077777777770772149999aaaa9941290011122222009992829229992299882ee222222222222ee8888884ffff42288
ccffffffffffffcc333334040400044376077777777770672199999aaaaa991290f00000000099992829ff99fff99988ee222222222222ee888888ffffff9248
cceffffffffffecc33443444440404437007767777677007221dddddddaa991290e0014410800999282f009ff0009908ee2222f2222222ee888888f1fff19498
cceeffffffffeecc33440442444444037007676776767007221cccc777ca988199050eeff00209992220ff0f0fff0980ee22ffffff2f2eee8888881f1f1f12f8
cccccc222222cccc32220042244444037007777777777007221d1dc6c6ca988199900e00f00f009922efffffffff9e82eee111f1112feeee888888ffffff9228
cccccc222222cccc122200002244400260077777777770062211c1cc7cca98819999000000d0109920fff4ffffff9982ee71f1f1f1877eee888888fffff99288
ccccff888888cccc11122000000000220007777777777000221cccc777ca98819999056770a7909920ff0fff00ff9982ee77ffffff877eee88f8889422494288
ccccff888888cccc11111122000444420007766666677007221ddddcccaa94129999000000a7909920ff00000ff99008eeeee888888eeeee88fff88422442888
ccccccccccccffcc111111112224444407077666666770702199999aaaaa99129990111240dd1099220ff000ff900118eeee88228888eeee88fff81444422888
ccccccccccccffcc111111111122444200077766667770002155194a555a991299900099000000998220ff0ff00ccc11eeee82222888eeee88ff911244211188
cccccccccccccccc3111111111122222776007777770067716761151676111229999999999999999822200ff0cccc011eeeeeeeeeeeeeeee8811111199111188
cccccccccccccccc33331111111122217777777777777777177711d177715122999999999999999928220100cc000111eeeeeeeeeeeeeeee88111111f1111118
cccccccccccccccc33333333033303330000000000066000222211222227222299999999999999991202110211021111eeeeeeeeeeeeeeee8888888888888888
cccccccccccccccc30330333033033330000006777066000272144122222222299999999999999991020211021022111eeeeeeeeeeeeeeee8888888888888888
cccccccccccccccc33033033333333300067777777066600221144111111227299999999999999991102002d02102211eeee2e222e2eeeee8888888888888888
cccccccccccccccc33303330000033037777777767606600214999999994122299990000000999991110dd0ddddd0211eee222222222eeee8842222228888888
cccccccccccccccc33333000000003337776777676706600149999aaaa9941229990201220409999121111ddd111d221ee222222222222ee8844222222888888
cccccccccccccccc30003000000000307767677767700000199999aaaaa9912299020122440409991210011d1100dd22ee22fff222222eee8242249922488888
ccccffccccccffcc33333444444000336776777777700660214444888aa991229902012444040999121dd0d600dddd02ee2fff1122f222ee8442ffff92288888
ccccffccccccffcc3322204044444033077777777776066021eeeefffea9881299902024404009991118888688888d20ee21ff11f2f22eee848ffff1f92f8888
ccffffffffffffcc32224404404044430777766666770000211eeeffeea9881299900200040000991108086608886d21eeeffffff22e2eee8881ff1119298888
ccffffffffffffcc1222404044044443067766666677000021e1eefefea98812990e002241d010991106666666666d21ee2ffff22effeeee88111ff1f9288888
cc1f1ffff1f1ffcc1440444440404023007766666777000021eeeefffea98812990f056770a79099106666566666dd21eef2888888ffeeee8881fffff4288888
ccf1ffffff1fffcc14400422444440220077777777006777218888eeeaa941229900000000a7909910666000066dd002eeee888888eeeeee8888f42242211888
cc1e1ffff1f1eecc11400002244400227600777777777777199999aaaaa991229999011240dd10991106611006d00552eee22888882eeeee8888824442111118
cceeffffffffeecc11110000000002227777777777777777199194aaaaa99122999900090000009921106666d0011155eeee22eee22eeeee8888884449111118
cccccc222222cccc31111110000044427777777777777777211115555551122299999999999999992111006601111055eeeeeeeeeeeeeeee8888811299111111
ccccccffccffcccc33331111111144417777777777777777222221d5dddd512299999999999999991211050011000555eeeeeeeeeeeeeeee88888111f1111111
__label__
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccc7c7ccccccccccccccc7ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccc7ccccccccccccccccccccccc0707ccccccccccc7cc0ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cc7ccc0ccccccc77777ccccccccc7770c0cccc7ccc7777777cc77cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc00000cccccccc
cc7cc7cccccccc00007ccccccccc000ccccc770ccc0007000cc007cc7cccccccccccccccccccccccccccccccccccccccccccccccccccccccccc08880cccccccc
cc7770cc77777ccccc7cc77777c77777cc7770ccccc7c7c7ccccc0c70cccccccccccccccccccccccccccccccccccccccccccccccccccccccccc08880cccccccc
cc700ccc00000ccccc7cc00000c00700cc007ccccc70c7c07ccccc70cccccccccccccccccccccccccccccccccccccccccccccccccccccccc00008880000ccccc
cc7ccccccccccc77777cccccccccc7cccccc7ccccc0cc7cc0cccc70ccccccccccccccccccccccccccccccccccccccccccccccccccccccccc0999777fff0ccccc
cc07777ccccccc00000ccccccccc70cccccc0ccccccc70ccccc770cccccccccccccccccccccccccccccccccccccccccccccccccccccccccc0999777fff0ccccc
ccc0000ccccccccccccccccccccc0ccccccccccccccc0cccccc00cccccccccccccccccccccccccccccccccccccccccccccccccccccccc0000999777fff0000cc
ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc0aaa777777777eee0cc
cc77777cc77cc7777cc7777ccccc77777cc77777cccc77777ccc7777cc77ccc77cccccccccccccccccccccccccccccccccccccccccccc0aaa777777777eee0cc
cc777777c77c77777c777777cccc777777c77777cccc777777c777777c777cc77cccccccccccccccccccccccccccccccccccccccccccc0aaa777777777eee0cc
cc770077c77c77000c770077cccc770077c77000cccc770077c770077c7777c77cccccccccccccccccccccccccccccccccccccccccccc0000bbb777ddd0000cc
cc666666c66c66cccc66cc66cccc66cc66c6666ccccc666666c66cc66c6666666ccccccccccccccccccccccccccccccccccccccccccccccc0bbb777ddd0ccccc
cc666660c66c66cccc66cc66cccc66cc66c6600ccccc666660c66cc66c6606666ccccccccccccccccccccccccccccccccccccccccccccccc0bbb777ddd0ccccc
cc66000cc66c66666c666666cccc666666c66666cccc66000cc666666c66c0666ccccccccccccccccccccccccccccccccccccccccccccccc0000ccc0000ccccc
cc66ccccc66c06666c066660cccc666660c66666cccc66ccccc066660c66cc066cccccccccccccccccccccccccccccccccccccccccccccccccc0ccc0cccccccc
cc00ccccc00cc0000cc0000ccccc00000cc00000cccc00cccccc0000cc00ccc00cccccccccccccccccccccccccccccccccccccccccccccccccc0ccc0cccccccc
ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc00000cccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
4944449a99999444449a9999944449403b33333bbbbbbbbbbbbbbbbb33333b30282222222222288888222222222228204944449a99999444449a999994444940
494444999999944444999999944449403b333333333333333333333333333b302822222222222288822222222222282049444499999994444499999994444940
494444444444444444444444444449403b333333333333333333333333333b302822222222222228222222222222282049444444444444444444444444444940
494444444444444444444444444449403b333333333333333333333333333b302822222222222222222222222222282049444444444444444444444444444940
494444444444444444444444444449403b333333333333333333333333333b302822222222222222222222222222282049444444444444444444444444444940
499444444444444444444444444499403bb3333333333333333333333333bb302882222222222222222222222222882049944444444444444444444444449940
4499999999999999999999999999944033bbbbbbbbbbbbbbbbbbbbbbbbbbb3302288888888888888888888888888822044999999999999999999999999999440
04444444444444444444444444444400033333333333333333333333333333000222222222222222222222222222220004444444444444444444444444444400
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
02222222222222222222222222222200011111111111111111111111111111000222222222222222222222222222220003333333333333333333333333333300
22666eeeeeeeeeeeeeeeeeeeeeeee22011666cccccccccccccccccccccccc11022eee88888888888888888888888822033666bbbbbbbbbbbbbbbbbbbbbbbb330
2662222222222222222222222222ee201661111111111111111111111111cc102ee222222222222222222222222288203663333333333333333333333333bb30
26222222222222222222222222222e2016111111111111111111111111111c102e22222222222222222222222222282036333333333333333333333333333b30
26222222222222222222222222222e2016111111111111111111111111111c102e22222222222222222222222222282036333333333333333333333333333b30
2e222222222222222222222222222e201c111111111111111111111111111c10282222222222222222222222222228203b333333333333333333333333333b30
2e222222222222222222222222222e201c111111111111111111111111111c10282222222888222222288822222228203b3333333333333b3333333333333b30
2e22222222222eeeee22222222222e201c1111111111111c1111111111111c10282222288888882228888888222228203b3333333333333b3333333333333b30
2e222222222ee666eeee222222222e201c111111111111c6c111111111111c10282222888eee888288888888822228203b333333333333b6b333333333333b30
2e22222222e66eeeeeeee22222222e201c11111111111c6ccc11111111111c1028222288ee88888888888888822228203b333333333333b6b333333333333b30
2e2222222e6eeeeeeeeeee2222222e201c1111111111c6ccccc1111111111c102822288ee888888888888888882228203b33333333333b6bbb33333333333b30
2e222222e6eeeeeeeeeeeee222222e201c111111111c6ccccccc111111111c102822288e8888888888888888882228203b33333333333b6bbb33333333333b30
2e222222e6eeeeeeeeeeeee222222e201c11111111c6ccccccccc11111111c102822288e8888888888888888882228203b3333333333b6bbbbb3333333333b30
2e22222e6eeeeeeeeeeeeeee22222e201c1111111c6ccccccccccc1111111c102822288e8888888888888888882228203b3333333333b6bbbbb3333333333b30
2e22222e6eeeeeeeeeeeeeee22222e201c111111c6ccccccccccccc111111c10282228888888888888888888882228203b333333333b6bbbbbbb333333333b30
2e22222eeeeeeeeeeeeeeeee22222e201c11111c6ccccccccccccccc11111c10282222888888888888888888822228203b333333333b6bbbbbbb333333333b30
2e22222eeeeeeeeeeeeeeeee22222e201c111111ccccccccccccccc111111c10282222888888888888888888822228203b33333333b6bbbbbbbbb33333333b30
2e22222eeeeeeeeeeeeeeeee22222e201c1111111ccccccccccccc1111111c10282222288888888888888888222228203b33333333b6bbbbbbbbb33333333b30
2e222222eeeeeeeeeeeeeee222222e201c11111111ccccccccccc11111111c10282222228888888888888882222228203b3333333b6bbbbbbbbbbb3333333b30
2e222222eeeeeeeeeeeeeee222222e201c111111111ccccccccc111111111c10282222222888888888888822222228203b3333333b6bbbbbbbbbbb3333333b30
2e2222222eeeeeeeeeeeee2222222e201c1111111111ccccccc1111111111c10282222222288888888888222222228203b333333b6bbbbbbbbbbbbb333333b30
2e22222222eeeeeeeeeee22222222e201c11111111111ccccc11111111111c10282222222228888888882222222228203b333333b6bbbbbbbbbbbbb333333b30
2e222222222eeeeeeeee222222222e201c111111111111ccc111111111111c10282222222222888888822222222228203b33333bbbbbbbbbbbbbbbbb33333b30
2e22222222222eeeee22222222222e201c1111111111111c1111111111111c10282222222222288888222222222228203b33333bbbbbbbbbbbbbbbbb33333b30
2e222222222222222222222222222e201c111111111111111111111111111c10282222222222228882222222222228203b333333333333333333333333333b30
2e222222222222222222222222222e201c111111111111111111111111111c10282222222222222822222222222228203b333333333333333333333333333b30
2e222222222222222222222222222e201c111111111111111111111111111c10282222222222222222222222222228203b333333333333333333333333333b30
2e222222222222222222222222222e201c111111111111111111111111111c10282222222222222222222222222228203b333333333333333333333333333b30
2ee2222222222222222222222222ee201cc1111111111111111111111111cc10288222222222222222222222222288203bb3333333333333333333333333bb30
22eeeeeeeeeeeeeeeeeeeeeeeeeee22011ccccccccccccccccccccccccccc1102288888888888888888888888888822033bbbbbbbbbbbbbbbbbbbbbbbbbbb330
02222222222222222222222222222200000000011111111111111111000000000000000222222222222222220000000003333333333333333333333333333300
00000000000000000000000000000000777777000000000000000000077777000777770000000000000000000777777000000000000000000000000000000000
01111111111111111111111111111107666666022222222222222222066666666666660111111111111111110666666702222222222222222222222222222200
11666cccccccccccccccccccccccc076666666088888888888888888066666666666660ccccccccccccccccc0666666670666eeeeeeeeeeeeeeeeeeeeeeee220
1661111111111111111111111111c07660000002222222222222222200000076600000011111111111111111000000667062222222222222222222222222ee20
16111111111111111111111111111076602222222222222222222222222220766011111111111111111111111111106670222222222222222222222222222e20
16111111111111111111111111111076602222222222222222222222222220766011111111111111111111111111106670222222222222222222222222222e20
1c111111111111111111111111111076602222222222222222222222222220766011111111111111111111111111106670222222222222222222222222222e20
1c111111111111111111111111111076602222222888222222288822222220766011111111111111111111111111106670222222222222222222222222222e20
1c1111111111111c111111111111100000222228888888222888888822222000001111111111111c11111111111110000022222222222eeeee22222222222e20
1c111111111111c6c111111111111c10282222888eee888288888888822228201c111111111111c6c111111111111c102e222222222ee666eeee222222222e20
1c11111111111c6ccc11111111111c1028222288ee88888888888888822228201c11111111111c6ccc11111111111c102e22222222e66eeeeeeee22222222e20
1c1111111111c6ccccc1111111111c102822288ee888888888888888882228201c1111111111c6ccccc1111111111c102e2222222e6eeeeeeeeeee2222222e20
1c111111111c6ccccccc111111111c102822288e8888888888888888882228201c111111111c6ccccccc111111111c102e222222e6eeeeeeeeeeeee222222e20
1c11111111c6ccccccccc11111111c102822288e8888888888888888882228201c11111111c6ccccccccc11111111c102e222222e6eeeeeeeeeeeee222222e20
1c1111111c6ccccccccccc1111111c102822288e8888888888888888882228201c1111111c6ccccccccccc1111111c102e22222e6eeeeeeeeeeeeeee22222e20
1c111111c6ccccccccccccc111111c10282228888888888888888888882228201c111111c6ccccccccccccc111111c102e22222e6eeeeeeeeeeeeeee22222e20
1c11111c6ccccccccccccccc11111c10282222888888888888888888822228201c11111c6ccccccccccccccc11111c102e22222eeeeeeeeeeeeeeeee22222e20
1c111111ccccccccccccccc111111c10282222888888888888888888822228201c111111ccccccccccccccc111111c102e22222eeeeeeeeeeeeeeeee22222e20
1c1111111ccccccccccccc1111111c10282222288888888888888888222228201c1111111ccccccccccccc1111111c102e22222eeeeeeeeeeeeeeeee22222e20
1c11111111ccccccccccc11111111c10282222228888888888888882222228201c11111111ccccccccccc11111111c102e222222eeeeeeeeeeeeeee222222e20
1c111111111ccccccccc111111111c10282222222888888888888822222228201c111111111ccccccccc111111111c102e222222eeeeeeeeeeeeeee222222e20
1c1111111111ccccccc1111111111c10282222222288888888888222222228201c1111111111ccccccc1111111111c102e2222222eeeeeeeeeeeee2222222e20
1c11111111111ccccc11111111111c10282222222228888888882222222228201c11111111111ccccc11111111111c102e22222222eeeeeeeeeee22222222e20
1c111111111111ccc111111111111c10282222222222888888822222222228201c111111111111ccc111111111111c102e222222222eeeeeeeee222222222e20
1c1111111111111c111111111111100000222222222228888822222222222000001111111111111c11111111111110000022222222222eeeee22222222222e20
1c111111111111111111111111111076602222222222228882222222222220766011111111111111111111111111106670222222222222222222222222222e20
1c111111111111111111111111111076602222222222222822222222222220766011111111111111111111111111106670222222222222222222222222222e20
1c111111111111111111111111111076602222222222222222222222222220766011111111111111111111111111106670222222222222222222222222222e20
1c111111111111111111111111111076602222222222222222222222222220766011111111111111111111111111106670222222222222222222222222222e20
1cc1111111111111111111111111c076600000022222222222222222000000766000000111111111111111110000006670e2222222222222222222222222ee20
11ccccccccccccccccccccccccccc076666666088888888888888888066666666666660ccccccccccccccccc0666666670eeeeeeeeeeeeeeeeeeeeeeeeeee220
01111111111111111111111111111107666666022222222222222222066666666666660111111111111111110666666702222222222222222222222222222200
00000000000000000000000000000000777777000000000000000000077777000777770000000000000000000777777000000000000000000000000000000000
01111111111111111111111111111100000000033333333333333333000000000000000444444444444444440000000002222222222222222222222222222200
11666cccccccccccccccccccccccc11033666bbbbbbbbbbbbbbbbbbbbbbbb33044aaa99999999999999999999999944022eee888888888888888888888888220
1661111111111111111111111111cc103663333333333333333333333333bb304aa444444444444444444444444499402ee22222222222222222222222228820
16111111111111111111111111111c1036333333333333333333333333333b304a4444444444444444444444444449402e222222222222222222222222222820
16111111111111111111111111111c1036333333333333333333333333333b304a4444444444444444444444444449402e222222222222222222222222222820
1c111111111111111111111111111c103b333333333333333333333333333b304944444444444444444444444444494028222222222222222222222222222820
1c111111111111111111111111111c103b3333333333333b3333333333333b304944449999999444449999999444494028222222288822222228882222222820
1c1111111111111c1111111111111c103b3333333333333b3333333333333b304944449aaaaa9444449aaaaa9444494028222228888888222888888822222820
1c111111111111c6c111111111111c103b333333333333b6b333333333333b304944449a999999999999999994444940282222888eee88828888888882222820
1c11111111111c6ccc11111111111c103b333333333333b6b333333333333b304944449a99999999999999999444494028222288ee8888888888888882222820
1c1111111111c6ccccc1111111111c103b33333333333b6bbb33333333333b304944449a9999999999999999944449402822288ee88888888888888888222820
1c111111111c6ccccccc111111111c103b33333333333b6bbb33333333333b304944449a9999999999999999944449402822288e888888888888888888222820
1c11111111c6ccccccccc11111111c103b3333333333b6bbbbb3333333333b30494444999999999999999999944449402822288e888888888888888888222820
1c1111111c6ccccccccccc1111111c103b3333333333b6bbbbb3333333333b30494444449a99999999999994444449402822288e888888888888888888222820
1c111111c6ccccccccccccc111111c103b333333333b6bbbbbbb333333333b30494444449a999999999999944444494028222888888888888888888888222820
1c11111c6ccccccccccccccc11111c103b333333333b6bbbbbbb333333333b30494444449a999999999999944444494028222288888888888888888882222820
1c111111ccccccccccccccc111111c103b33333333b6bbbbbbbbb33333333b30494444449a999999999999944444494028222288888888888888888882222820
1c1111111ccccccccccccc1111111c103b33333333b6bbbbbbbbb33333333b30494444449a999999999999944444494028222228888888888888888822222820
1c11111111ccccccccccc11111111c103b3333333b6bbbbbbbbbbb3333333b30494444999a999999999999999444494028222222888888888888888222222820
1c111111111ccccccccc111111111c103b3333333b6bbbbbbbbbbb3333333b304944449aaa9999999999999a9444494028222222288888888888882222222820
1c1111111111ccccccc1111111111c103b333333b6bbbbbbbbbbbbb333333b304944449a99999999999999999444494028222222228888888888822222222820
1c11111111111ccccc11111111111c103b333333b6bbbbbbbbbbbbb333333b304944449a999999aaa99999999444494028222222222888888888222222222820
1c111111111111ccc111111111111c103b33333bbbbbbbbbbbbbbbbb33333b304944449a99999999999999999444494028222222222288888882222222222820
1c1111111111111c1111111111111c103b33333bbbbbbbbbbbbbbbbb33333b304944449a99999444449a99999444494028222222222228888822222222222820
1c111111111111111111111111111c103b333333333333333333333333333b304944449999999444449999999444494028222222222222888222222222222820
1c111111111111111111111111111c103b333333333333333333333333333b304944444444444444444444444444494028222222222222282222222222222820
1c111111111111111111111111111c103b333333333333333333333333333b304944444444444444444444444444494028222222222222222222222222222820
1c111111111111111111111111111c103b333333333333333333333333333b304944444444444444444444444444494028222222222222222222222222222820
1cc1111111111111111111111111cc103bb3333333333333333333333333bb304994444444444444444444444444994028822222222222222222222222228820
11ccccccccccccccccccccccccccc11033bbbbbbbbbbbbbbbbbbbbbbbbbbb3304499999999999999999999999999944022888888888888888888888888888220
01111111111111111111111111111100033333333333333333333333333333000444444444444444444444444444440002222222222222222222222222222200
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000

__map__
777778787c7c324f6e5d3232324f6e5d324f5d32320000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
777778787c7c4f6d6d7e6e5d4f096d224f6d7e6e5d0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
777778787c7c5f7d6d6d7f5e5f6f6f5e5f6f6f6f5e0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
777778787c7c325f6f6f5e324f6e6e6e5d4f6e5d000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
777778787c7c0202020202025f6f6f6f5e5f6f5e000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
777778787c7c0118081121010108183111080131082100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
777778787c7c3121011808112118011801311101210800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
777778787c7c0831110101113121211101312131013100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
777778787c7c2108182131110801083118011818212100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
777778787c7c1801113108011131210108111108180100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
777778787c7c0821311121211801180821180108112100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
777778787c7c1811212101111808213111180821311800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
777778787c7c0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
777778787c7c0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
777778787c7c0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
777778787c7c0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
777778787c7c0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
0101000018320213502334026330330003300033000330003300033000330003300033000330003300033000330000c0000c0000c0000c0000c0000c0000c0000c00000000000000000000000000000000000000
010400003c61524000240002400024000240002400024000240002400024000240002400024000240002400024000240002400024000240002400024000240002400024000240002400024000240002400024000
010500031041013310182100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010100002931000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
01060000163301b3302033022330273302c3302b3302b3222b3120000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010500001d43000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010200002943129431294312943129431294312943129431294312942129421294112941329000290002900029000290002900029000000000000000000000000000000000000000000000000000000000000000
000700000262105631086410865107641056310462103611026010060500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0107000018850198501a8501b8501c8501d8501e8501f850208502185022850238502485025850268502785028850298502a8502b8502c8502d8502e8502f8503085031850328503385034850358503685037850
0101000024630216201f610216301e620186000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010700000f03305000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
011a00001f0301f0221f01222030230312b0322903026030270302702227012260302703027022220302202024030240222401224012000002ca502ca312ca1124025000002702500000260252ea502ea312ea11
011a00001f0301f0221f01222030230312b03229030260302703027022270122603027030270222b0302b02024030240222401224012000002ca502ca312ca1127025000002b02500000290252ea502ea312ea11
011a00000f125031251895005125071250a12518950071250c1250a125189500712500100001251895003125081250000518950071250812500005189500000508125071251895005125051000a125189500e125
011a0000270302702227012290302a0302903027030290302503025022250122aa502aa312aa111e0301e02220030200222001222030230302a030290312703025030250222501225012250122aa502aa312aa11
011a0000270302702227012290302a03029030270302903025030250222a0302a0222f03031021310122f0302e0302e0222e0122e0122e0122a03025030260302e0302e0222e0122e0122e0122ea502ea312ea11
011a00000f125031251895005125071250a12518950071250c1250a1251895007125001000012518950031250812500005189500712508125000051895000005081250712518950051250510002125189500a125
011a00000b1250000018950061250312507100189500b1250a12506125189500112500100061001895000100081250b10018950031250b12508100189500a1250612508125189500a12505100011001895005100
011a00000b1250000018950061250312507100189500b1250a125011251895006125001000610018950081250a1250a125189500a1250a1251612518950021250a1250212518950051250a12502100189500c100
01140000270402703227022290402a0402904027040290402504025032220402704027032270222701200000330372e0272c01727037330272e0172c03727027340372f0272d01728037340272f0172d03728027
01140000270402703227022290402a0402904027040290402504025032220402e0402e0322e0222e0122e000270372c0272e01733037270272c0172e03733027280372d0272f01734037280272d0172f03734027
01140000031550a15509155031552b6230a1550915503155061550815501155031552b6230a1550000006155031550a15509155031552b6230a1550915503155041550b1550a155041552b6230b1550a15501155
011a00001a5161b5161f516225161a5261d5261f526235261a5361b5361f53624536185261a5261d526225261351614516185161b5161351614516185161b51614526185261b52620526185261a5261d52622526
011a0000195361b5361e53623536195261b5261e5262352616516195161d5161e51616526195261d5261e526175161b5161d5161e516175261b5261d5261e52616536195361d5361e53616526195261d5261e526
011a000016516175161b5161e51616526175261b5261e52616536195361d5361e53616526195261d5261e52614516165161a5161d51614526165261a5261d5261a5361d53620536225361a5261d5262052622526
01140000270450000000000290452b0452204500000240450000000000000000000000000000000000000000260450000000000270452604522045000001f0450000000000000000000000000000000000000000
01140000270450000000000290452b0452204500000240450000027045000002e04500000000002c045000002b04500000000002c0452b0452904500000270450000000000000000000000000000000000000000
0114000003145000000c1450a1450f1450c1450a145081450000013145000001414214122131450f1450c1450a14500000051450a1450e1450a1450514503145000000a1450c1450a1450f1450c1450a14507145
0114000003145000000c1450a1450f1450c1450a14508145000000f145000001314014141141200c1400c1200a145000000a1450814505145021450000003145000000f1450c1450a14508145071450514502145
01140000030000000027a7027a403c9202e80030800338002ca002ca002ca702ca403c92000000000000000000000000002ea702ea403c9202b8002e8003380027a0027a0027a7027a403c920000000000000000
01140000030000000027a7027a403c9202e80030800338002ca002ca002ca702ca403c92000000000000000000000000002ea702ea403c9202b8002e8003380027a0027a0027a0027a003c920000000000000000
011a00001f0301f0221f0122b030290302e0302b03026030270312702227012270122701227a5027a3027a102002500000000002c0252c0252e0252b0252702529025000000000000000000002ea502ea302ea10
011a00001f0301f0221f0122b03029030270302603027030240302402224012240122401227a5027a3027a102002500000000002c0252c0252b025290252702524025000000000000000000002ea502ea302ea10
__music__
00 50124344
00 50124344
01 10124344
00 11154344
00 13164344
00 14174344
00 25124344
00 24124344
00 1b124344
00 1b154344
00 1c164344
02 1d174344
00 41424344
00 41424344
00 41424344
01 181a4344
02 191a4344
00 41424344
00 41424344
00 41424344
01 1e202244
02 1f212344

