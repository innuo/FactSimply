function maxent(ss::SampleSpace, 
    constraints::Vector{PMFConstraint}, 
    query::ProbabilityExpression) 

    model = JuMP.Model(SCS.Optimizer)

    @variable(model, 0 <= pmf_table[ss.var_index] <= 1)
    @variable(model, t[ss.var_index])
    @constraint(model, sum(pmf_table[i] for i in ss.var_index) == 1.0)
    for c in constraints
        jump_constraint(model, c, pmf_table, ss)
    end
    #@objective(model, Min, sum(log.(pmf_table[i]) .* pmf_table[i] for i in ss.var_index))
    #@objective(model, Max, entropy(pmf_table))

    #exp cone
    @constraint(model, [i in ss.var_index], [t[i], pmf_table[i], 1] in MOI.ExponentialCone())
    @objective(model, Max, sum(t))

    optimize!(model)
    print(model)

    @show termination_status(model), JuMP.OPTIMAL
    termination_status(model) == JuMP.OPTIMAL || termination_status(model) == JuMP.LOCALLY_SOLVED || return nothing

    maxent_pmf_table = value.(pmf_table)

    @show maxent_pmf_table

    query_prob = prob(query, maxent_pmf_table, ss)

    @show query
    @show  query_prob
    @show ">>>>>>>>>>>>>>>>>>>>>>>>>> Max Ent"
    @show solution_summary(model)

    return query_prob
end

function compute_bounds(ss::SampleSpace, 
constraints::Vector{PMFConstraint}, 
query::ProbabilityExpression)

    model = JuMP.Model(Ipopt.Optimizer)

    @variable(model, 0 <= pmf_table[ss.var_index] <= 1)
    @constraint(model, sum(pmf_table[i] for i in ss.var_index) == 1.0)
    for c in constraints
        jump_constraint(model, c, pmf_table, ss)
    end
    query_prob = prob(query, pmf_table, ss)
    @objective(model, Min, query_prob)
    optimize!(model)
    lb = objective_value(model)

    @show ">>>>>>>>>>>>>>>>>>>>>>>>>> LB"
    @show solution_summary(model)
    optimal_solve = true
    termination_status(model) == JuMP.OPTIMAL || (optimal_solve = false)

    @objective(model, Max, query_prob)
    optimize!(model)
    ub = objective_value(model)

    @show "UB"
    @show solution_summary(model)

    termination_status(model) == JuMP.OPTIMAL || (optimal_solve = false)

    if optimal_solve
        p = [lb, ub]
    else
        p = nothing
    end

    return p
end