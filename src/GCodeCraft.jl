module GCodeCraft

using PrecompileTools

include("configurations.jl")
include("instructions.jl")
include("parser.jl")
include("gcodes.jl")

"""
    parse(G, input)

Parse the `input` string into a new `G` program.
"""
Base.parse(::Type{G}, input) = Parser.parse!(input, G())
"""
    parse(g, input)

Parse the `input` string to GCode instructions and push it to the program `g`.
"""
Base.parse(g::G, input) = Parser.parse!(input, g)
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

@setup_workload begin
    # Putting some things in `@setup_workload` instead of `@compile_workload` can reduce the size of the
    # precompile file and potentially make loading faster.
    s = """
    G01 X6.7 Y7
    G28 ; Go home.
    """
    @compile_workload begin
        parse(G, s)
    end
end
end
