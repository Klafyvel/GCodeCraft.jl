struct GConfiguration
    output_digits::Int
end
"""
    GConfiguration()

A simple configuration, for which the G-Codes will be outputed in a Vector.

See also [`GSerialConfiguration`](@ref).
"""
GConfiguration() = GConfiguration(5)
output_digits(c::GConfiguration) = c.output_digits

struct GSerialConfiguration
    sleeptime::Float64
    output::IO
    buffersize::Int
    read_timeout::Float64

    output_digits::Int
end
output_digits(c::GSerialConfiguration) = c.output_digits

"""
    GSerialConfiguration(;sleeptime=0.01, output=stdout, output_digits=5, buffersize=16, read_timeout=10)

A configuration to stream G-Codes to a serial port. 

# Keywords
    * `sleeptime`: Time in seconds between each poll of the serial link.
    * `output`: `Base.IO` object towards which the text sent by the external device is redirected.
    * `output_digits`: number of digits in the command arguments sent.
    * `buffersize`: The size of the buffer used to communicate with the thread managing the serial link.
    * `read_timeout`: Time after which the reading operations will timeout.

# Example

```
using GCodeCraft
using LibSerialPort

sp = LibSerialPort.SerialPort("/dev/ttyACM0")
config = GCodeCraft.GSerialConfiguration(sleeptime=0.1, read_timeout=1)
g = G(sp, config)
move!(g, X=>5)
```
"""
function GSerialConfiguration(;sleeptime=0.01, output=stdout, output_digits=5, buffersize=16, read_timeout=10)
    GSerialConfiguration(sleeptime, output, buffersize, read_timeout, output_digits)
end
