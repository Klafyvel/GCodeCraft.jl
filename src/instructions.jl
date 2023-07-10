"""
Here are defined the available G-Code instructions. Please refer to [Marlin's documentation](https://marlinfw.org/meta/gcode/) for G-Code reference.
"""
module Instructions
using Printf

@enum Prefix G M T

struct Instruction
    prefix::Prefix
    number::Int
    subcommand::Int
    complement::Union{Nothing, String}
    parameters::Dict{Symbol,Union{Nothing,Float64}}
end

Instruction(p, n, params) = Instruction(p, n, 0, params)

prefixstring(i::Instruction) = if i.prefix == G
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
        parameters = [
            string(k) * @sprintf("%1.5f", instruction.parameters[k])
            for k in keys(instruction.parameters)
        ]
        print(io, join(parameters, " "))
    end
end

CODES = include("instructions_array.jl")

for code in CODES
    name = Symbol(code.funname)
    main_id, second_id, compl = code.identifier
    prefix = Symbol(code.codetype)
    code = quote
        @doc $(code.doc)
        $name(;params...) = Instruction($prefix, $main_id, $second_id, $compl, params)
    end
    eval(code)
end

function format(config, instruction)
    command = prefixstring(instruction) * string(instruction.number)
    if instruction.subcommand > 0
        command *= ".$(string(instruction.subcommand))"
    elseif !isnothing(instruction.complement)
        command *= " $(instruction.complement)"
    end
    if !isempty(instruction.parameters)
        command *= " "
        formatter = Printf.Format("%1." * string(output_digits(config)) * "f")
        parameters = [
            string(k) * Printf.format(formatter, instruction.parameters[k])
            for k in keys(instruction.parameters)
        ]
        command *= join(parameters, " ")
    end
    command
end

end
