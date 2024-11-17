
function term_wise_prob(pc::PMFConstraint{Float64}, pmf_table, ss::SampleSpace)
    num = prob(pc.lhs.joint_spec, pmf_table, ss)
    den = prob(pc.lhs.condition_spec, pmf_table, ss)
    return (num=lhs, den=rhs, direction=pc.direction)
end


prob(x::Float64, ::Any, ::SampleSpace) = x