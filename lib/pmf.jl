
Base.isempty(js::JointSpec) = Base.isempty(js.spec)
vars(js::JointSpec) = sort(collect(keys(js.spec)))
vals(js::JointSpec) = getindex.(Ref(js.spec), vars(js))



function agrees(js::JointSpec, constraint::JointSpec)
    common_vars = intersect(vars(js), vars(constraint))
    isempty(common_vars) && return true
    return getindex.(Ref(js.spec), common_vars) == getindex.(Ref(constraint.spec), common_vars)
end

merge(js1::JointSpec, js2::JointSpec) = JointSpec([vars(js1); vars(js2)], [vals(js1); vals(js2)])

function _all_joint_specs(n_var, vars)
    spec_vec = []
    for i in 0:(2^n_var-1)
        spec = JointSpec(vars, collect(Bool.(digits(i, base=2, pad=n_var))))
        push!(spec_vec, spec)
    end
    return spec_vec
end

function prob(joint_spec::JointSpec, pmf_table, ss::SampleSpace)
    isempty(joint_spec) && return 1.0
    idx_vec = [s for s in ss.var_index if agrees(s, joint_spec)]

    @show "-----=-----------------"
    @show joint_spec
    @show idx_vec

    return sum(pmf_table[idx] for idx in idx_vec)
end

function prob(joint_spec::JointSpec, condition_spec::JointSpec, 
            pmf_table, ss::SampleSpace)

    !agrees(joint_spec, condition_spec) && return 0.0

    full_joint_spec = merge(joint_spec, condition_spec)

    den = prob(condition_spec, pmf_table, ss)
    num = prob(full_joint_spec, pmf_table, ss)

    den == 0.0 && error("Condition probability exactly zero.")
    return  num/den         
end

prob(pe::ProbabilityExpression, pmf_table, ss::SampleSpace) = 
        prob(pe.joint_spec, pe.condition_spec, pmf_table, ss)

function maxent(ss::SampleSpace, 
                constraints::Vector{PMFConstraint}, 
                query::ProbabilityExpression) 
    
    model = JuMP.Model(Ipopt.Optimizer)

    @variable(model, 0 <= pmf_table[ss.var_index] <= 1)
    @constraint(model, sum(pmf_table[i] for i in ss.var_index) == 1.0)
    for c in constraints
        @show "xxxxxxxxxxxxxxxxxxxxxxxxxxx"
        @show c
        terms = term_wise_prob(c, pmf_table, ss)
        @show terms
        if terms.direction == eq 
            @constraint(model, terms.num == terms.rhs * terms.den)
        elseif c.direction == leq 
            @constraint(model, terms.num <= terms.rhs * terms.den)
        else
            @constraint(model, terms.num >= terms.rhs * terms.den)         
        end
    end
    @objective(model, Min, sum(log.(pmf_table[i]) .* pmf_table[i] for i in ss.var_index))
    optimize!(model)
    print(model)

    @show termination_status(model), JuMP.OPTIMAL
    termination_status(model) == JuMP.OPTIMAL || termination_status(model) == JuMP.LOCALLY_SOLVED || return nothing

    maxent_pmf_table = value.(pmf_table)
    query_prob = prob(query, maxent_pmf_table, ss)
    @show ">>>>>>>>>>>>>>>>>>>>>>>>>> Max Ent"
    @show solution_summary(model)
    
    print(model)
    return query_prob
end

function compute_bounds(ss::SampleSpace, 
    constraints::Vector{PMFConstraint}, 
    query::ProbabilityExpression)

    model = JuMP.Model(Ipopt.Optimizer)

    @variable(model, 0 <= pmf_table[ss.var_index] <= 1)
    @constraint(model, sum(pmf_table[i] for i in ss.var_index) == 1.0)
    for c in constraints
        terms = term_wise_prob(c, pmf_table, ss)
        if terms.direction == eq 
            @constraint(model, terms.num == terms.rhs * terms.den)
        elseif c.direction == leq 
            @constraint(model, terms.num <= terms.rhs * terms.den)
        else
            @constraint(model, terms.num >= terms.rhs * terms.den)         
        end
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