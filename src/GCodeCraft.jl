module GCodeCraft

include("configurations.jl")
include("instructions.jl")
include("parser.jl")
include("gcodes.jl")

"""
Use `Base.parse(G, s)` to the given string `s`.

See also [`G`](@ref).
"""
macro G_str(p)
    Base.parse(G, p)
end
"""
Use `Base.parse(Instructions.Instruction, s)` to the given string `s`.

See also [`Instructions.Instruction`](@ref).
"""
macro GCode_str(p)
    Base.parse(Instructions.Instruction, p)
end

export @G_str, @GCode_str

end
