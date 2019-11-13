using TaskHeritableStorage  # Load the module (overrides Task() constructor)

using Test

@testset "TaskHeritableStorage" begin
    include("TaskHeritableStorage.jl")

    # Examples
    include("ThreadSafeAccumulators.jl")
    include("Tracing.jl")
    # NOTE: MultiTest.jl currently modifies Test.@testset behavior, so keep it last:
    include("MultiTest.jl")
end
