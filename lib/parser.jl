



function parse_input(expression)
    # Split the input by commas and remove leading/trailing spaces
    substrings = split(expression, ",")
    print_strings = []
    var_symbols = Symbol[]
    vals = Bool[]

    for substring in substrings
        cleaned_str = strip(substring)
        is_negated = startswith(cleaned_str, "!")

        if is_negated
            cleaned_str = cleaned_str[2:end]
        end

        length(cleaned_str) == 0 && continue

        cleaned_str = uppercase(cleaned_str)
        value = is_negated ? false : true
        push!(var_symbols, Symbol(cleaned_str))
        push!(vals, value)
        push!(print_strings, "$cleaned_str=$value")
    end

    return (; printable = join(print_strings, ", "), 
            var_symbols = var_symbols, vals = vals)
end

function to_string(fact)
    joint = parse_input(fact.what_text)
    cond = parse_input(fact.when_text)
    
    prob_statement = length(cond.vals) == 0 ? "P($(joint.printable))" : "P($(joint.printable) | $(cond.printable))"
    rhs = " = ?"
    if !fact.is_query
        if fact.prob_range.max - fact.prob_range.min < 0.01
            rhs = " = $(fact.prob_range.min)"
        else
            rhs = " ∈ [$(fact.prob_range.min), $(fact.prob_range.max)]"
        end
    end

    return  prob_statement * rhs
end



export parse_input, to_string