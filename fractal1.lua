local gpu = require('component').gpu
local xor = require('bit32').bxor
local uptime=require('computer').uptime
local math=require('math')
local abs=require('math').abs
local cos=require('math').cos
local sin=require('math').sin
local char=require('unicode').char
local center,max_x,max_y = 0, gpu.getResolution()
local shell=require('shell')
local ys,xs = max_y*4, max_x*2
local center_x=xs//2-2
local center_y = ys//2-2

local radius = ys//2-10
lines=400
local a, angle= 0, 2*math.pi/lines
local x,y=0,0
--опишем более быстрое однобитное ксорирование
local revers={} revers[0]=1 revers[1]=0
chars={}
local ch_y = math.floor(max_y)
local ch_x = math.floor(max_x)

function cls_chr()
    for y = 1,ch_y do 
        chars[y]={}
        for x = 1,ch_x do 
            chars[y][x] = 0x2800
        end
    end 
end

function cls_scr()    
screen = {}
for y=1.0,ys do
	screen[y]={}
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
function toUnicode()
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
function showMustGoOne()
    for y in pairs(chars)do
        show=''
        
        for x in pairs(chars[y])do
            show = show..char(chars[y][x])    
        end
        gpu.set(1,y,show)
    end
    return true
end



function pseudo_draw(x1,y1,x,y)--вычисляет координаты точек линии
	if x < x1 then x_step = -1 else x_step = 1 end
	if y < y1 then y_step = -1 else y_step = 1 end

	if abs(x-x1) > abs(y-y1) then
		y_step=y_step*abs(y-y1)/abs(x-x1)
		y_plot=y1
		for x_plot = x1,x,x_step do
			screen[center_y+y_plot//1+1][center_x+x_plot//1+1]=revers[screen[center_y+y_plot//1+1][center_x+x_plot//1+1]]
			y_plot=y_plot+y_step
		end
	else
		x_step=x_step*abs(x-x1)/abs(y-y1)
		x_plot=x1
		for y_plot = y1,y,y_step do
			screen[center_y+y_plot//1+1][center_x+x_plot//1+1]=revers[screen[center_y+y_plot//1+1][center_x+x_plot//1+1]]
			x_plot=x_plot+x_step
		end
	end
end
cls_scr() cls_chr()
step=17  f=2
while math.huge do
	t=uptime()
	lines=512
	while lines <= 888 do
angle=f*math.pi/lines
a= 0 
for i = 1, lines do
	x=radius*cos(a)
	y=radius*sin(a)
	--pseudo_draw(center_x/2,center_y/2,x,y)
	pseudo_draw(0,0,x,y)
	a=a+angle
end

toUnicode()
showMustGoOne()
--gpu.set(1,1,tostring(lines/20-39))
cls_scr()
cls_chr()
t=uptime()-t
--gpu.set(12,1,tostring(t))
t=uptime()
os.sleep((8001-lines)/40000)
os.sleep(0.4)
lines=lines+step
end
if step <60 then step=step+3 else step=33 end
end