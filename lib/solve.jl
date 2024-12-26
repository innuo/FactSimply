function maxent(ss::SampleSpace, 
    constraints::Vector{PMFConstraint{T}}, 
    query::ProbabilityExpression) where T <: Float64

    model = JuMP.Model(SCS.Optimizer)

    @variable(model, 0 <= pmf_table[ss.var_index] <= 1)
    @variable(model, t[ss.var_index]) #exp cone variable

    @constraint(model, sum(pmf_table[i] for i in ss.var_index) == 1.0)
    for c in constraints
        jump_constraint!(model, c, pmf_table, ss)
    end
    #@objective(model, Min, sum(log.(pmf_table[i]) .* pmf_table[i] for i in ss.var_index))
 
    #exp cone
    @constraint(model, [i in ss.var_index], [t[i], pmf_table[i], 1] in MOI.ExponentialCone())
    @objective(model, Max, sum(t))

    optimize!(model)

    @show termination_status(model), JuMP.OPTIMAL
    termination_status(model) == JuMP.OPTIMAL || termination_status(model) == JuMP.LOCALLY_SOLVED || return nothing

    maxent_pmf_table = value.(pmf_table)

    query_prob = prob(query, maxent_pmf_table, ss)
    @show ">>>>>>>>>>>>>>>>>>>>>>>>>> Max Ent"
    @show solution_summary(model)

    return query_prob
end

function compute_bounds(ss::SampleSpace, 
    constraints::Vector{PMFConstraint{T}}, 
    query::ProbabilityExpression) where T <: Float64

    model = JuMP.Model(HiGHS.Optimizer)

    @variable(model, 0 <= pmf_table[ss.var_index])
    @variable(model, 0 <= t) #linear fractional t

    @constraint(model, pmf_table .<= t)
    @constraint(model, sum(pmf_table[i] for i in ss.var_index) == t)

    for c in constraints
        num, den = prob_terms(c.lhs.joint_spec, c.lhs.condition_spec, pmf_table, ss)
        if den isa Number
            _add_constraint(model, num, c.rhs * den * t, c.direction)
        else
            _add_constraint(model, num, c.rhs * den, c.direction)
        end
    end 

    num, den = prob_terms(query, pmf_table, ss)
    _add_constraint(model, den, 1.0, eq)

    @objective(model, Min, num)
    optimize!(model)
    lb = objective_value(model)

    @show ">>>>>>>>>>>>>>>>>>>>>>>>>> LB"
    optimal_solve = true
    termination_status(model) == JuMP.OPTIMAL || (optimal_solve = false)
    lb = objective_value(model)
    @show lb, value(t)

    @objective(model, Max, num)
    optimize!(model)
    ub = objective_value(model)

    @show "UB"
    @show ub, value(t)

    termination_status(model) == JuMP.OPTIMAL || (optimal_solve = false)

    if optimal_solve
        p = [lb, ub]
    else
        p = nothing
    end

    print(model)

    return p
end