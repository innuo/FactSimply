@kwdef mutable struct Fact{P}
    id::Int
    what_text::String
    when_text::String
    prob_range::P
    is_query::Bool
    printable::String = ""
end

function Fact(id, what_text, when_text, prob_range, is_query)
    f = Fact{typeof(prob_range)}(id, what_text, when_text, prob_range, is_query, "")
    f.printable = to_string(f)
    return f
end

function probability_expression(fact::Fact)
    (;var_symbols, vals) = parse_input(fact.what_text)
    joint_spec = JointSpec(var_symbols, vals)
 
    (;var_symbols, vals) =  parse_input(fact.when_text)
    cond_spec = JointSpec(var_symbols, vals)
    
    pe = ProbabilityExpression(joint_spec=joint_spec, condition_spec=cond_spec)
    return pe
end

function parse_problem(facts, query)
    all_vars = Symbol[]
    constraints = PMFConstraint[]

    for f in facts
        pe = probability_expression(f)
        push!(all_vars, vars(pe)...)
        if f.prob_range.max - f.prob_range.min < 0.01
            constraint = PMFConstraint(lhs=pe, rhs=f.prob_range.min, direction=eq)
            push!(constraints, constraint)
        else
            constraint = PMFConstraint(lhs=pe, rhs=f.prob_range.min, direction=geq)
            push!(constraints, constraint)
            constraint = PMFConstraint(lhs=pe, rhs=f.prob_range.max, direction=leq)
            push!(constraints, constraint)
        end

    end
    all_vars = unique(all_vars)
    sample_space = SampleSpace(all_vars)

    query_expression = probability_expression(query)
    query_vars = vars(query_expression)

    return (;sample_space, constraints, query_expression, query_vars)
end

function parse_input(expression)
    # Split the input by commas and remove leading/trailing spaces
    substrings = split(expression, ",")
    print_strings = []
    var_symbols = Symbol[]
    vals = Bool[]

    for substring in substrings
        cleaned_str = replace(substring, r"[^a-zA-Z0-9!]" => "")
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


export Fact, probability_expression, parse_problem, parse_input, to_string