# G-Code program interface

"""
    status(program, [axis])

Return the current position in the program.
"""
function status end
# function sethome end
# function resethome end
# function feed end
# function dwell end
# function home end
# function arc! end
# function absarc end
# function meander end
# function clip end
# function triangularwave end


"""
    G()

A G-Code program.
"""
mutable struct G{T, P}
    instructions::T
    current_position::Dict{Symbol,Float64}
    current_mode::Symbol
    config::P
end
G(config::P=GConfiguration()) where P = G{Vector{Instructions.Instruction}, P}([], Dict(), :absolute, config)

Base.push!(g, instr...) = push!(g.instructions, instr...)

status(g) = g.current_position
status(g, axis) = get(g.current_position, axis, 0.0)

"""
    absolute!([f ,]g)
Set current mode to absolute. If `f` is given, it will be executed ensuring current mode is absolute.

See also [`relative!`](@ref).
"""
absolute!(g) = if g.current_mode ≠ :absolute 
    g.current_mode = :absolute
    push!(g, Instructions.G91())
end
function absolute!(f, g)
    need_restore = false
    if g.current_mode ≠ :absolute
        absolute!(g)
        need_restore = true
    end
    f()
    if need_restore
        relative!(g)
    end
end

"""
    relative!([f, ]g)
Set current mode to relative. If `f` is given, it will be executed ensuring current mode is absolute.

See also [`absolute!`](@ref).
"""
relative!(g) = if g.current_mode ≠ :relative 
    g.current_mode = :relative
    push!(g, Instructions.G90())
end
function relative!(f, g)
    need_restore = false
    if g.current_mode ≠ :relative
        relative!(g)
        need_restore = true
    end
    f()
    if need_restore
        absolute!(g)
    end
end

invert_mode!(g) = if g.current_mode == :absolute
    relative!(g)
else
    absolute!(g)
end

const Dimension = Pair{Union{Symbol, Vector{Symbol}}, Real}

include("move.jl")
include("rect.jl")

export G, status, absolute!, relative!
