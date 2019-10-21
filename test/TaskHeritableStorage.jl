module TaskHeritableStorageTests

using Test

using ..TaskHeritableStorage

# Example
begin
    task_heritable_storage()[:current_testset] = 5
    fetch(@async begin
        @test task_heritable_storage()[:current_testset] == 5
    end)
end

@testset "callbacks" begin
    # Dummy function that "uses concurrency" when sorting
    function psort(args...; kwargs...)
        fetch(@async sort(args...; kwargs...))
    end

    @testset "PROBLEM: task_local_storage isn't composable" begin
        task_local_storage()[:reverse] = false
        reversed() = task_local_storage()[:reverse]

        less_than = (a,b) -> reversed() ? a>b : a<b
        # All good, we can access this task_local_storage
        @test sort(1:10, lt=less_than) == 1:10

        # SURPRISE: the author of sort decides to parallelize it (represented via `psort`)!
        @test_throws KeyError(:reverse) psort(1:10, lt=less_than) == 1:10
    end

    @testset "SOLUTION: task_heritable_storage is composable" begin
        task_heritable_storage()[:reverse] = false
        reversed() = task_heritable_storage()[:reverse]

        less_than = (a,b) -> reversed() ? a>b : a<b
        @test sort(1:10, lt=less_than) == 1:10

        # NOW, if the author of sort wants to parallelize it, everything is *okay*! :)
        @test psort(1:10, lt=less_than) == 1:10
    end
end

end
