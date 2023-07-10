# G-Code program interface

"""
    status(program, [axis])

Return the current position in the program.
"""
function status end
"""
    move!(program; mode=:current, rapid=false, axes...)

Move linearly the program to the specified position.

If the movement `mode` does not correspond to the currently set movement mode, 
it will be set correctly beforehand. Possible values: `:current`, `:absolute` or `:relative`.

# Examples
```
move!(g, mode=:relative, rapid=true, X=5)
```
Moves in rapid movement mode the `X` axis by 5 units.

```
move!(g, mode=:absolute, Y=6, X=0.1, U=3)
```
"""
function move! end
# function sethome end
# function resethome end
# function feed end
# function dwell end
# function home end
# function arc! end
# function absarc end
"""
    rect!(program; direction=:cw, start=:ll, axes...)

Trace a rectangle on the specified axes. `direction` can be clockwise (`:cw`) or counter-clockwise (`:ccw`). The rectangle will begin at the current position and the program will assume it is at the position specified by `start`. Possible values: `:ll`, `:ul`, `:lr` or `:ur` (`l`/`u`: lower/upper, `l`/`r`: left/right).

# Example
```
rect!(g; direction=:ccw, start=:ul, X=10, U=40)
```
Will trace a 10×40 rectangle counter-clockwisely in the `XU` plane, assuming current position is upper-left.
"""
function rect! end
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

Base.push!(g, instr) = push!(g.instructions, instr)

status(g) = g.current_position
status(g, axis) = get(g.current_position, axis, 0.0)

invert_mode!(g) = if g.mode == :absolute
    g.mode = :relative
    push!(g, Instructions.G91())
else
    g.mode = :absolute
    push!(g, Instructions.G90())
end
function move!(g; mode=:current, rapid=false, axes...)
    if mode ≠ :current && mode ≠ g.current_mode
        invert_mode!(g)
    end
    if g.current_mode == :relative
        for axis in keys(axes)
            g.current_position[axis] = status(g, axis) + axes[axis]
        end
    else
        for axis in keys(axes)
            g.current_position[axis] = axes[axis]
        end
    end
    if rapid
        push!(g, Instructions.G0(;axes...))
    else
        push!(g, Instructions.G1(;axes...))
    end
end

export G, move!, status
