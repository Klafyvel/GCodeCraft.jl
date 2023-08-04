"""
    move!(program, axes...; mode=:current, rapid=false)

Move linearly the program to the specified position.

If the movement `mode` does not correspond to the currently set movement mode, 
it will be set correctly beforehand. Possible values: `:current`, `:absolute` or `:relative`.

# Examples
```
move!(g, :X=>5, mode=:relative, rapid=true)
```
Moves in rapid movement mode the `X` axis by 5 units.

```
move!(g, :Y=>6, :X=>0.1, :U=>3, mode=:absolute)
move!(g, [:Y, :V]=>6, [:X, :U]=>3, mode=:relative)
move!(g, [:Y, :V]=>[6, 0.5, -5], [:X, :U]=>[3, 4, 5], mode=:relative)
```
"""
function move! end

append_movement!(d, a, m) = d[a] = collect(m)
append_movement!(d, as::Vector, m) = for a in as append_movement(d, a, m) end

function move!(g, movements...; mode=:current, rapid=false)
    if mode ≠ :current && mode ≠ g.current_mode
        invert_mode!(g)
    end
    axes = Dict()
    sequence_length = length(last(first(movements)))
    for m in movements
        append_movement!(axes, first(m), last(m))
        if length(last(m)) ≠ sequence_length
            error("All axes' movement sequences must have the same number of segments.")
        end
    end
    if g.current_mode == :relative
        for axis in keys(axes)
            g.current_position[axis] = status(g, axis) + sum(axes[axis])
        end
    else
        for axis in keys(axes)
            g.current_position[axis] = last(axes[axis])
        end
    end
    for i in 1:sequence_length
        ax = Dict(map(x->first(x)=>last(x)[i], collect(axes)))
        if rapid
            push!(g, Instructions.G0(;ax...))
        else
            push!(g, Instructions.G1(;ax...))
        end
    end
end

export move!
