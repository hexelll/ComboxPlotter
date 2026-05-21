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
    ycoeff=3/2
}

local screen = Renderer:new{
    term=mon,
    combinators={
        SquarePixelCombinator,
        --MathCharCombinator
    }
}

while true do
    p:plot{
        screen=screen,
        miny=-2,
        maxy=2,
        graphs={
            p:sample(function(x)
                return {x,2*math.sin(x+os.clock())}
            end,-5,5,0.5,"area"),
            -- p:sample(function(x)
            --     return {2*math.cos(x+os.clock()),x}
            -- end,-2,2,0.5,"bar",{axis='y'}),
            -- p:sample(function(x)
            --     return {5*math.cos(x+os.clock()),2*math.sin(x+os.clock())}
            -- end,0,2*math.pi-math.pi/4,0.1,"line",{axis="y"})
        },
        colors={
            function(u,v)
                return p.colors.Teal:mix(p.colors.Red,u)
            end,
            p.colors.Red,
            p.colors.Rosewater
        },
        onRender=function(self,s,img)
        end
    }
    sleep()
end