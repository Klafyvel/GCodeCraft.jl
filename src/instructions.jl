"""
Here are defined the available G-Code instructions. Please refer to [Marlin's documentation](https://marlinfw.org/meta/gcode/) for G-Code reference.
"""
module Instructions
@enum Prefix G M

struct Instruction
    prefix::Prefix
    number::Int
    parameters::Dict{Symbol,Union{Nothing,Float64}}
end

######## G-Codes ########
GCODES = Dict([
    0  =>  ("Rapid linear move (convention: no extrusion).", "https://marlinfw.org/docs/gcode/G000-G001.html")
    1  =>  ("Rapid movement (convention: with extrusion).", "https://marlinfw.org/docs/gcode/G000-G001.html")
    2  =>  ("Clockwise arc move.", "https://marlinfw.org/docs/gcode/G002-G003.html")
    3  =>  ("Counter-clockwise arc move.", "https://marlinfw.org/docs/gcode/G002-G003.html")
    4  =>  ("Dwell pauses the command queue and waits for a period of time.", "https://marlinfw.org/docs/gcode/G004.html")
    5  =>  ("Create a cubic B-spline in the XY plane.", "https://marlinfw.org/docs/gcode/G005.html")
    6  =>  ("Direct Stepper Move.", "https://marlinfw.org/docs/gcode/G006.html")
    10 => ("Retract.", "https://marlinfw.org/docs/gcode/G010.html")
    11 => ("Recover.", "https://marlinfw.org/docs/gcode/G011.html")
    12 => ("Clean the Nozzle.", "https://marlinfw.org/docs/gcode/G012.html")
    17 => ("Select workspace plane XY.", "https://marlinfw.org/docs/gcode/G017-G019.html")
    18 => ("Select workspace plane ZX.", "https://marlinfw.org/docs/gcode/G017-G019.html")
    19 => ("Select workspace plane YZ.", "https://marlinfw.org/docs/gcode/G017-G019.html")
    20 => ("Set Units to Inches.", "https://marlinfw.org/docs/gcode/G020.html")
    21 => ("Set Units to Millimeters.", "https://marlinfw.org/docs/gcode/G021.html")
    26 => ("Mesh Validation Pattern.", "https://marlinfw.org/docs/gcode/G026.html")
    27 => ("Park the current toolhead.", "https://marlinfw.org/docs/gcode/G027.html")
    28 => ("Auto Home.", "https://marlinfw.org/docs/gcode/G028.html")
    29 => ("Bed Leveling.", "https://marlinfw.org/docs/gcode/G029.html")
    30 => ("Single Z-Probe.", "https://marlinfw.org/docs/gcode/G030.html")
    31 => ("Dock the Z probe sled.", "https://marlinfw.org/docs/gcode/G031.html")
])

for (i,doc) in GCODES
    name = Symbol("G" * string(i))
    documentation = """
        G$i(;params...)
    $(doc[1])

    See [Marlin's G-Code reference]($(doc[2])).
    """
    code = quote
        @doc $documentation
        $name(;params...) = Instruction(G, $i, params)
    end
    eval(code)
end

end
