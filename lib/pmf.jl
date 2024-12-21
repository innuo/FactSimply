
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
    #Main.@infiltrate
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
        if c.direction == eq 
            @constraint(model, prob(c.lhs, pmf_table, ss) == prob(c.rhs, pmf_table, ss))
        elseif c.direction == leq 
            @constraint(model, prob(c.lhs, pmf_table, ss) <= prob(c.rhs, pmf_table, ss))
        else
            @constraint(model, prob(c.lhs, pmf_table, ss) >= prob(c.rhs, pmf_table, ss))           
        end
    end
    @objective(model, Min, sum(log.(pmf_table[i]) .* pmf_table[i] for i in ss.var_index))
    optimize!(model)
    maxent_pmf_table = value.(pmf_table)
    query_prob = prob(query, maxent_pmf_table, ss)
    @show solution_summary(model)
    @show "=="
    print(maxent_pmf_table)
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

    @objective(model, Max, query_prob)
    optimize!(model)
    ub = objective_value(model)

    return (lb, ub)
end