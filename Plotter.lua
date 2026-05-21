local Color = require "combox.Color"
local ImageHandler = require "combox.ImageHandler"

local function round(x)
    return math.floor(x+0.4999)
end

local Plotter = {}

local hexTable = {"0","1","2","3","4","5","6","7","8","9","a","b","c","d","e","f"}

local defaultPalette = {
    Red={
        0.90588235294118,
        0.50980392156863,
        0.51764705882353,
    },
    Marron={
        0.93725490196078,
        0.62352941176471,
        0.46274509803922,
    },
    Yellow={
        0.89803921568627,
        0.7843137254902,
        0.56470588235294,
    },
    Green={
        0.65098039215686,
        0.81960784313725,
        0.53725490196078,
    },
    Teal={
        0.50588235294118,
        0.7843137254902,
        0.74509803921569,
    },
    Blue={
        0.54901960784314,
        0.66666666666667,
        0.93333333333333,
    },
    Lavender={
        0.72941176470588,
        0.73333333333333,
        0.94509803921569,
    },
    Text={
        0.77647058823529,
        0.8156862745098,
        0.96078431372549,
    },
    Subtext={
        0.64705882352941,
        0.67843137254902,
        0.8078431372549,
    },
    Crust={
        0.13725490196078,
        0.14901960784314,
        0.20392156862745,
    },
    Base={
        0.18823529411765,
        0.20392156862745,
        0.27450980392157,
    },
    Surface0={
        0.25490196078431,
        0.27058823529412,
        0.34901960784314,
    },
    Surface1={
        0.31764705882353,
        0.34117647058824,
        0.42745098039216,
    },
    Overlay={
        0.45098039215686,
        0.47450980392157,
        0.58039215686275,
    },
    Rosewater={
        0.94901960784314,
        0.83529411764706,
        0.81176470588235,
    },
    Mauve={
        0.7921568627451,
        0.61960784313725,
        0.90196078431373,
    }
}

function Plotter:new(args)
    args = args or {}
    local o = {}
    o.colors = args.colors
    if not o.colors then
        o.colors = {}
        for k,v in pairs(defaultPalette) do
            o.colors[k] = Color(v[1],v[2],v[3])
        end
    end
    o.bgCol = args.bgCol or         Color(table.unpack(defaultPalette.Crust))
    o.gridCol = args.gridCol or     Color(table.unpack(defaultPalette.Base))
    o.originCol = args.originCol or Color(table.unpack(defaultPalette.Overlay))
    o.lineCol = args.lineCol or     Color(table.unpack(defaultPalette.Rosewater))
    o.ycoeff = args.ycoeff or (3/2)
    o.types = {
        point = {
            render=function(self,graph,screen,image,spaceToUv,color)
                local points = graph.data
                for i=1,#points do
                    local p = points[i]
                    local u,v = spaceToUv(p[1],p[2])
                    color = p[3] or (color or self.lineCol)
                    local col = type(color) == "function" and color(u,v) or color
                    image:setPx(u,v,col)
                end
            end
        },
        line = {
            render=function(self,graph,screen,image,spaceToUv,color)
                local points = graph.data
                for i=1,#points-1 do
                    local p1 = points[i]
                    local p2 = points[i+1]
                    local u1,v1 = spaceToUv(p1[1],p1[2])
                    local u2,v2 = spaceToUv(p2[1],p2[2])
                    color = p1[3] or (color or self.lineCol)
                    self:drawLine(screen,image,u1,v1,u2,v2,color)
                end
            end
        },
        bar = {
            render=function(self,graph,screen,image,spaceToUv,color)
                local points = graph.data
                local args = graph.args or {}
                local yaxis = args.axis == "y"
                for i=1,#points do
                    local p = points[i]
                    local u,v = spaceToUv(p[1],p[2])
                    local uz,vz = spaceToUv(0,0)
                    color = p[3] or (color or self.lineCol)
                    if yaxis then
                        self:drawLine(screen,image,u,v,uz,v,color)
                    else
                        self:drawLine(screen,image,u,v,u,vz,color)
                    end
                end
            end
        },
        area = {
            render=function(self,graph,screen,image,spaceToUv,color)
                local points = graph.data
                local args = graph.args or {}
                local yaxis = args.axis == "y"
                for j=1,#points-1 do
                    local p = points[j]
                    local p1 = points[j+1]
                    local u,v = spaceToUv(p[1],p[2])
                    local u1,v1 = spaceToUv(p1[1],p1[2])
                    local dx = u1-u+0.001
                    local dy = v1-v
                    local a = dy/dx
                    local b = v-a*u
                    local uz,vz = spaceToUv(0,0)
                    color = p[3] or (color or self.lineCol)
                    if yaxis then
                        b = -b/a
                        a = 1/a
                        for i=v,v1,(dy/math.abs(dy)) * 1/(screen.sy*3/2) do
                            self:drawLine(screen,image,i*a+b,i,uz,i,color)
                        end
                    else
                        for i=u,u1,(dx/math.abs(dx)) * 1/screen.sx do
                            self:drawLine(screen,image,i,i*a+b,i,vz,color)
                        end
                    end
                end
            end
        }
    }
    o.palette = {}
    for _,col in pairs(o.colors) do
        o.palette[#o.palette+1] = col
    end
    setmetatable(o,{__index=function (_, k)
        return self[k]
    end})
    return o
end

function Plotter:drawLine(screen,image,u1,v1,u2,v2,col)
    local color = type(col) == "function" and col(u1,v1) or col
    image:setPx(u1,v1,color)
    color = type(col) == "function" and col(u2,v2) or col
    image:setPx(u2,v2,color)
    local dy = v1-v2
    local dx = u1-u2
    if dx ~= 0 then
        local interval = 1/(screen.sx+(dy ~= 0 and 3*math.abs(screen.sy/dy) or 0))
        interval = dx > 0 and -interval or interval
        local a = dy/dx
        local b = v1-a*u1
        for x=u1,u2,interval do
            local y = a*x+b
            color = type(col) == "function" and col(x,y) or col
            image:setPx(x,y,color)
        end
    else
        local interval = 1/(screen.sy*3/2)
        interval = dy > 0 and -interval or interval
        for y=v1,v2,interval do
            color = type(col) == "function" and col(u1,y) or col
            image:setPx(u1,y,color)
        end
    end
end

function Plotter:sample(fn,a,b,interval,ptype,args)
    ptype = ptype or "line"
    local points = {}
    interval = interval or 1
    for i=a,b,interval do
        points[#points+1] = fn(i)
    end
    return {data=points,type=ptype,args=args}
end

function Plotter:plot(args)
    local screen = args.screen
    local graphs = args.graphs
    local colors = args.colors or {}
    local labels = args.labels or {}
    local minay = args.miny
    local maxay = args.maxy
    local minax = args.minx
    local maxax = args.maxx
    local paddingx = args.paddingx or 1
    local paddingy = args.paddingy or 1
    local scalex = args.scalex or 1
    local scaley = args.scaley or 1
    local gridx = args.gridx or scalex
    local gridy = args.gridy or scaley
    local originx = args.originx or 0
    local originy = args.originy or 0
    local autoscale = args.autoscale
    local autoscalex = args.autoscalex or autoscale
    local autoscaley = args.autoscaley or autoscale
    local onRender = args.onRender or function(self,screen,image) end
    local image = args.bg and args.bg:duplicate() or ImageHandler:new(screen.sx,round(screen.sy*3/2)):process(function()
        return self.bgCol
    end)
    local minx = math.huge
    local maxx = -math.huge
    local miny = math.huge
    local maxy = -math.huge
    for _,points in pairs(graphs) do
        for _,p in pairs(points.data) do
            minx = minx < p[1] and minx or p[1]
            maxx = maxx > p[1] and maxx or p[1]
            miny = miny < p[2] and miny or p[2]
            maxy = maxy > p[2] and maxy or p[2]
        end
    end

    miny = minay and minay or miny
    maxy = maxay and maxay or maxy
    minx = minax and minax or minx
    maxx = maxax and maxax or maxx
    miny = miny-paddingy
    maxy = maxy+paddingy
    minx = minx-paddingx
    maxx = maxx+paddingx
    local function spaceToUv(x,y)
        return (x-minx)/(maxx-minx+0.0001),1-(y-miny)/(maxy-miny+0.0001)
    end
    local ug,vg = spaceToUv(gridx+minx,gridy+miny)
    vg = 1-vg
    local uz,vz = spaceToUv(originx,originy)
    if ug > 3/screen.sx then
        local x = minx
        while x <= maxx do
            for i=0,image.sy-1,3 do
                local v = i/(image.sy-0)
                local u = spaceToUv(x,0)
                image:setPx(u,v,self.gridCol)
            end
            x=x+gridx
        end
    end
    if vg > 3/screen.sy then
        local y = miny+1
        while y <= maxy do
            for i=0,image.sx-1,3 do
                local u = i/(image.sx-1)
                local _,v = spaceToUv(0,y)
                image:setPx(u,v,self.gridCol)
            end
            y=y+gridy
        end
    end
    if vz > 0 then
        for i=1,image.sx-2,2 do
            local u = i/(image.sx-1)
            image:setPx(u,vz,self.originCol)
        end
    end
    if uz > 0 then
        for i=0,image.sy-1,2 do
            local v = i/(image.sy-1)
            image:setPx(uz,v,self.originCol)
        end
    end
    for j,graph in pairs(graphs) do
        self.types[graph.type].render(self,graph,screen,image,spaceToUv,colors[j])
    end
    onRender(self,screen,image)
    local palette = self.palette and self.palette or image:findPalette()
    screen:render(image,palette).display()

    local x = minx
    while x<=maxx+1 do
        local u = spaceToUv(x,0)
        local text = tostring(round(x*10)/10)
        screen.term.setCursorPos(screen.px+1+u*(screen.sx),screen.py+1)
        screen.term.blit(
            text,
            hexTable[self.originCol:findClosest(palette)]:rep(#text),
            hexTable[self.bgCol:findClosest(palette)]:rep(#text)
        )
        x = x + (autoscalex and (maxx-minx+0.0001)/scalex or scalex)
    end
    local y = miny+1
    while y < maxy do
        local _,v = spaceToUv(0,y)
        local text = tostring(round(y*10)/10)
        screen.term.setCursorPos(screen.px+1,screen.py+1+v*(screen.sy))
        screen.term.blit(
            text,
            hexTable[self.originCol:findClosest(palette)]:rep(#text),
            hexTable[self.bgCol:findClosest(palette)]:rep(#text)
        )
        y = y + (autoscaley and (maxy-miny+0.0001)/scaley or scaley)
    end
    
    for i,_ in pairs(graphs) do
        local col = colors[i] and colors[i] or self.lineCol
        screen.term.setCursorPos(screen.px+1,screen.py+screen.sy-i)
        local p = graphs[i].data[#graphs[i].data]
        local color = type(col)=="function" and col(spaceToUv(p[1],p[2])) or col
        local text = (labels[i] and labels[i] or "y"..i)..":("..(round(p[1]*100)/100)..","..(round(p[2]*100)/100)..")"
        screen.term.blit(text,hexTable[self.bgCol:findClosest(palette)]:rep(#text),hexTable[color:findClosest(palette)]:rep(#text))
    end
end

return Plotter