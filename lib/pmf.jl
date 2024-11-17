
Base.isempty(js::JointSpec) = Base.isempty(js.spec)
vars(js::JointSpec) = sort(keys(js.spec))
vals(js::JointSpec) = getindex.(Ref(js.spec), vars(js))

function agrees(js::JointSpec, constraint::JointSpec)
    common_vars = intersect(js.vars, constraint.vars)
    isempty(common_vars) && return true
    return getindex.(Ref(js.spec), common_vars) == getindex.(Ref(constraint.spec), common_vars)
end

merge(js1::JointSpec, js2::JointSpec) = JointSpec([vars(js1), vars(js2)], [vals(js1), vals(js2)])

function SampleSpace(variable_names)
    vars = sort(Symbol.(variable_names))
    n_var = length(vars)
    var_index = _all_joint_specs(n_var, vars)
    return SampleSpace(n_var, vars, var_index)
end

function _all_joint_specs(n_var, vars, constraint = JointSpec())
    spec_vec = []
    for i in 0:(2^n_var-1)
        spec = JointSpec(vars, Bool.(digits(i, base=2, pad=n_var)))
        !agrees(spec, constraint) && continue
        push!(spec_vec, spec)
    end
    return spec_vec
end



function prob(joint_spec::JointSpec, pmf_table::Dict{JointSpec, Float64}, ss::SampleSpace)
    isempty(joint_spec) && return 1.0
    idx_vec =_all_joint_specs(ss.n_var, ss.vars, joint_spec)
    return sum(pmf_table[idx] for idx in idx_vec)
end

function prob(joint_spec::JointSpec, condition_spec::JointSpec, 
            pmf_table::Dict{JointSpec, Float64}, ss::SampleSpace)

    !agrees(joint_spec, condition_spec) && return 0.0

    full_joint_spec = merge(joint_spec, condition_spec)

    den = prob(condition_spec, pmf_table, ss)
    num = prob(full_joint_spec, pmf_table, ss)

    den == 0.0 && error("Condition probability exactly zero.")
    return  num/den         
end

prob(pe::ProbabilityExpression, pmf_table::Dict{JointSpec, Float64}, ss::SampleSpace) = 
        prob(pe.joint_spec, pe.condition_spec, pmf_table, ss)

function maxent(ss::SampleSpace, 
                constraints::Vector{PMFConstraint}, 
                query::ProbabilityExpression)
    
    model = JuMP.model(Ipopt.Optimizer)
    
    @variable(model, 0 <= pmf[ss.var_index] <= 1)
    for c in constraints
        if c.direction == Direction.eq 
            @constraint(model, prob(c.lhs, pmf_table, ss) == prob(c.rhs, pmf_table, ss))
        elseif c.direction == Direction.leq 
            @constraint(model, prob(c.lhs, pmf_table, ss) <= prob(c.rhs, pmf_table, ss))
        else
            @constraint(model, prob(c.lhs, pmf_table, ss) >= prob(c.rhs, pmf_table, ss))           
        end
    end
    @objective(model, Min, sum(log(pmf_table[i]) .* pmf_table[1] for i in ss.var_index))
    optimize!(model)
    maxent_pmf_table = value.(pmf_table)
    query_prob = prob(query, maxent_pmf_table, ss)
    return query_prob
end