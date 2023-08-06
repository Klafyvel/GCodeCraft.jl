"""
A very basic G-Code parser
"""
module Parser
using ..Instructions

parse_error(linenum, charnum, msg) = error("$linenum:$charnum : $msg")

@enum TokenType FieldName FieldValue Space Comma Star NewLine Comment

abstract type TokenStrategy end
let
    tokentypes = string.(instances(TokenType))
    strategy_names = [
        Symbol(string(Symbol(tokentype)) * "Strategy") for tokentype in tokentypes
    ]
    to_be_evaluated = [
        quote
            struct $strategy <: TokenStrategy end
        end for strategy in strategy_names
    ]
    switch_case = Meta.parse(
        "if " *
        join(
            [
                " tokentype == $tokentype f($strategy(), args...; kwargs...)" for
                (tokentype, strategy) in zip(tokentypes, strategy_names)
            ],
            "\nelseif ",
        ) *
    "else\nerror(\"Unmatched strategy.\")\nend",
    )
    function_expr = quote
        function map_token_strategy(f, tokentype::TokenType, args...; kwargs...)
            return $(switch_case)
        end
    end
    push!(to_be_evaluated, function_expr)
    eval.(to_be_evaluated)
end

struct Token
    type::TokenType
    string::String
    linenum::Int
    charnum::Int
end
Base.length(t::Token) = length(t.string)

function tokenize(::FieldNameStrategy, input, i, args...)
    fieldname = input[i:i]
    return Token(FieldName, fieldname, args...)
end
function tokenize(::FieldValueStrategy, input, i, args...)
    j = nextind(input, i)
    while j < lastindex(input)
        if input[j] ∈ (' ', '\n', ',', '*', ';')
            j = prevind(input, j)
            break
        end
        j = nextind(input, j)
    end
    value = input[i:j]
    return Token(FieldValue, value, args...)
end
function tokenize(::SpaceStrategy, input, i, args...)
    j = nextind(input, i)
    while j < lastindex(input)
        if input[j] ≠ ' '
            j = prevind(input, j)
            break
        end
        j = nextind(input, j)
    end
    value = input[i:j]
    return Token(Space, value, args...)
end
function tokenize(::CommaStrategy, input, i, args...)
    comma = input[i:i]
    return Token(Comma, comma, args...)
end
function tokenize(::StarStrategy, input, i, args...)
    star = input[i:i]
    return Token(Star, star, args...)
end
function tokenize(::NewLineStrategy, input, i, args...)
    j = nextind(input, i)
    while j < lastindex(input)
        if input[j] ≠ '\n'
            j = prevind(input, j)
            break
        end
        j = nextind(input, j)
    end
    value = input[i:j]
    return Token(NewLine, value, args...)
end
function tokenize(::CommentStrategy, input, i, args...)
    j = nextind(input, i)
    while j < lastindex(input)
        if input[j] == '\n'
            j = prevind(input, j)
            break
        end
        j = nextind(input, j)
    end
    value = input[i:j]
    return Token(Comment, value, args...)
end
function tokenize(input)
    linenum = 1
    charnum = 1
    i = firstindex(input)
    lasttokentype = NewLine
    tokens = Token[]
    while i <= lastindex(input)
        tokentype = if input[i] == ';'
            Comment
        elseif input[i] == '\n'
            NewLine
        elseif input[i] == '*'
            Star
        elseif input[i] == ','
            Comma
        elseif input[i] == ' '
            Space
        elseif lasttokentype ∈ (NewLine, Space) && input[i] ∈ "GMTSXYZUVWIJDHFRQEN"
            FieldName
        elseif lasttokentype == FieldName
            FieldValue
        else
            parse_error(linenum, charnum, "Unrecognized token '$(input[i])'")
        end
        token = map_token_strategy(tokenize, tokentype, input, i, linenum, charnum)
        i = nextind(input, i, length(token))
        if tokentype == NewLine
            linenum += length(token)
            charnum = 1
        else
            charnum += length(token)
        end
        push!(tokens, token)
        lasttokentype = tokentype
    end
    return tokens
end

function nextline(tokens, i)
    line = Token[]
    for token in tokens[i:end]
        if token.type ≠ NewLine
            push!(line, token)
        else
            break
        end
    end
    return line
end

function parse_field(line, i)
    token = line[i]
    if token.type != FieldName
        parse_error(token.linenum, token.charnum, "Expected a field name")
    end
    name = token.string
    i = nextind(line, i)
    if i > lastindex(line)
        parse_error(token.linenum, token.charnum, "Line ended to soon.")
    end
    token = line[i]
    if token.type == Space
        (i, name, nothing)
    elseif token.type != FieldValue
        parse_error(token.linenum, token.charnum, "Expected a field name or a space.")
    else
        value = token.string
        i = nextind(line, i)
        (i, name, value)
    end
end

function parse_prefix_num(prefix_num)
    splitted = split(prefix_num, ".")
    if length(splitted) == 1
        (Base.parse(Int, prefix_num), 0)
    else
        number, subcommand = parse.(Int, splitted)
        (number, subcommand)
    end
end

function parse!(
    ::Type{Instructions.Instruction}, tokens::Vector{Token}, target, i=firstindex(tokens)
)
    line = nextline(tokens, i)
    j = firstindex(line)
    prefix_token = line[j]
    if prefix_token.type == Comment
        # Comments are ignored for now
        return i + length(line) + 1
    end
    j, prefix, prefix_num = parse_field(line, j)
    if prefix ∉ ("G", "M", "T")
        parse_error(
            prefix_token.linenum, prefix_token.charnum, "Instruction prefix unrecognized \"$(prefix_token.string)\"."
        )
    elseif isnothing(prefix_num)
        parse_error(
            prefix_token.linenum, prefix_token.charnum, "Instruction prefix not followed by instruction number."
        )
    end
    number, subcommand = parse_prefix_num(prefix_num)
    parameters = Dict{Symbol,Union{Nothing,Float64}}()
    while j ≤ lastindex(line) && line[j].type ≠ Comment
        if line[j].type == Space
            j = nextind(line, j)
            continue
        end
        j, fieldname, fieldparam = parse_field(line, j)
        parameters[Symbol(fieldname)] =
            isnothing(fieldparam) ? fieldparam : Base.parse(Float64, fieldparam)
    end
    instruction = Instructions.Instruction(
        Instructions.prefix(prefix), number, subcommand, nothing, parameters
    )
    @debug "Pushing instruction" instruction
    push!(target, instruction)
    return i + length(line) + 1
end

function parse!(input, target)
    tokens = tokenize(input)
    i = 1
    while i < lastindex(tokens)
        i = parse!(Instructions.Instruction, tokens, target, i)
    end
    return target
end

end
