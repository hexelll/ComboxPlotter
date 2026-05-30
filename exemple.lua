local Renderer = require "combox.Renderer"
local Color = require "combox.Color"
local Plotter = require "Plotter"


local mon = peripheral.find("monitor")
if mon then
    mon.setTextScale(0.5)
end

local MathCharCombinator = require "combox.combinators.MathCharCombinator":new()
local SquarePixelCombinator = require "combox.combinators.SquarePixelCombinator":new()

local p = Plotter:new{
    ycoeff=1
}

local screen = Renderer:new{
    term=mon,
    combinators={
        --SquarePixelCombinator,
        MathCharCombinator
    }
}

while true do
    p:plot{
        screen=screen,
        paddingx=0,
        miny=-2,
        maxy=2,
        graphs={
            p:sample(function(x)
                return {x,2*math.cos(x+os.clock()*2)}
            end,-5,5,0.5,"bar",{axis='x'}),
            p:sample(function(x)
                return {x,2*math.sin(x+os.clock()*2)}
            end,-5,5,0.5,"line"),
            
        },
        colors={
            function(u,v)
                return Color(0,(u+os.clock()/5)%1,v)
            end,
            p.colors.Red,
            p.colors.Rosewater
        },
        onRender=function(self,s,img)
        end
    }
    sleep(0.1)
end
