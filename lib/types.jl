using JuMP
using Ipopt
using HiGHS
using Logging

Base.@kwdef mutable struct JointSpec
    spec::Dict{Symbol, Bool}
end
JointSpec(vars::Vector{Symbol}, vals::Vector{Bool}) = JointSpec(Dict(vars .=> vals))


Base.@kwdef mutable struct SampleSpace
    n_var::Int = length(vars)
    vars::Vector{Symbol}
    var_index::Vector{JointSpec} 
end

@enum Direction leq=1 geq=-1 eq=0 

Base.@kwdef mutable struct ProbabilityExpression
    joint_spec::JointSpec
    condition_spec::JointSpec = JointSpec()
end

Base.@kwdef mutable struct PMFConstraint{P<:Union{Float64,ProbabilityExpression}}
    lhs::ProbabilityExpression
    rhs::P
    direction::Direction
    function PMFConstraint(lhs, rhs, direction)
        if rhs isa Float64
            rhs = clamp(rhs, 0.0, 1.0)   
        end
        return new{typeof(rhs)}(lhs, rhs, direction)
    end
end

export JointSpec, ProbabilityExpression, PMFConstraint