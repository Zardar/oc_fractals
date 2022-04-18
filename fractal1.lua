local gpu = require('component').gpu
local computer=require('computer')
local pullSignal = computer.pullSignal
local term=require('term')
local xor = require('bit32').bxor
local math=require('math')
local abs=require('math').abs
local cos=require('math').cos
local sin=require('math').sin
local char=require('unicode').char
local os=require('os')
local time, this_time = os.time, 0
local center,max_x,max_y = 0, gpu.getResolution()
local ys,xs = max_y*4, max_x*2
local center_x=xs//2-2
local center_y = ys//2-2

local radius = ys//2-10
local x,y=0,0
--опишем более быстрое однобитное ксорирование
local reverse={} reverse[0]=1 reverse[1]=0
local chars,screen={},{}
local ch_y,ch_x = (max_y//1),(max_x//1)
local xr,yr=0,0
local mode='0'
actions={}
events = {key_up='keyUp'}
--chars init
for y=1,ch_y do
	chars[y]={}
end
--screen init
for y=1.0,ys do
	screen[y]={}
end
--перехват ивентов. надстройка над ОС
function computer.pullSignal(...)
    local e = {pullSignal(...)}
       if events[e[1]] then
           return actions[events[e[1]]](e)
       end
   return true --table.unpack(e) --true --table.unpack(e) 
end
-----------------------------------
actions.t=function()
    --tetminate
    mode='terminate'
    term.clear()
    screen=nil
    chars=nil
    computer.pullSignal = pullSignal
    evo=nil
    return os.exit()
end
actions['1']=function()
 mode='0'
 return true
end
actions['2']=function()
mode = '1'
return true
end
---------------------------------
actions.keyUp=function(e)
    local key=math.floor(e[3])
    if key > 128 then
        key = string.lower(ru_keys[key])
    else
        key=string.lower(string.char(key))
    end
    if actions[key] then
        return actions[key](e)
    end
    return true
end


local function cls_chr()
    for y = 1,ch_y do 
        for x = 1,ch_x do 
            chars[y][x] = 0x2800
        end
    end 
end

local function cls_scr()    
	for y=1.0,ys do
		for x=1.0,xs do
			screen[y][x]=0
		end
	end
end

--опишем биткарту шрифта брайля
local bits = {} 
	bits[1]={1,8,2,16,4,32,64,128}
	bits[0]={0,0,0,0,0,0,0,0}
	bits[-1]={-1,-8,-2,-16,-4,-32,-64,-128}
--попробуем описать трансформацию значений массива в шрифт брайля
local function toUnicode()
  local ch_x,ch_y,yy,xx=0,0,0,0
    for y in pairs(screen) do
        ch_y=y+3  yy=y-1
        ch_y=math.floor(ch_y/4)
        for x in pairs(screen[y]) do
          ch_x=x+1  xx=x-1
            ch_x=math.floor(ch_x/2)
            chars[ch_y][ch_x]=chars[ch_y][ch_x]+bits[screen[y][x]][1+(yy%4)*2+xx%2]
        end
    end
    return true
end

--отобразим содержимое экрана
local function showMustGoOne()
    for y in pairs(chars)do
        show=''
        
        for x in pairs(chars[y])do
            show = show..char(chars[y][x])    
        end
        gpu.set(1,y,show)
    end
    return true
end

local function pseudo_draw(x1,y1,x,y)--вычисляет координаты точек линии
	if x < x1 then x_step = -1 else x_step = 1 end
	if y < y1 then y_step = -1 else y_step = 1 end

	if abs(x-x1) > abs(y-y1) then
		y_step=y_step*abs(y-y1)/abs(x-x1)
		y_plot=y1
		for x_plot = x1,x,x_step do
			screen[center_y+y_plot//1+1][center_x+x_plot//1+1]=reverse[screen[center_y+y_plot//1+1][center_x+x_plot//1+1]]
			y_plot=y_plot+y_step
		end
	else
		x_step=x_step*abs(x-x1)/abs(y-y1)
		x_plot=x1
		for y_plot = y1,y,y_step do
			screen[center_y+y_plot//1+1][center_x+x_plot//1+1]=reverse[screen[center_y+y_plot//1+1][center_x+x_plot//1+1]]
			x_plot=x_plot+x_step
		end
	end
end

cls_scr() cls_chr()
local x,y,a,angle,step,f,lines=0,0,0,0,17,2,0

function main()
while math.huge do
	lines=512.0
	while lines <= 888 do
		this_time=time()/1000
		if mode == '1' then 
			xr=(this_time%radius)*cos(1.0/sin(this_time))--radius/2-4
			yr=(this_time%radius)*sin(1.0/cos(this_time))--radius/2-4
		else
			xr=0
			yr=0
		end
		angle=f*math.pi/lines
		a= 0
		for i = 1, lines do
			if mode == '1' then 
				xr=(this_time%radius)*cos(1.0/sin(this_time))
				yr=(this_time%radius)*sin(1.0/cos(this_time))
			else
				xr=0
				yr=0
			end
			x=radius*cos(a)
			y=radius*sin(a)
			--pseudo_draw(center_x/2,center_y/2,x,y)
			pseudo_draw(xr,yr,x,y)
			a=a+angle
		end

		toUnicode()
		showMustGoOne()
		cls_scr()
		cls_chr()
		os.sleep((8001-lines)/40000)
		os.sleep(0.3)
		lines=lines+step
	end
	if step <60 then step=step+3 else step=33 end
end
end
main()