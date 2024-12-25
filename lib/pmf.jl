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
    return sum(pmf_table[idx] for idx in idx_vec)
end

function prob(joint_spec::JointSpec, condition_spec::JointSpec, 
            pmf_table, ss::SampleSpace)
    num, den = prob_terms(joint_spec, condition_spec, pmf_table, ss)
    den == 0.0 && error("Condition probability exactly zero.")
    return  num/den         
end

function prob_terms(joint_spec::JointSpec, condition_spec::JointSpec, 
    pmf_table, ss::SampleSpace)

    !agrees(joint_spec, condition_spec) && return (num=0.0, den=1.0)

    full_joint_spec = merge(joint_spec, condition_spec)

    den = prob(condition_spec, pmf_table, ss)
    num = prob(full_joint_spec, pmf_table, ss)

    return  (num = num, den = den)         
end

prob(pe::ProbabilityExpression, pmf_table, ss::SampleSpace) = 
        prob(pe.joint_spec, pe.condition_spec, pmf_table, ss)

prob_terms(pe::ProbabilityExpression, pmf_table, ss::SampleSpace) = 
        prob_terms(pe.joint_spec, pe.condition_spec, pmf_table, ss)

