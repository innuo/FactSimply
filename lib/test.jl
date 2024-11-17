
ss = SampleSpace([:a, :b])

pe1 = ProbabilityExpression(joint_spec=JointSpec([:a], [true]))
pe2 = ProbabilityExpression(joint_spec=JointSpec([:b], [true]))
pe3 = ProbabilityExpression(joint_spec=JointSpec([:a, :b], [true, true]))

c1 = PMFConstraint(lhs = pe1, rhs = 0.7, direction=FactSimply.eq)
c2 = PMFConstraint(lhs = pe2, rhs = 0.8, direction=FactSimply.eq)
q = pe3

FactSimply.maxent(ss, [c1, c2], q)