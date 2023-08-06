"""
Here are defined the available G-Code instructions. Please refer to [Marlin's documentation](https://marlinfw.org/meta/gcode/) for G-Code reference.
"""
module Instructions
import ..output_digits

@enum Prefix G M T

struct Instruction
    prefix::Prefix
    number::Int
    subcommand::Int
    complement::Union{Nothing,String}
    parameters::Dict{Symbol,Union{Nothing,Float64}}
end

Instruction(p, n, params) = Instruction(p, n, 0, nothing, params)

prefix(p::String) =
    if p == "G"
        G
    elseif p == "M"
        M
    else
        T
    end

prefixstring(i::Instruction) =
    if i.prefix == G
        "G"
    elseif i.prefix == M
        "M"
    else
        "T"
    end

function Base.show(io::IO, instruction::Instruction)
    print(io, prefixstring(instruction) * string(instruction.number))
    if instruction.subcommand > 0
        print(io, ".$(string(instruction.subcommand))")
    elseif !isnothing(instruction.complement)
        print(io, " $(instruction.complement)")
    end
    if !isempty(instruction.parameters)
        print(io, " ")
        parameters = Vector{String}(undef, length(instruction.parameters))
        for (i,k) in enumerate(keys(instruction.parameters))
            if isnothing(instruction.parameters[k])
                parameters[i] = string(k)
            else
                parameters[i] = string(round(instruction.parameters[k]::Float64, digits=5))
            end
        end
        print(io, join(parameters, " "))
    end
end

include("instructions_array.jl")

for code in CODES
    name = Symbol(code.funname)
    main_id, second_id, compl = code.identifier
    prefix = Symbol(code.codetype)
    code = quote
        @doc $(code.doc) function $name(; params...)
            return Instruction($prefix, $main_id, $second_id, $compl, params)
        end
    end
    eval(code)
end

function format(config, instruction::Instruction)
    command = String[prefixstring(instruction) * string(instruction.number)]
    if instruction.subcommand > 0
        push!(command, "." * string(instruction.subcommand))
    elseif !isnothing(instruction.complement)
        push!(command, " " * instruction.complement::String)
    end
    if !isempty(instruction.parameters)
        for k in keys(instruction.parameters)
            if isnothing(instruction.parameters[k])
                push!(command, " " * string(k))
            else
                push!(command, " "*string(round(instruction.parameters[k]::Float64, digits=output_digits(config))))
            end
        end
    end
    return join(command)
end

end
