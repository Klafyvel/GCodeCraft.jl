module GCodeCraft

include("configurations.jl")
include("instructions.jl")
include("parser.jl")
include("gcodes.jl")

"""
    parse(G, input)

Parse the `input` string into a new `G` program.
"""
Base.parse(::Type{G}, input) = Parser.parse!(G, input, G())
"""
    parse(g, input)

Parse the `input` string to GCode instructions and push it to the program `g`.
"""
Base.parse(g::G, input) = parse!(G, input, g)
function Base.parse(::Type{Instructions.Instruction}, input)
    p = Instructions.Instruction[]
    tokens = Parser.tokenize(input)
    Parser.parse!(Instructions.Instruction, tokens, p)
    return first(p)
end

"""
Use `Base.parse(G, s)` to the given string `s`.

See also [`G`](@ref).
"""
macro G_str(p)
    return Base.parse(G, p)
end
"""
Use `Base.parse(Instructions.Instruction, s)` to the given string `s`.

See also [`Instructions.Instruction`](@ref).
"""
macro GCode_str(p)
    return Base.parse(Instructions.Instruction, p)
end

export @G_str, @GCode_str

end
