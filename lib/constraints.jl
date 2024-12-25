
function jump_constraint(model, pc::PMFConstraint, pmf_table, ss::SampleSpace)
    plhs = prob(pc.lhs, pmf_table, ss)
    prhs = prob(pc.rhs, pmf_table, ss)

    if pc.direction == eq 
        @constraint(model, plhs == prhs)
    elseif pc.direction == leq 
        @constraint(model, plhs <= prhs)
    else
        @constraint(model, plhs >= prhs)         
    end
end


function jump_constraint(model, pc::PMFConstraint{Float64}, pmf_table, ss::SampleSpace)
    num, den = prob_terms(pc.lhs.joint_spec, pc.lhs.condition_spec, pmf_table, ss)
    if pc.direction == eq 
        @constraint(model, num == pc.rhs * den)
    elseif pc.direction == leq 
        @constraint(model, num <= pc.rhs * den)
    else
        @constraint(model,  num >= pc.rhs * den)         
    end
end
