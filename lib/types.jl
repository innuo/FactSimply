using JuMP
using SCS
using HiGHS
using Logging

Base.@kwdef mutable struct JointSpec
    spec::Dict{Symbol, Bool} = Dict{Symbol, Bool}()
end

JointSpec(vars::Vector{Symbol}, vals::BitVector) = JointSpec(vars, collect(vals))

function JointSpec(vars::Vector{Symbol}, vals::Vector{Bool}) 
    (length(vars) == 0 || length(vals) == 0 || length(vars) != length(vals)) && return JointSpec()
    return JointSpec(Dict(vars .=> vals))
end

Base.isempty(js::JointSpec) = Base.isempty(js.spec)
vars(js::JointSpec) = sort(collect(keys(js.spec)))
vals(js::JointSpec) = getindex.(Ref(js.spec), vars(js))

Base.@kwdef mutable struct SampleSpace
    n_var::Int = length(vars)
    vars::Vector{Symbol}
    var_index::Vector{JointSpec} 
end

function SampleSpace(variable_names)
    vars = sort(Symbol.(variable_names))
    n_var = length(vars)
    var_index = _all_joint_specs(n_var, vars)
    return SampleSpace(n_var, vars, var_index)
end

@enum Direction leq=1 geq=-1 eq=0 

Base.@kwdef mutable struct ProbabilityExpression
    joint_spec::JointSpec
    condition_spec::JointSpec = JointSpec()
end

vars(pe::ProbabilityExpression) = unique([vars(pe.joint_spec); vars(pe.condition_spec)])

Base.@kwdef mutable struct PMFConstraint{P}
    lhs::ProbabilityExpression
    rhs::P #either a Float64 or ProbabilityExpression
    direction::Direction
    function PMFConstraint(lhs, rhs, direction)
        if rhs isa Float64
            rhs = clamp(rhs, 0.0, 1.0)   
        end
        return new{typeof(rhs)}(lhs, rhs, direction)
    end
end

export SampleSpace, JointSpec, ProbabilityExpression, PMFConstraint, Direction