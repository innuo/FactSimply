(pwd() != @__DIR__) && cd(@__DIR__) # allow starting app from bin/ dir

using FactSimply
const UserApp = FactSimply
FactSimply.main()
