struct GConfiguration
    output_digits::Int
end
GConfiguration() = GConfiguration(5)
#
# Configurations interface
output_digits(c::GConfiguration) = c.output_digits

