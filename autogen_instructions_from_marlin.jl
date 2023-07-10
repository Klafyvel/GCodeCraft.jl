using LibGit2
using YAML
using JuliaFormatter
using Dates


dir = mktempdir()

@info "Cloning Marlin's documentation" dir
LibGit2.clone("https://github.com/MarlinFirmware/MarlinDocumentation.git", dir)


gcodespath = joinpath(dir, "_gcode")

function load_file(path)
    yaml = YAML.load_file(path)
    md = open(path) do f
        yaml_started = false
        yaml_ended = false
        while !eof(f) && !yaml_ended
            l = readline(f)
            if l == "---" && !yaml_started
                yaml_started = true
            elseif l == "---" && yaml_started
                yaml_ended = true
            end
        end
        read(f, String)
    end
    yaml["mddescr"] = md    
    yaml
end

function name_to_functionname(name)
    replace(name, "."=>"_", " "=>"_")
end

function make_docstring(name, yaml, url)
    res = """
        $name(;params...)
    $(yaml["brief"])

    *Note:* This documentation has been automatically generated from [Marlin's G-Code documentation]($url).


    """

    if "parameters" ∈ keys(yaml) && !isnothing(yaml["parameters"])
        res *= """
        # Marlin parameters
        Note: these are Marlin's G-Code parameters. GCodes.jl does not inforce them.
        """
        for param in yaml["parameters"]
            p = "* $(param["tag"]) $(ifelse(get(param, "optional", false), "[Optional]", "")): $(get(param, "description", ""))\n"
            res *= p
        end
    end
    res *= "\n\n# Description\n"
    res *= yaml["mddescr"]
    if "related" ∈ keys(yaml)
        if yaml["related"] isa Vector
            seealsos = ["[`$(name_to_functionname(c))`](@ref)" for c in yaml["related"]]
            res *="\n\nSee also $(join(seealsos, ", ", " and "))."
        else
            seealsos = "[`$(name_to_functionname(yaml["related"]))`](@ref)"
            res *="\n\nSee also $(seealsos)."
        end
    end
    res
end

function process_name(name)
    splitted = split(name, ".")
    splitted_space = split(name, " ")
    funname = name_to_functionname(name)
    codetype = name[1:1]
    identifier = if length(splitted_space) == 1
        if length(splitted) == 1
            (parse(Int, name[2:end]), 0, nothing)
        else
            (parse(Int, splitted[1][2:end]), parse(Int, splitted[2]), nothing)
        end
    else
        (parse(Int, splitted_space[1][2:end]), 0, splitted_space[2])
    end
    (;codetype, identifier, funname)
end

all_codes = Dict()
@info "Generating documentation and function names"
for fname in readdir(gcodespath, join=true)
    yaml = load_file(fname)
    for name in yaml["codes"]
        try
            url = "https://marlinfw.org/docs/gcode/" * splitext(basename(fname))[1] * ".html"
            doc = make_docstring(name, yaml, url)
            meta = process_name(name)
            all_codes[meta.funname] = (;meta..., doc)
        catch e
            @error "On" name fname
            rethrow(e)
        end
    end
end

@info "Exporting to src/instructions_array.jl"
open(joinpath("src", "instructions_array.jl"), "w") do f
    write(f, "# This file is auto-generated. Please do not edit!\n")
    write(f, "# Generation date: $(now())\n\n")
    write(f, format_text(repr(collect(values(all_codes))[sortperm(collect(keys(all_codes)))])))
end

@info "Done!"
