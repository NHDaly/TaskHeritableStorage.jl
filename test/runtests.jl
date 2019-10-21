include("../src/TaskHeritableStorage.jl")  # Load the module (overrides Task() constructor)

include("TaskHeritableStorage.jl")
include("MultiTest.jl")  # Note that this currently modifies Test.@testset behavior
