using TaskHeritableStorage  # Load the module (overrides Task() constructor)

include("TaskHeritableStorage.jl")

# Examples
include("MultiTest.jl")  # Note that this currently modifies Test.@testset behavior
