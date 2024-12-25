"""
General constraint
"""
function jump_constraint!(model, pc::PMFConstraint, pmf_table, ss::SampleSpace)
    plhs = prob(pc.lhs, pmf_table, ss)
    prhs = prob(pc.rhs, pmf_table, ss)
    _add_constraint(model, plhs, prhs, pc.direction)
end

"""
rhs::Float64 type constraint
"""
function jump_constraint!(model, pc::PMFConstraint{Float64}, pmf_table, ss::SampleSpace)
    num, den = prob_terms(pc.lhs.joint_spec, pc.lhs.condition_spec, pmf_table, ss)
    _add_constraint(model, num, pc.rhs * den, pc.direction)
end

function _add_constraint(model, lhs, rhs, direction)
    if direction == eq 
        @constraint(model, lhs == rhs)
    elseif direction == leq 
        @constraint(model, lhs <= rhs)
    else
        @constraint(model,  lhs >= rhs)         
    end
end