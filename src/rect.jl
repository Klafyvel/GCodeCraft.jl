"""
    rect!(g; direction=:cw, start=:ll, axes...)

Trace a rectangle on the specified axes. `direction` can be clockwise (`:cw`) or counter-clockwise (`:ccw`). The rectangle will begin at the current position and the g will assume it is at the position specified by `start`. Possible values: `:ll`, `:ul`, `:lr` or `:ur` (`l`/`u`: lower/upper, `l`/`r`: left/right).

Note that a `relative!` command will be issued when starting, and that positioning mode will be restored afterwards.

# Example
```
rect!(g, :X=>10, :U=>40; direction=:ccw, start=:ul)
```
Will trace a 10×40 rectangle counter-clockwisely in the `XU` plane, assuming current position is upper-left.

```
rect!(g, [:X, :U]=>10, [:Y, :V]=>40; direction=:ccw, start=:ul)
```
Will trace a 10×40 rectangle counter-clockwisely in the `(XU)(YV)` plane, assuming current position is upper-left.
"""
function rect! end

abstract type Direction end
struct Clockwise <: Direction end
struct CounterClockwise <: Direction end

abstract type Start end
struct LowerLeft <: Start end
struct LowerRight <: Start end
struct UpperLeft <: Start end
struct UpperRight <: Start end

function rect!(g, width, height; start = :ll, kw...)
    return relative!(g) do
        if start == :ll
            rect!(LowerLeft(), g, width, height; kw...)
        elseif start == :lr
            rect!(LowerRight(), g, width, height; kw...)
        elseif start == :ul
            rect!(UpperLeft(), g, width, height; kw...)
        elseif start == :ur
            rect!(UpperRight(), g, width, height; kw...)
        else
            error("Unknown starting point $start.")
        end
    end
end

function rect!(s::Start, g, width, height; direction = :cw, kw...)
    return if direction == :cw
        rect!(Clockwise(), s, g, width, height; kw...)
    elseif direction == :ccw
        rect!(CounterClockwise(), s, g, width, height; kw...)
    else
        error("Unknown direction $direction.")
    end
end

function rect!(cw::Clockwise, ::LowerLeft, g, width, height; kw...)
    return move!(
        g,
        first(height) => [last(height), 0, -last(height), 0],
        first(width) => [0, last(width), 0, -last(width)];
        kw...,
    )
end
function rect!(cw::Clockwise, ::UpperLeft, g, width, height; kw...)
    return move!(
        g,
        first(height) => [0, -last(height), 0, last(height)],
        first(width) => [last(width), 0, -last(width), 0];
        kw...,
    )
end
function rect!(cw::Clockwise, ::UpperRight, g, width, height; kw...)
    return move!(
        g,
        first(height) => [-last(height), 0, last(height), 0],
        first(width) => [0, -last(width), 0, last(width)];
        kw...,
    )
end
function rect!(cw::Clockwise, ::LowerRight, g, width, height; kw...)
    return move!(
        g,
        first(height) => [0, last(height), 0, -last(height)],
        first(width) => [-last(width), 0, last(width), 0];
        kw...,
    )
end

function rect!(cw::CounterClockwise, ::LowerLeft, g, width, height; kw...)
    return move!(
        g,
        first(height) => [0, last(height), 0, -last(height), 0],
        first(width) => [last(width), 0, -last(width), 0];
        kw...,
    )
end
function rect!(cw::CounterClockwise, ::UpperLeft, g, width, height; kw...)
    return move!(
        g,
        first(height) => [-last(height), 0, last(height), 0],
        first(width) => [0, last(width), 0, -last(width)];
        kw...,
    )
end
function rect!(cw::CounterClockwise, ::UpperRight, g, width, height; kw...)
    return move!(
        g,
        first(height) => [0, -last(height), 0, last(height)],
        first(width) => [-last(width), 0, last(width), 0];
        kw...,
    )
end
function rect!(cw::CounterClockwise, ::LowerRight, g, width, height; kw...)
    return move!(
        g,
        first(height) => [last(height), 0, -last(height), 0],
        first(width) => [0, -last(width), 0, last(width)];
        kw...,
    )
end

export rect!
