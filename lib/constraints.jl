
function term_wise_prob(pc::PMFConstraint{Float64}, pmf_table, ss::SampleSpace)
    num = prob(pc.lhs.joint_spec, pmf_table, ss)
    den = prob(pc.lhs.condition_spec, pmf_table, ss)
    return (num=num, den=den, rhs=pc.rhs, direction=pc.direction)
end


prob(x::Float64, ::Any, ::SampleSpace) = x