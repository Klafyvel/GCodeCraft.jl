module LibSerialPortExt
using GCodes
using LibSerialPort

mutable struct SerialPortBuffer
    queue::Channel{GCodes.Instructions.Instruction}
    port::LibSerialPort.SerialPort
    config::GCodes.GSerialConfiguration
    received_ok::Int
    sent_instr::Int
end
function serial_port_monitor(sp::SerialPortBuffer)
    @debug "Serial port monitoring started" Threads.threadid()
    if !isopen(sp.port)
        try
            open(sp.port)
            set_speed(sp.port, 250000)
            set_frame(sp.port, ndatabits=8, parity=SP_PARITY_NONE, nstopbits=1)
        catch e
            @error "Could not open serial port." e
            rethrow(e)
        end
        @debug "Port opened"
    end
    set_read_timeout(sp.port, sp.config.read_timeout)
    while isopen(sp.port)
        if bytesavailable(sp.port) > 0
            line = try
                readline(sp.port, keep=true)
            catch e
                @error "Error while readline" e
                if !(e isa LibSerialPort.Timeout)
                    rethrow(e)
                end
                nothing
            end
            if !isnothing(line)
                write(sp.config.output, line)
            end
            if line == "ok\n"
                sp.received_ok += 1
            end
        elseif isready(sp.queue) && sp.received_ok >= sp.sent_instr
            @debug "OMG I'm gonna move" sp.received_ok sp.queue
            instr = take!(sp.queue)
            str = GCodes.Instructions.format(sp.config, instr)
            @debug "sending"
            write(sp.port, str, "\n")
            @debug "sent"
            sp.sent_instr = sp.received_ok - 1
        else
            sleep(sp.config.sleeptime)
        end
    end
    close(sp)
    @debug "Serial port monitoring says goodbye."
end
Base.push!(spbuf::SerialPortBuffer, items...) =
    for i in items
        put!(spbuf.queue, i)
    end
function SerialPortBuffer(port, config)
    SerialPortBuffer(Channel{GCodes.Instructions.Instruction}(config.buffersize), port, config, 0, 0)
end

"""
    G(serialport[, config])

Create a G-Code program that streams directly towards a serial port. As sending and receiving happens in a separate thread, it is better to let `G` handle the opening.

`config` is a `GSerialConfiguration`.

See also [`GSerialConfiguration`](@ref).

# Example

```
using GCodes
using LibSerialPort

sp = LibSerialPort.SerialPort("/dev/ttyACM0")
config = GCodes.GSerialConfiguration(sleeptime=0.1, read_timeout=1)
g = G(sp, config)
move!(g, X=>5)
```
"""
function GCodes.G(sp::LibSerialPort.SerialPort, config::GCodes.GSerialConfiguration=GCodes.GSerialConfiguration())
    spbuf = SerialPortBuffer(sp, config)
    Threads.@spawn serial_port_monitor(spbuf)
    GCodes.G{SerialPortBuffer,GCodes.GSerialConfiguration}(spbuf, Dict(), :absolute, config)
end

export GSerialConfiguration
end
