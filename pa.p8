pico-8 cartridge // http://www.pico-8.com
version 8
__lua__
function _init()
 -- globals struct

 g_tick = 0
 g_cs = {}   --camera stack
 g_ct = 0    --controllers
 g_ctl = 0   --last controllers
 g_lv = {0,0} --p1/p2 game level

 --previously per-board
 --global for tokens savings
 g_h = 12    --board height
 g_w = 6     --board width
 g_hp = g_h*9 --height/pixels
 g_wp = g_w*9 --width/pixels

 --general objects
 g_go = {
  make_trans(
   function()
    addggo(make_title())
   end
  )
 }

 --disable sound
 --memset(0x3200,0,0x4300-0x3200)
end

function _update()
 -- naturally g_tick wraps to
 -- neg int max instead of 0
 g_tick = max(0,g_tick+1)

 -- current/last controller
 g_ctl = g_ct
 g_ct = btn()
 -- top-level objects
 update_gobjs(g_go)
end

function _draw()
 cls()
 rectfill(0,0,127,127,5)
 draw_gobjs(g_go)
 --print('cpu:'..
 --  (flr(stat(1)*100))..'%',100,0,
 --   7)
end
--
function make_row(
  w, -- row width
  e, -- row is empty or not
  nt,-- number of tile types
  ra,-- row above (check match)
  raa)--row above row above
 
 local r = {}
 for j = 1, w do
  r[j] = {}
  local n=0
  if not e then
   n = flr(rnd(nt) + 1)
   local tries=0
   while (j > 2 and (n == r[j-1].t 
     and n == r[j-2].t)
     or (ra 
         and raa 
         and
         (raa[j].t == n 
         and ra[j].t == n)))
         and 
      tries < nt do
    n += 1
    tries += 1
    if n > nt then
     n = 1
    end
   end
  end
  r[j].t = n
 end
 return r
end

function make_board(
  x, -- x position
  y, -- y position
  p, -- player
  v, -- number of visible lines
  nt)-- number of tile types
 local b = {
  draw=draw_board,
  update=update_board,
  start=function(b)
   b.st = 3 -- countdown to start
   add(b.go,make_cnt(b))
   --b.ri = nil
   --if b.ob then
   b.mtlidx=1
   b.mtlcnt=0
   --end
  end
  ,
  nt=nt, --tile types
  t={}, -- a list of rows
  -- cursor position (0 indexed)
  cx=2, --flr(w/2)-1
  cy=8, --h-4
  x=x,
  y=y,
  noshake_x=x,
  noshake_y=y,
  p=p, -- player (input)
  o=4,     -- rise offset
  r=0.025, -- rise rate
  mc=0, --match count
  f={},  -- tiles to fall
  go={}, -- general objects
  gq={}, -- queued garbage
  st=0,  -- board state
  lc=0,  -- lines cleared
  dropcount=0, --weight of
              --garbage dropped
              --this cycle
  shake_start=g_tick,
  shake_time=5,
  shake_amount=10,
 }

 for i = g_h,1,-1 do
  local e,r2,r3 = g_h-i > v,
    b.t[i+1],
    b.t[i+2]
    b.t[i] = make_row(
      g_w,e,b.nt,r2,r3)
 end  
 
 -- additional fields
 --b.s = nil -- tiles to swap
 --b.ri = nil  -- time since rise
 -- board state enum
 --     0 -- playing
 --     1 -- lose
 --     2 -- win
 --     3 -- countdown to start
 
 
 return b
end

--function start_board(b)
-- b.st = 3 -- countdown to start
-- add(b.go,make_cnt(b))
-- b.ri = nil
-- --if b.ob then
--  b.mtlidx=1
--  b.mtlcnt=0
-- --end
--end

function input_cursor(b)
 local m,p =
   false,
   b.p
 if btnp(0, p) then
  if b.cx > 0 then
   b.cx -= 1
   m = true
  end
 end
 if btnp(1, p) then
  if b.cx < g_w - 2 then
   b.cx += 1
   m = true
  end
 end
 if btnp(2, p) then
  if b.cy > 0 then
   b.cy -= 1
   m = true
  end
 end
 if btnp(3, p) then
  if b.cy < g_h - 2 then
   b.cy += 1
   m = true
  end
 end
 if m then
  sfx(0)
 end
end

function input_board(b)
 input_cursor(b)
 if btnn(5,b.p) and b.st==0 then
  local x,y =
   b.cx+1,
   b.cy+1
  local t1,t2 =
   b.t[y][x],
   b.t[y][x+1]

  if not busy(t1, t2) and
    (t1.t>0 or t2.t>0) then
   t1.s = g_tick
   t1.ss = 1
   t2.s = g_tick
   t2.ss = -1
   b.s = {t1, t2}
   sfx(1)
  end
 end
end

function end_game(b, single_player)
 for t in all(b.s or {}) do
  t.s=nil
  t.ss=nil
 end
 if b.st==1 then
  b.et=g_tick
  sfx(6)
 else
  g_wins[b.p+1]+=1
 end
 b.s=nil
 b.tophold=nil
 b.hd=nil
 local np=1
 make_shake(b, 10, 20)
 if b.ob then 
  np=2
 end

 local score = nil
 if single_player then
  score = b.sb.s
 end

 addggo(make_retry(np))
  --(g_wp)/2-16,(g_hp)/2-16))
  --hard-wire for tokens
 add(b.go, make_winlose(b.st==2, 11, 38, score))
end

function offset_board(b)
 if b.st ~= 0 then return end
 --pause while matching
 if b.mc>0 then
  if b.tophold then
   b.tophold+=1
  end
  if b.hd then
   b.hd+=1
  end
 end

 if b.hd then
  if b.hd > 0 then
   b.hd-=1
   if b.tophold then
    b.tophold=g_tick
   end
  else
   b.hd=nil
   --for no speed-up during
   --hold
   --b.ri=g_tick
  end
 end

 if not b.ri then
  b.ri=g_tick
 end
 if b.st == 0 and elapsed(b.ri) > 30 then
  b.ri=g_tick
  b.r+=0.001
 end

 if btn(4,b.p) then
  b.o+=1
 elseif not b.hd
   and b.mc==0 then
  b.o+=b.r
 end

 if b.o >= 9 then
  local r = b.t[1]
  for i=1,#r do
   -- lose condition
   if r[i].t > 0 then
    if b.tophold then
     b.o=9
     if elapsed(b.tophold) > 60 then
      b.st=1
      if b.ob then
       b.ob.st=2
       end_game(b)
       end_game(b.ob)
      else
       end_game(b, true)
      end
     end
    else
     b.tophold=g_tick
    end
    return
   end
  end

  b.tophold=nil

  b.o=0
  del(b.t, b.t[1])
  add(b.t, make_row(g_w,false,
    b.nt))
  b.lc+=1
  --if b.mtlidx then
   b.mtlcnt+=1
   if b.mtlcnt >=
     g_nxtmtl[b.mtlidx] then
    b.mtlidx+=1
    if b.mtlidx > #g_nxtmtl
      then
     b.mtlidx=1
    end
    b.mtlcnt=0
    b.t[g_h][
      flr(rnd(g_w))+1].t=7
   end
  --end
  if b.cy>0 then
   b.cy-=1
  end
  sfx(3)
 end
end

function update_board(b)
 if b.st==0 then
  local gb=b.gq[1]
  if gb and
    elapsed(gb[3])>40 then
   local x=garb_fits(b,gb[1],
     gb[2])
   if x then
    add_garb(b,x,0,gb[1],gb[2],
      gb[4])
    del(b.gq,gb)
   end
  end
  offset_board(b)
 end
 if b.st==0 or b.st==3 then
  input_board(b)
 end
 if b.st==0 then
  scan_board(b)
 end
 
 apply_shake(b, 9)
 update_gobjs(b.go)
end

function garb_fits(b,w,h)
 local sx=flr(rnd(g_w-w+0.99))
 for x=sx+1,sx+w do
  for y=1,h do
   local t=b.t[y][x]
   if busy(t) or t.t>0 then
    return nil
   end
  end
 end
 return sx
end


function busy(...)
 for t in all({...}) do
  if t.m or t.s or t.f or t.g
    then
   return true
  end
 end
 return false
end

function swapt(t,t2)
 local tmp = {}
 for k,v in pairs(t) do
  tmp[k] = v
  t[k] = nil
 end
 for k,v in pairs(t2) do
  t[k] = v
  t2[k] = nil
 end
 for k,v in pairs(tmp) do
  t2[k] = v
 end
end

function update_swap(b)
 if (not b.s) return
 local t,t2 = b.s[1],b.s[2]
 if elapsed(t.s) > 1 then
  t.s = nil
  t.ss = nil
  t2.s = nil
  t2.ss = nil
  b.s = nil
  swapt(t, t2)
 end
end

function set_falling(b, t, t2)
 t.s = g_tick
 t.f = true
 t2.f= true
      
 add(b.f, {t,t2})
end

function update_fall(b)
 for x=1,g_w do
  for y=g_h-1,1,-1 do
   local t=b.t[y][x] 
   
   if (t.g 
       and t.g[1] ==0 
       and t.g[2] ==0) then
    if (not t.f and 
       not t.s and 
       not t.m) then
     update_fall_gb(b,x,y)
    end
   elseif y<g_h and t.t>0 then
    local t2=b.t[y+1][x]
    if t2.t==0 and
     not busy(t,t2) then
      -- mark for falling
      set_falling(b, t, t2)
       
      -- blocks above fall too
      fall_above(x,y,t,b)
    end
   end
  end
 end
 
 --if (not b.f) return
 
 for f_s in all(b.f) do
  local t,t2 = f_s[1],f_s[2]
  --xxx: can't find what's
  --causing non-falling entries
  --in b.f, for now, ignore
  --and remove
  if not t.s then
   del(b.f,f_s)
   --cls()
   --print(t.f)
   --print(t.g)
   --print(t.gm)
   --stop()
  elseif (elapsed(t.s) > 0) then
   -- execute the fall
   t.s = nil
   t.ss = nil
   t2.s = nil
   t2.ss = nil
   t.f = false
   t2.f = false
   swapt(t, t2)
   del(b.f, f_s)
  end
 end
end

function update_fall_gb(b,x,y)
 local t = b.t[y][x]
 --xxx t.g should always be set
 --    working around for now
 if t.gm or not t.g then
  return
 end
 local should_fall = true
 local lastgx=t.g[3]+x-1
 local lastgy=t.g[4]+y-1
 local have_cleared=false
 for xg=x,lastgx do
  local t2 = b.t[lastgy+1][xg]
  if t2.t~=0 and not t2.f then
   should_fall = false
   break
  end
 end
 if should_fall then
  for xg=x,lastgx do
   for yg=lastgy,y,-1 do
    local tg1=b.t[yg][xg]
    local tg2=b.t[yg+1][xg]
    set_falling(b, tg1, tg2)
    if yg==y then
     fall_above(xg,y,tg1,b)
    end
   end
  end
 else
  
  -- first garbage hit
  if t.firsthit then
   t.firsthit = nil
   --sfx(8)
   --todo, weight by width
   b.dropcount = b.dropcount+1
  end
  
 end
end

function fall_above(x,y,t,b)
 for a=y-1,1,-1 do
  local a_t = b.t[a][x]
  if a_t.g and not a_t.f then
   update_fall_gb(
    b,
    x-a_t.g[1],
    a-a_t.g[2])
   break
  end
  if busy(a_t) then
   break
  end
  set_falling(b, a_t, t)
  t = a_t
 end
end
function above_solid(b,x,y)
 --brute force test prevent
 --mid-fall matches.
 --todo:optimize
 for i=y+1,g_h-1 do
  if b.t[i][x].t==0 then
   return false
  end
 end
 return true
end

function clr_match(b,x,y)
 local t=b.t[y][x]
 t.m=nil
 t.t=0
 t.e=nil
 --update chain count above
 local ch=t.ch
 if not ch then
  ch=2
 else
  t.ch=nil
  ch+=1
 end
 for i=y-1,1,-1 do
  local t2=b.t[i][x]
  if t2.t>0 and
    not busy(t2) then
   if t2.ch then
    t2.ch=max(ch,t2.ch)
   else
    t2.ch=ch
   end
  end
 end
 b.mc-=1
end

function reset_chain(b)
 for x=1,g_w do
  local tt = b.t[g_h-1][x]
  if not busy(tt) then
   tt.ch=nil
  end
  for y=g_h-2,1,-1 do
   local t=b.t[y][x]
   if not busy(t) and t.ch then
    if (tt.t>0 and
      not busy(tt)) and
      not tt.ch
      then
     t.ch=nil
    end
   end
   tt=t
  end
 end
end

function match_garb(b,x,y,ch,gbt)
 local t=b.t[y][x]
 if not t.g or t.gm then
  return
 end
 --metal vs regular
 if gbt and t.g[5] ~= gbt then
  return
 end
 gbt=t.g[5]
 x-=t.g[1]
 y-=t.g[2]
 local xe=x+t.g[3]-1
 local ye=y+t.g[4]-1
 local w=t.g[3]
 for yy=y,ye do
  local r=make_row(
    w,false,b.nt)
  for xx=x,xe do
   t=b.t[yy][xx]
   --charge preservation
   t.ch=max(ch,t.ch or 1)
   t.t=r[xx-x+1].t
   t.gm=g_tick
   --match top and bottom
   if yy==y and yy>1 then
    match_garb(b,xx,yy-1,ch,gbt)
   end
   if yy==ye and yy<g_h-1 then
    match_garb(b,xx,yy+1,ch,gbt)
   end
   --
  end
 end
end

function scan_board(b)
 local ms = {}

 update_fall(b)
 update_swap(b)

 -- act upon the accumulated
 -- first drop of the garbage
 if b.dropcount == 1 then
  b.dropcount = 0
  -- make_shake(b, 5, 8)
 end

 for h = 1, g_h do
  local r = b.t[h]
  for w = 1,g_w do
   local t = r[w]

   if t.m then
    if elapsed(t.m) > 30 then
     clr_match(b,w,h)
    end
   end

   if t.gm and
     elapsed(t.gm)>60 then
    t.gm=nil
    t.g=nil
   end
   if t.t > 0 and
     not busy(t) and
     above_solid(b,w,h) then
    if w < g_w-1 then
     local wc = 1
     for i=(w+1),g_w do
      if t.t == r[i].t and
        not busy(r[i]) and
        above_solid(b,i,h) then
       wc+=1
      else
       break
      end
     end
     if wc > 2 then
      for i=w,w+(wc-1) do
       add(ms,{r[i],i,h})
      end
     end 
    end

    if h < g_h-2 then
     local hc = 1
     for i=(h+1),g_h-1 do
      if t.t == b.t[i][w].t and
        not busy(b.t[i][w]) then
       hc+=1
      else
       break
      end
     end
     if hc > 2 then
      for i=h,h+(hc-1) do
       add(ms,{b.t[i][w],w,i})
      end
     end

    end
   end
  end
 end

 --collase to unique matches
 local mc=0
 local mtlc=0 --mtl count
 local um={}
 local ch=1
 local mm={g_w,0,g_h,0}
 for m in all(ms) do
  local t=m[1]
  local x=m[2]
  local y=m[3]
  mm[1]=min(x,mm[1])
  mm[2]=max(x,mm[2])
  mm[3]=min(y,mm[3])
  mm[4]=max(y,mm[4])
  if not um[t] then
   um[t]={x,y}
   t.m=g_tick
   if t.t==7 then
    mtlc+=1
   else
    mc+=1
   end
   t.e=30-((mc*3)%15)
   if t.ch then
    ch=max(ch,t.ch)
   end
  end
 end
 local mx=mm[1]+(mm[2]-mm[1])/2
 local my=mm[3]+(mm[4]-mm[3])/2-1
 b.mc+=mc+mtlc
 if mc>0 then
  sfx(2)
 end
 
 --check for adjacent garbage
 for t,xy in pairs(um) do
  local x,y,chp =
    xy[1],
    xy[2],
    ch+1
  if x>1 then
   match_garb(b,x-1,y,chp)
  end
  if x<g_w-1 then
   match_garb(b,x+1,y,chp)
  end
  if y>1 then
   match_garb(b,x,y-1,chp)
  end
  if y<g_h-1 then
   match_garb(b,x,y+1,chp)
  end
 end

 if ch>1 then
  addggo(make_bubble(
    max(0,b.x+(mx-1)*9-17),
    b.y+my*9,ch..'x',true))
  incr_hold(b,ch*10)	--tune
 end

 if mc>3 then
  incr_hold(b,mc*12) --todo tune
  addggo(make_bubble(
    min(112,b.x+mx*9),
      b.y+my*9-5,mc,false))
 end

 --target board, could be score
 local tb = b.ob or b.sb
 if mtlc>2 then
  incr_hold(b,mtlc*12) --todo tune
  send_garb(
    b.x+mx*9,
    b.y+my*9,
    tb,
    {1,(mtlc-2)*6+1,g_tick,1},
    g_tick)
 end

 if tb and
   (ch>1 or mc>3) then
  send_garb(
    b.x+mx*9,
    b.y+my*9,
    tb,
    {ch,mc,g_tick,0},
    g_tick)
  make_shake(b, 5, 5)
  sfx(10)
 end

 reset_chain(b)
end

function garb_size(gb)
 local r={}
 local sum=(gb[2]-1)*gb[1]
 local left=sum%6
 if sum-left>0 then
  add(r,{6,flr(sum/6),gb[3],gb[4]})
 end
 if left>2 then
  add(r,{left,1,gb[3],gb[4]})
 end
 return r
end

function send_garb(sx,sy,b,gb,e)
 addggo({
  sx=sx,sy=sy,b=b,gb=gb,e=e,
  update=function(t,s)
   if elapsed(t.e)>15 then
    for gb in all(
      garb_size(t.gb)) do
     add(t.b.gq,gb)
    end
    del(s,t)
   end
  end,
  draw=function(t)
   local v=elapsed(t.e)/15
   local v2=v^3
   palt(2,true)
   palt(0,false)
   spr(42,
     (b.x+5-t.sx)*v+t.sx-3,
     (b.y-10-t.sy)*v2+t.sy-3)
   palt()
  end
 })
end

function incr_hold(b,v)
 b.hd=(b.hd or 0)+v
end

function calc_offset(b)
 local offset=b.o
 if b.et then
  local e=elapsed(b.et)
  if e<10 then
   offset+=sin(e/5)*3*((9-e)/9)
  else
   b.et=nil
  end
 end
 return offset
end

function draw_board(b)
 rectfill(-1,-9,g_wp-2,g_hp,0)
 color(1)
 line(-1,-9,-1,g_hp)
 line(g_wp-1,-9,g_wp-1,g_hp)
 line(-1,-10,g_wp-1,-10)
 if b.hd then
  local btm=g_hp-7
  line(-1,btm,-1,
    max(-10,btm-b.hd),12)
 end
 color()

 local offset = calc_offset(b)
 pushc(0,offset)

 for h = 1, g_h do
  local r = b.t[h]
  for w = 1, g_w do
   local s = r[w].t
   local warn = (
       b.t[1][w].t > 0 and g_tick%16>7)
   if r[w].s then
    if not r[w].f then
     pushc(
      -r[w].ss*(elapsed(r[w].s)+1)
      ,0
     )
    else
     pushc( 
      0,
      -1*(elapsed(r[w].s)+1)
     ) 
    end
   end
   
   local t=r[w]
   if t.g then
    if t.gm then
     local i=t.g[2]*t.g[3]+t.g[1]
     local s=24
     local mt=(i+1)*3
     local ge=elapsed(t.gm)
     if ge==50-mt or
       ge==40-mt then
      sfx(7)
     end

     if ge>40-mt then
      s=t.t
      if ge<50-mt then
       s+=16
      end
     end

     spr(s,(w-1)*9,(h-1)*9)
    elseif t.g[1]==0 and
      t.g[2]==0 then
     local warn=false
     if b.st==0 and
       g_tick%16>7 then
      for i=w,w+t.g[3]-1 do
       if b.t[1][i].t>0 then
        warn=true
        break
       end
      end
     end
     if b.st==1 or b.st==2 then
      pal(13,6)
     end
     draw_garb((w-1)*9,
      (h-1)*9, t.g[3],t.g[4],
       warn,t.g[5])
     pal()
    end
   elseif s > 0 then
    if b.st<1 or b.st>2 then
     if r[w].m then
      local e=elapsed(r[w].m)
      if e%3 == 0 then
       s+=16
      end
      if e>15 then
       s=8
       if e>t.e then
        if e==t.e+1 then
         sfx(7)
        end
        s=0
       end
      end
     else
      if warn then
       s+=32
      end
     end
    else
     s+=16
    end
    spr(s,(w-1)*9,(h-1)*9)
    --if g_dbg and t.ch then
    -- print(t.ch,
    --  (w-1)*9+2,(h-1)*9+1,7)
    --end
   end

   if r[w].s then
    popc()
   end
   
  end
 end

 pal(1,0)
 local by = g_hp-9+offset
 local sx,sy = toscn(0,by)
 clip(sx, sy-offset,g_wp, 17)
 for y=0,1 do
  for x=1,g_w do
   --+(g_tick%3)*16
   spr(16+(y*16),(x-1)*9,by-(y*8))
  end
 end
 clip()
 pal()

 if b.st<1 or b.st>2 then
  draw_curs(b.cx*9,b.cy*9,
    --6 tkns, no grow as swap
    --b.s==nil and
    g_tick%30 < 15)
 end
 
 draw_gobjs(b.go)
 
 popc()

 palt(2,true)
 palt(0,false)
 if b.tophold then
  spr(
   49+elapsed(b.tophold)/60*8,
    g_wp-7,-18)
 end
 if #b.gq > 0 then
  spr(26,6,-18,2,1)
  spr(10,20,-18)
  print(#b.gq,24,-17,6)
 end
 palt()

 --token-permitting, level
 spr(g_lv[b.p+1]+88,-1,-18)

 --bottom cover
 --rectfill(-1,g_hp-9-1,
 --  g_wp-1,g_hp-1,1)
 ----tokens-permitting
 --palt(0,false)
 --palt(1,true)
 --clip(b.x,0,g_wp-1,128)
 --local y=g_hp-9
 --for i=0,g_w do
 -- spr(11,i*8,y,1,1,b.p==1)
 --end
 --clip()
 --palt()

end

function draw_curs(x, y, grow)
 local s=12
 if grow then
  s=13
 end
 spr(s,x-1,y-1)
 spr(s,x+10,y-1,1,1,true)
 spr(s,x-1,y+1,1,1,
   false,true)
 spr(s,x+10,y+1,1,1,
   true,true)
 s+=2
 spr(s,x+6,y-1)
 spr(s,x+6,y+1,1,1,
   false,true)
end

function add_garb(b,x,y,w,h,mtl)
 for by=y+1,min(g_h,y+h) do
  for bx=x+1,min(g_w,x+w) do
   local t=b.t[by][bx]
   t.g={bx-x-1,by-y-1,w,h,mtl}
   t.t=8
   t.firsthit=1
  end
 end
end

function draw_garb(x,y,w,h,warn,
		mtl)
 if mtl==1 then
  pal(13,5)
  pal(5,13)
 end
 rectfill(x,y,x+w*9-2,
    y+h*9-2,13)
 rect(x,y,x+w*9-2,y+h*9-2,5)
 local s=8
 if warn then s+=32 end
 spr(s,x+(w*9)/2-4-((w+1)%2),
   y+((h-1)*9)/2)
	pal()
end

function make_winlose(
  wl, --true win
  x,
  y,
  score
 )
 local r={
  x=x,
  y=y,
  s=68,
  e=g_tick,
  score=score,
  draw=function(t)
   local y=sin(g_tick/35)*3
   local e=elapsed(t.e)
   if e<10 then
    y=(10-e)*-4
   end
   if t.score then
    local n = t.score
    local digit = 10000
    local offset=0
    local ndigits = #(""..n)
    local origin=-6*ndigits
    if n < 10 then
     origin = 0
    end

    current_frame = flr(14*(elapsed(t.e) % 20)/20) + 1

    palt(15, true)
    palt(0, false)

    for i=1,4 do
     if current_frame == i then
      pal(i, 9)
     else
      pal(i, 2)
     end
    end
    for i=5,8 do
     pal(i, 6)
     if current_frame and i >= current_frame and current_frame > 5 then
      pal(i, 10)
     else
     end
    end
    pal(14, 6)

    local y = -24+8*sin((elapsed(t.e+10*offset) % 60)/60)

    if (0 == n) then 
     sspr(0, 96, 8, 8, origin, y, 32, 32)
    else
     while digit > n*10  do
      digit = flr(digit / 10)
     end
     digit = flr(digit / 10)
     repeat
      y = -24+8*sin((elapsed(t.e+10*offset) % 60)/60)
      sspr(
       (flr(n/digit) % 10)*8,
       96,
       8,
       8,
       origin + offset*24,
       y,
       32,
       32
      )
      digit = flr(digit/10)
      offset += 1
     until (digit == 0)
    end

    palt(15, false)
    palt(0, true)

   for i=0,16 do
    pal(i, i)
   end
   else
    spr(t.s,0,y,4,2)
   end
  end
 }
 if wl then 
  r.s=64
 end
 return r
end

function make_cnt(b)
 if b.p==0 then
  addggo(make_clock(b))
  if not b.ob then
   local gs=make_garbscore(b)
   addggo(gs)
   b.sb=gs
   -- addggo(make_linecount(b))
   addggo(make_1playgarb(b))
  end
 else
  addggo(make_vsscore())
 end
 return {
  x=g_wp/2-8,
  y=g_hp/2-8,
  c=3,
  e=g_tick,
  b=b, --potential cycle
  draw=function(t)
   pal(6,0)
   spr(96+(3-t.c)*2,0,0,2,2)
   pal()
  end,
  update=function(t,s)
   if elapsed(t.e)>30 then
    t.c-=1
    if t.c==0 then
     t.b.st=0
     del(s,t)
     sfx(5)
    else
     sfx(4)
     t.e=g_tick
    end
   end
  end
 }
end

function make_vsscore()
 return {
  draw=function()
   for i=0,1 do
    pushc(-111*i,0)
    rectfill(1,1,15,7,6)
    spr(72+i,1,1)
    local v = g_wins[i+1]
    local pad=' '
    if (v>9) pad=''
    print(pad..v,8,2,0)
    popc()
   end
  end
 }
end


function make_shake(t, amount, time)
 t.shake_start=g_tick
 t.shake_amount=amount
 t.shake_time = time
end

function apply_shake(b, with_sfx)
 b.x = b.noshake_x
 b.y = b.noshake_y
 if b.shake_start != nil then
  if elapsed(b.shake_start) > b.shake_time then
   b.shake_start = nil
  else
   b.x += rnd(b.shake_amount) - b.shake_amount / 2
   b.y += rnd(b.shake_amount) - b.shake_amount / 2
   if with_sfx then
    sfx(with_sfx)
   end
  end
 end
end

function make_garbscore(b)
 return {
  x=68,y=0,s=0,sp=74,ra=1,
  noshake_x=68,
  noshake_y=0,
  bling_time=g_tick,
  gq={},
  b=b,
  draw=function(t)
   local w=4*(#(''..t.s))
   rectfill(1,1,8+w,7,6)

   spr(t.sp,1,1)

   local digit = 10000
   local n = t.s
   local offset=6

   -- 6 frames of "bling" play out over a second
   local current_frame = nil
   if t.shake_start ~= nil then
    current_frame = flr((elapsed(t.shake_start) % 20)/20*9) + 1
   end

   palt(15, true)
   palt(0, false)

   for i=1,4 do
    if current_frame == i then
     pal(i, 9)
    else
     pal(i, 7)
    end
   end
   for i=5,8 do
    pal(i, 6)
    if current_frame and i >= current_frame and current_frame > 5 then
     pal(i, 10)
    else
    end
   end
   pal(14, 6)

   if (0 == n) then 
    spr(192, offset, 1)
   else
    while digit > n*10  do
     digit = flr(digit / 10)
    end
    digit = flr(digit / 10)
    repeat
     spr(192 + (flr(n/digit) % 10), offset, 1)
     digit = flr(digit/10)
     offset += 6
    until (digit == 0)
   end

   palt(15, false)
   palt(0, true)

   for i=0,16 do
    pal(i, i)
   end

  end,
  update=function(t)
   local amount = 0
   for gb in all(t.gq) do
    t.s+=gb[1]*gb[2]
    del(t.gq,gb)
    amount += min(gb[1], 5)
   end
   if amount > 0 then
    make_shake(t, amount, 4*amount)
    -- make_extra_parts(t, amount)
   end
   apply_shake(t)
  end
 }
end

-- function make_extra_parts(src, num)
--  for i=1, num do
--   addggo(
--   -- src.b.go,
--   {
--    x=src.x,
--    y=src.y,
--    b=src.b,
--    start=g_tick,
--    v={x=rnd(0.5)-0.25,y=-rnd(1)},
--    update=function(t)
--     t.x -= t.v.x
--     t.y -= t.v.y
--     t.v.y -= 0.1
--     if elapsed(t.start) > 60 then
--      del(t.b.go, t)
--     end
--    end,
--    draw=function(t)
--    palt(15, true)
--    palt(0, false)
--
--    for i=1,4 do
--     if current_frame == i then
--      pal(i, 9)
--     else
--      pal(i, 7)
--     end
--    end
--    for i=5,8 do
--     pal(i, 6)
--     if current_frame and i >= current_frame and current_frame > 5 then
--      pal(i, 10)
--     else
--     end
--    end
--    pal(14, 6)
--     spr(202, 0, 0)
--     spr(192+num, 6, 0)
--    palt(15, false)
--    palt(0, true)
--
--    for i=0,16 do
--     pal(i, i)
--    end
--
--    end
--   }
--  )
--  end
-- end

function make_linecount(b)
 local r=make_garbscore()
 r.ra=nil --right align
 r.sp=75 --sprite
 --r.b=b --lexical scoping to b
 r.x=0
 r.update=function(t)
  t.s=b.lc--t.b.lc
 end
 return r
end

function make_1playgarb(b)
 return {
  --b=b,
  update=function(t)
   if (b.st~=0) return
   --every two seconds
   if g_tick%60>=59 then
    --increased odds by level
    if rnd(100)>85-(g_lv[1]*12)
      then
     add(b.gq,{3,1,g_tick})
    end
   end
  end
 }
end

--todo, trim palette stuff
--      to a sprite for tokens
function make_bubble(
  x,y,n,f)
 return {
  x=x,y=y,n=n..'',
  b=g_tick,f=f,
  draw=function(t)
   local sx=1
   if #t.n>1 then
    sx-=1
   end
   spr(102,0,0,2,2,t.f)
   print(t.n,5+sx,3,6)
  end,
  update=function(t,s)
   if elapsed(t.b) > 60 then
    del(s,t)
   end
   t.y-=1
  end
 }
end

function make_clock(b)
 return {
  x=47,y=2,c=0,b=b,m=0,s=0,
  draw=function(t)
   rectfill(-1,-1,19,5,6)
   local mp,sp = '',''
   if (t.m<10) mp=0
   if (t.s<10) sp=0
   print(mp..t.m..':'..sp..t.s,
     0,0,0)
  end,
  update=function(t)
   if (t.b.st~=0) return
   t.c+=1
   --fixed-point math not
   --accurate enough for
   --division of seconds.
   --do addition instead
   if t.c>=30 then
    t.c=0
    t.s+=1
    if t.s>=60 then
     t.s=0
     t.m+=1
    end
   end
  end
 }
end

function update_title(t,s)
 if rnd(100)>92 then
  add(t.ts,{
   x=flr(rnd(128)),
   y=144,
   r=flr(rnd(2))+1,
   sx=8*(flr(rnd(5))+1),
   update=function(t,s)
    t.y-=t.r
    if t.y<-16 then
     del(s,t)
    end
   end,
   draw=function(t)
    rect(-17,-17,16,16,0)
    sspr(t.sx,0,8,8,-16,-16,32,32)
   end
  })
 end
 update_gobjs(t.ts)
 update_gobjs(t.mn)
end

function make_title()
 g_wins={0,0}
 return {
  ts={},
  np=2, --num players
  draw=function(t)
   draw_gobjs(t.ts)
   pal(2,0)
   spr(128,33,36,9,4)
   pal()
   draw_gobjs(t.mn)
  end,
  update=update_title,
  mn={make_main()}
 }
end

function add_bg(b,bx,cx)
 addggo({
  draw=function()
   map(cx,0,bx,((b.o)%8)-8,8,17)
  end
 })
end

function make_menu(
 lbs, --menu lables
 fnc, --chosen callback
 x,y, --pos
 omb, --omit backdrop
 p,   --player
 cfnc --cancel callback
)
 local m={
  --lbs=lbs,
  --f=fnc,
  --fc=cfnc,
  i=0, --item
  s=g_tick,
  e=5,
  x=x or 64,
  y=y or 80,
  h=10*#lbs+4,
  --omb=omb,
  tw=0,--text width
  p=p or -1,
  draw=function(t)
   local e=elapsed(t.s)
   local w=t.tw*4+10
   local x=min(1,e/t.e)*(w+9)/2
   if not omb then
    rectfill(-x,0,x,t.h,0)
    rect(-x,0,x,t.h,1)
   end
   if e<t.e then
    return
   end
   x=w/2+1
   for i,l in pairs(lbs) do
    if not t.off or i==t.i+1 then
     local y=4+(i-1)*10
     print(l,-x+9,y+1,0)
     print(l,-x+9,y,7)
    end
   end
   spr(48,-x,3+10*t.i)
  end,
  update=function(t,s)
   if (t.off) return
   if elapsed(t.s)<(t.e*2) then
    return
   end

   if btnn(5,t.p) then
    if fnc then
     fnc(t,t.i,s)
     sfx(2)
    end
   end

   --cancel
   if btnn(4,t.p) then
    if cfnc then
     cfnc(t,s)
     sfx(2)
    end
   end

   if btnn(2,t.p) and
     t.i>0 then
    t.i-=1
    sfx(1)
   end
   if btnn(3,t.p) and
     t.i<(#lbs-1) then
    t.i+=1
    sfx(1)
   end
  end
 }
 for l in all(lbs) do
  m.tw=max(m.tw,#l)
 end
 return m
end

function make_retry(np)
 return make_timer(30,
  function(t,s)
   local m = make_menu(
    {'retry','quit'},
    function(t,i,s)
     if i==0 then
      addggo(make_trans(
       function(t,s)
        start_game(t.d)
       end,
       t.np))
     else
      addggo(make_trans(
       function()
        g_go={
         make_title()}
       end))
     end
    end
   )
   m.np=t.d
   add(s,m)
  end,
  np) --added to timer as d
end

function make_lmenu(p,pm)
 local m=make_menu(
  {'easy',
   'normal',
   'hard',
   'expert'},
  function(t,i,s)
   t.off=true
   g_lv[p+1]=i
   t.pm:accept(t,s)
  end,
  64,70,nil,p,
  function(t,s)
   t.pm:cancel(t,s)
  end
 )
 m.i=g_lv[p+1]
 m.p=p
 m.pm=pm
 return m
end

function make_lmenuc(pm,np,s)
 local c={
  np=np,
  pm=pm,
  ac=0, --num accepted
  mns={},
  accept=function(t,mn,s)
   t.ac+=1
   if t.ac==t.np then
    t:_done()
    addggo(make_trans(
     function(t,s)
     	start_game(t.d)
     end,t.np))
   end
  end,
  cancel=function(t,mn,s)
   t.pm.off=nil
   t:_done(s)
  end,
  _done=function(t,s)
   for mn in all(t.mns) do
    del(s,mn)
   end
   del(s,t)
  end
 }
 for i=1,np do
  local mn=make_lmenu(i-1,c)
  if np==2 then
   mn.x+=(i*2-3)*39.5
  end
  add(c.mns,mn)
  add(s,mn)
 end
 add(s,c)
end

function make_main()
 return make_menu(
  {'1 player','2 player',
   'exit'},
  function(t,i,s)
   if i == 2 then
    load('git/menu')
    run()
    return
   end
   t.off=true
   make_lmenuc(t,i+1,s)
  end,
  62,76,true
 )
end

-- function make_stats(b,x,y)
-- return {
--  b=b,
--  x=x,
--  y=y,
--  draw=function(t)
--   if t.b.ri then
--    print('r: '.. t.b.r, 0, 12, 8)
--    print('ri: '.. t.b.ri, 0, 18, 8)
--   end
--   -- print('speed '..
--   --  (t.b.r-0.025)/0.01+1,0,12,6)
--   -- if b.hd then
--   --  print('hold '..b.hd,0,18,6)
--   -- end
--   -- print('mc '..b.mc,0,24,6)
--  end
-- }
-- end

-- difficulty math
-- we want the game to end after about 3 minutes
-- and for it to be worth it (if you can) to play on higher difficulty
-- working backwards should give us where it should end at 0.4

function get_lv(l)
 l=g_lv[l]
 local r={}
 if l>2 then
  r.nt=6
 else
  r.nt=5
 end

 --                    easy   normal hard   expert
 local difficulties = {0.015, 0.025, 0.050, 0.095} 
 r.r = difficulties[l+1]
 return r
end

function start_game(np)
 g_go={}
 local bs={}
 local lv={get_lv(1),get_lv(2)}
 if np==2 then
  for i=1,2 do
   bs[i] = make_board(
     5,30,i-1,5,lv[i].nt)
   bs[i].r=lv[i].r
  end
  bs[2].x=70
  bs[1].ob=bs[2]
  bs[2].ob=bs[1]

  --sync initial tiles
  if bs[1].nt == bs[2].nt then
   for y=1,g_h do
    for x=1,g_w do
     bs[2].t[y][x].t=
       bs[1].t[y][x].t
    end
   end
  end

  add_bg(bs[1],0,8)
  add_bg(bs[2],63,16)

 else
  add(bs,
   make_board(38,30,0,6,
     lv[1].nt))
  -- addggo(make_stats(bs[1],2,2))
  bs[1].r=lv[1].r

  add_bg(bs[1],0)
  add_bg(bs[1],64)

  -- uncomment to test garbage
  --bs[1].ob=bs[1]
 end

 for b in all(bs) do
  addggo(b)
  b:start()
 end
 g_nxtmtl={}
 for i=1,100 do
  add(g_nxtmtl,flr(rnd(4)))
 end
end

--
function update_gobjs(s)
 for o in all(s) do
  if o.update then
   o:update(s)
  end
 end
end

function draw_gobjs(s)
 for o in all(s) do
  if o.draw then
   pushc(-(o.x or 0),
     -(o.y or 0))
   o:draw(s)
   popc()
  end
 end
end

function elapsed(t)
 if g_tick>=t then
  return g_tick - t
 end
 return 32767-t+g_tick
end

function pushc(x, y)
 local l=g_cs[#g_cs] or {0,0}
 local n={l[1]+x,l[2]+y}
 add(g_cs, n)
 camera(n[1], n[2])
end

function popc()
 local len = #g_cs
 g_cs[len] = nil
 len -= 1
 if len > 0 then
  local xy=g_cs[len]
  camera(xy[1],xy[2])
 else
  camera()
 end
end

function toscn(x,y)
 --if #g_cs==0 then
 -- return x,y
 --end
 local c=g_cs[#g_cs]
 return x-c[1],y-c[2]
end

function make_timer(e,f,d)
 return {
  --e=e,f=f,  --closure
  d=d,  --data for callback
  s=g_tick,
  update=function(t,s)
   if elapsed(t.s) > e then
    del(s,t)
    f(t,s)
   end
  end
 }
end

--returns state,changed
function btns(i,p)
 i=shl(1,i)
 if p==1 then
  i=shl(i,8)
 end
 local c,cng =
   band(i,g_ct),
   band(i,g_ctl)
 return c>0,c~=cng
end

--returns new press only
function btnn(i,p)
 if p==-1 then --either
  return btnn(i,0) or btnn(i,1)
 end
 local pr,chg=btns(i,p)
 return pr and chg
end

function addggo(t)
 add(g_go,t)
end

function trans(s)
 if (s<1) return
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

function make_trans(f,d,i)
 return {
  d=d,
  e=g_tick,
  f=f,
  i=i,
  update=function(t,s)
   if elapsed(t.e)>10 then
    if (t.f) t:f(s)
    del(s,t)
    if not t.i then
     addggo(
       make_trans(nil,nil,1))
    end
   end
  end,
  draw=function(t)
   local x=flr(elapsed(t.e)/2)
   if t.i then
    x=5-x
   end
   trans(x)
  end
 }
end

__gfx__
0000000088888888ccccccccbbbbbbbbeeeeeeee9999999922222222d555555d00000000dddddddd222222220011001100000000777000000000000077777000
00000000888ee888ccccccccb333333beeeffeee999ff99922e22e22555665550dddddd05d5d5d5d222222220110011007700000700000000777000000700000
00000000888ee888cc6666ccb3bbbb3beeffffee99f99f992ee22ee2555665550d5dd5d0dddddddd626222221100110007000000700000000070000000700000
000000008eeeeee8cc6666ccb3bbbb3beffffffe9f9999f922222222555665550d5dd5d05d5d5d5d262222221001100100000000000000000000000000000000
000000008eeeeee8cc6666ccb3bbbb3beffffffe9f9999f922222222555665550dddddd0dddddddd626222220011001100000000000000000000000000000000
00000000888ee888cc6666ccb3bbbb3beeffffee99f99f992ee22ee2555555550d5555d05d5d5d5d222222220110011000000000000000000000000000000000
00000000888ee888ccccccccb333333beeeffeee999ff99922e22e22555665550dddddd0dddddddd222222221100110000000000000000000000000000000000
0000000088888888ccccccccbbbbbbbbeeeeeeee9999999922222222d555555d000000005d5d5d5d222222221001100100000000000000000000000000000000
01101101666666666666666666666666666666666666666666666666666666665555555500000000000000000000022200000000000000000000000000000000
11111111666776666666666667777776666776666667766666766766666776665dddddd5000000000ddddddddddd02220d000d000e000e000c000c0000000000
10110110666776666677776667666676667777666676676667766776666776665d5dd5d5000000000dddd5d5dddd022200000000000000000000000000000000
11111111677777766677776667666676677777766766667666666666666776665d5dd5d5000000000ddddddddddd0222000d000d000e000e000c000c00000000
01101101677777766677776667666676677777766766667666666666666776665dddddd5000000000dddd555dddd022200000000000000000000000000000000
11111111666776666677776667666676667777666676676667766776666666665d5555d5000000000ddddddddddd02220d000d000e000e000c000c0000000000
10110110666776666666666667777776666776666667766666766766666776665dddddd500000000000000000000022200000000000000000000000000000000
111111116666666666666666666666666666666666666666666666666666666655555555000000002222222222222222000d000d000e000e000c000c00000000
0000000088888888ccccccccbbbbbbbbeeeeeeee9999999922222222d555555d00000000000000000000000200000000dd00000dd00000dd0000000000000000
1010101088888888ccccccccbbbbbbbbeeeeeeee9999999922222222555555550dddddd0000000000ddddd0200000000d00000dddd00000d0000000000000000
0111010188eeee88cccccccc33333333effffffe9ffffff9eee22eee556666550dddddd0000000000d5d5d020000000000000dddddd000000000000000000000
11011011eeeeeeeec666666c3bbbbbb3fffffffff999999f2222222255666655055dd550000000000ddddd02000000000000ddd00ddd00000000000000000000
01101101eeeeeeeec666666c3bbbbbb3fffffffff999999f22222222555555550dddddd0000000000d555d0200000000000ddd0000ddd0000000000000000000
1111111188eeee88cccccccc33333333effffffe9ffffff9eee22eee5566665505555550000000000ddddd020000000000ddd000000ddd000000000000000000
1011011088888888ccccccccbbbbbbbbeeeeeeee9999999922222222555555550dddddd00000000000000002000000000ddd00000000ddd00000000000000000
1111111188888888ccccccccbbbbbbbbeeeeeeee9999999922222222d555555d00000000000000002222222200000000ddd0000000000ddd0000000000000000
00660000222222222222222222222222222222222222222222222222222222222222222222222222000000000000000000000000000000000000000000000000
006d6000211111122111111221111112211111122111111221111112211111122111111221111112000000000000000000000000000000000000000000000000
006dd600210000122100dd122100dd122100dd122100dd122100dd122100dd122100dd1221dddd12000000000000000000000000000000000000000000000000
006ddd60210000122100d0122100dd122100dd122100dd122100dd122100dd1221d0dd1221dddd12000000000000000000000000000000000000000000000000
006dd65021000012210000122100001221000d122100dd122100dd1221dddd1221dddd1221dddd12000000000000000000000000000000000000000000000000
006d6500210000122100001221000012210000122100dd12210ddd1221dddd1221dddd1221dddd12000000000000000000000000000000000000000000000000
00665000211111122111111221111112211111122111111221111112211111122111111221111112000000000000000000000000000000000000000000000000
00550000222222222222222222222222222222222222222222222222222222222222222222222222000000000000000000000000000000000000000000000000
00ffff0000ffff00000000000ffff0000ffff0000000000000000000000ffff00000000000000000000000000000000000000000000000000000000000000000
00f33f0000f33f00000000000f33f0000f88f0000000000000000000000f88f0088888000ccccc000ddddd00088e880000000000000000000000000000000000
00f33f0000f33ffff00000000f33f0000f88f0000000000000000000000f88f0088788000c7c7c000d5d5d0008eee80000000000000000000000000000000000
00f33f0000f33f33f00000000f33f0000f88f0000000000000000000000f88f0088788000c7c7c000ddddd000e8e8e0000000000000000000000000000000000
00f33ffffff33f33f00000000f33f0000f88f0000000000000000000000f88f0088788000c7c7c000d555d00088e880000000000000000000000000000000000
00f33ff33ff33ffffff0fff00f33f0000f88f0000ffff000fffff0ffff0f88f0088888000ccccc000ddddd00088e880000000000000000000000000000000000
00f33ff33ff33f33f33f333f0f33f0000f88f000f8888fff8888ff8888ff88f00000000000000000000000000000000000000000000000000000000000000000
00f33ff33ff33f33f3333333ff33f0000f88f00f888888f88888f888888f88f00000000000000000000000000000000000000000000000000000000000000000
00f33ff33ff33f33f333ff33ff33f0000f88f00f88ff88f88ffff88ff88f88f01111100011111000111110001111100000000000000000000000000000000000
00f33ff33ff33f33f33f5f33ff33f0000f88f00f88ff88f88888f888888f88f01777100017711000171710001717100000000000000000000000000000000000
00f33ff33ff33f33f33f0f33ff33f0000f88f00f88ff88f88888f888888f88f01711100017171000171710001717100000000000000000000000000000000000
00f3333333333f33f33f0f33fffff0000f88ffff88ff88ffff88f88ffffffff01777100017171000177710001171100000000000000000000000000000000000
00f3333ff3333f33f33f0f33ff33f0000f88888f888888f88888f888888f88f01711100017171000171710001717100000000000000000000000000000000000
005f333ff333ff33f33f0f33ff33f0000f88888ff8888ff8888fff8888ff88f01777100017171000171710001717100000000000000000000000000000000000
0005fff55fff5fffffff0ffffffff0000ffffffffffff5fffff555ffff5ffff01111100011111000111110001111100000000000000000000000000000000000
00005550055505555555055555555000055555555555505555500055550555500000000000000000000000000000000000000000000000000000000000000000
00066666666600000006666666666000000006666660000000000000000000003777777333777733377777733777777337777773377777733777777337777773
00067777777600000006777777776000000006777760000000666666666666003766667333766733376666733766667337677673376666733766667337666673
000677777776000000067777777760000000067777600000006dddddddddd6003767767333776733377776733777767337677673376777733767777337777673
000666666776000000066666667760000000066677600000006dddddddddd6003767767333076733376666733076667337666673376666733766667330007673
00055555677600000005555556776000000005567760000006ddddddddddd6003767767333376733376777733777767337777673377776733767767333337673
0000066667760000000666666677600000000006776000006dddddddddddd6003766667333376733376666733766667330007673376666733766667333337673
00000677777600000006777777776000000000067760000056ddddddddddd6003777777333377733377777733777777333337773377777733777777333337773
000006777776000000067777777760000000000677600000056dddddddddd6003000000333300033300000033000000333330003300000033000000333330003
000006666776000000067766666660000000000677600000006dddddddddd6003777777337777773000000000000000000000000000000000000000000000000
00000555677600000006776555555000000000067760000000666666666666003766667337666673000000000000000000000000000000000000000000000000
00066666677600000006776666666000000000067760000000555555555555003767767337677673000000000000000000000000000000000000000000000000
00067777777600000006777777776000000000067760000000000000000000003766667337666673000000000000000000000000000000000000000000000000
00067777777600000006777777776000000000067760000000000000000000003767767337777673000000000000000000000000000000000000000000000000
00066666666600000006666666666000000000066660000000000000000000003766667330007673000000000000000000000000000000000000000000000000
00055555555500000005555555555000000000055550000000000000000000003777777333337773000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000003000000333330003000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
02222220022200002222000002220002222222222222220000222200002222220000000000000000000000000000000000000000000000000000000000000000
26666662266620026666200026662026666666626666662002666620026666662000000000000000000000000000000000000000000000000000000000000000
26ddddd625662026dddd62026ddd6226dddddd626ddddd62026dd62026ddddd62000000000000000000000000000000000000000000000000000000000000000
26dddddd6256226dddddd626ddddd626dddddd626dddddd6226dd6226dddddd62000000000000000000000000000000000000000000000000000000000000000
26dd66ddd62626ddd66dd626dd6dd62666dd66626dd66ddd626dd626dddd66662000000000000000000000000000000000000000000000000000000000000000
26dd656dd62626dd656dd626dd6dd62556dd65526dd656dd626dd626ddd655552000000000000000000000000000000000000000000000000000000000000000
26dd626dd62626dd62666626dd6dd62226dd62226dd626dd626dd626ddd622220000000000000000000000000000000000000000000000000000000000000000
26dd66ddd62626dd62555526dd6dd62026dd62026dd66dd6526dd626dddd62000000000000000000000000000000000000000000000000000000000000000000
26dddddd652626dd62222226dd6dd62026dd62026ddddd65226dd6256dddd6200000000000000000000000000000000000000000000000000000000000000000
26ddddd6522626dd62000026dd6dd62026dd62026dddd652026dd62256dddd620000000000000000000000000000000000000000000000000000000000000000
26dd6665226626dd62222226dd6dd62026dd62026dd6dd62026dd620256dddd62000000000000000000000000000000000000000000000000000000000000000
26dd655226d626dd62666626dd6dd62026dd62026dd66dd6226dd6200256ddd62000000000000000000000000000000000000000000000000000000000000000
26dd62226dd626dd626dd626dd6dd62026dd62026dd656dd626dd6222226ddd62000000000000000000000000000000000000000000000000000000000000000
26dd62026dd626ddd66dd626dd6dd62026dd62026dd626dd626dd626666dddd62000000000000000000000000000000000000000000000000000000000000000
26dd62026dd6256dddddd626ddddd62026dd62026dd626dd626dd626dddddd652000000000000000000000000000000000000000000000000000000000000000
26dd62026dd62256dddd65256ddd652026dd62026dd626dd626dd626ddddd6520000000000000000000000000000000000000000000000000000000000000000
26666202666620256666520256665200266662026666266662666626666665200000000000000000000000000000000000000000000000000000000000000000
25555202555520025555200025552000255552025555255552555525555552000000000000000000000000000000000000000000000000000000000000000000
02222222222222222222222222222222222222222222222222222222222222000000000000000000000000000000000000000000000000000000000000000000
00000266666202666666666266666666620266666200026666662666226666200000000000000000000000000000000000000000000000000000000000000000
00002666666622666666666266666666622666666620266666662666266665200000000000000000000000000000000000000000000000000000000000000000
00026665556662555666555255566655526665556662666555552666666652000000000000000000000000000000000000000000000000000000000000000000
00026662226662222666222022266622226662226662666222222666666520000000000000000000000000000000000000000000000000000000000000000000
00026666666662002666200000266620026666666662666200002666665200000000000000000000000000000000000000000000000000000000000000000000
00026666666662002666200000266620026666666662666200002666666200000000000000000000000000000000000000000000000000000000000000000000
00026665556662002666200000266620026665556662666222222666666620000000000000000000000000000000000000000000000000000000000000000000
00026662226662002666200000266620026662226662566666662666566662000000000000000000000000000000000000000000000000000000000000000000
00026662026662002666200000266620026662006662256666662666256666200000000000000000000000000000000000000000000000000000000000000000
00025552025552002555200000255520025552005552025555552555225555200000000000000000000000000000000000000000000000000000000000000000
00002220002220000222000000022200002220002220002222220222222222000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
f443333fff4433fff443333ff443333ff443333ff443333ff443333ff443333ff443333ff443333fff433fff0000000000000000000000000000000000000000
f466783fff4673fff466773ff466773ff463373ff466773ff466773ff467783ff466773ff466773fff473fff0000000000000000000000000000000000000000
f364373fff3373fff333373ff333373ff363383ff363333ff363333ff333383ff363373ff363373f4436333f0000000000000000000000000000000000000000
f373373fff0383fff378873ff038873ff377883ff378873ff378873ff000373ff378873ff378873f3788872f0000000000000000000000000000000000000000
f373262ffff372fff373322ff333362ff333372ff333362ff373362fffff372ff373362ff333362f3336221f0000000000000000000000000000000000000000
f387662ffff262fff377662ff377662ff000262ff377662ff377662fffff262ff377662ff000262f0037200f0000000000000000000000000000000000000000
f333221ffff221fff332221ff333221fffff221ff333221ff333221fffff221ff333221fffff221fff321fff0000000000000000000000000000000000000000
f000000ffff000fff000000ff000000fffff000ff000000ff000000fffff000ff000000fffff000fff000fff0000000000000000000000000000000000000000
37777773377777730000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
37666673376666730000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
37677673376776730000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
37666673376666730000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
37677673377776730000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
37666673300076730000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
37777773333377730000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
30000003333300030000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000003aaaaaa3000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000003a9999a3000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000003a9aaaa3000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000003a9999a3000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000003a9aa9a3000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000003a9999a3000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000003aaaaaa3000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000030000003000000000000000000000000000000000000000000000000000000000000000000000000
__gff__
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
1c1c1c1c1c1c1c1c1d1d1d1d1d1d1d1d1e1e1e1e1e1e1e1e0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1c1c1c1c1c1c1c1c1d1d1d1d1d1d1d1d1e1e1e1e1e1e1e1e0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1c1c1c1c1c1c1c1c1d1d1d1d1d1d1d1d1e1e1e1e1e1e1e1e0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1c1c1c1c1c1c1c1c1d1d1d1d1d1d1d1d1e1e1e1e1e1e1e1e0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1c1c1c1c1c1c1c1c1d1d1d1d1d1d1d1d1e1e1e1e1e1e1e1e0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1c1c1c1c1c1c1c1c1d1d1d1d1d1d1d1d1e1e1e1e1e1e1e1e0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1c1c1c1c1c1c1c1c1d1d1d1d1d1d1d1d1e1e1e1e1e1e1e1e0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1c1c1c1c1c1c1c1c1d1d1d1d1d1d1d1d1e1e1e1e1e1e1e1e0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1c1c1c1c1c1c1c1c1d1d1d1d1d1d1d1d1e1e1e1e1e1e1e1e0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1c1c1c1c1c1c1c1c1d1d1d1d1d1d1d1d1e1e1e1e1e1e1e1e0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1c1c1c1c1c1c1c1c1d1d1d1d1d1d1d1d1e1e1e1e1e1e1e1e0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1c1c1c1c1c1c1c1c1d1d1d1d1d1d1d1d1e1e1e1e1e1e1e1e0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1c1c1c1c1c1c1c1c1d1d1d1d1d1d1d1d1e1e1e1e1e1e1e1e0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1c1c1c1c1c1c1c1c1d1d1d1d1d1d1d1d1e1e1e1e1e1e1e1e0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1c1c1c1c1c1c1c1c1d1d1d1d1d1d1d1d1e1e1e1e1e1e1e1e0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1c1c1c1c1c1c1c1c1d1d1d1d1d1d1d1d1e1e1e1e1e1e1e1e0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1c1c1c1c1c1c1c1c1d1d1d1d1d1d1d1d1e1e1e1e1e1e1e1e0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1c1c1c1c1c1c1c1c1d1d1d1d1d1d1d1d1e1e1e1e1e1e1e1e0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
00010000000000c0700c0700c0700d07010070120701407016070160700d0000e0000f00010000130001400026000180000b0000a0000a0000a00009000080000700004000010000000000000000000000000000
000400000e600146101b620226402c660226202b60021600066001a60001200022001b6001b6001b60019600186000a6001450000000000000000000000000000000000000000000000000000000000000000000
00010000071400614006140061400c140141401914018140131400f1400d1400c1400c1400c1401014013130181301c14021140271402a1402b14028130231301c12014110101100d1700c1700c1700317002170
000400000253004530055200250009000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000b00002514022100221002210022100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001400003015030140301300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000700001e0731e0731e0731d1731c1731917315173101730c1730b1730c1730f173121630f1630b1530815304153021430213301133031130510301103000030000300003000030000300003000030000300003
000300001307117071190011400100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000200000835008350083500835008350083500835008350083500835008350203502135021350000002135021350213502135021350213500000000000000000000000000000000000000000000000000000000
000700001e1731e1731e1731d1031c1031910315103101030c1030b1030c1030f103121030f1030b1030810304103021030210301103031030510301103000030000300003000030000300003000030000300003
000100000611007130081400a1400d1401314014140101400a140091400c14010140171401f140271602c1702d1702c1702917025150201501e1401c1301e13022120271102c110301203215032160371603b140
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__music__
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344

