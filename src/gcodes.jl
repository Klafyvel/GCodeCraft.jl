"""
    G()

A G-Code program.
"""
struct G
    instructions::Instructions.Instruction
end

export G
