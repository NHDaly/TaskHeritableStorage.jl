module TaskHeritableStorageTests #end

using Test

using ..TaskHeritableStorage

# Examples
fetch(@async begin  # Put each test in its own Task so they don't share a task_heritable_storage
    @task_heritable_storage()[:current_testset] = 5
    fetch(@async begin
        @test @task_heritable_storage()[:current_testset] == 5
    end)
end)

fetch(@async begin
    @test TaskHeritableStorage._has_task_heritable_storage(@__MODULE__) == false
    @task_heritable_storage()[:x] = 1
    @test TaskHeritableStorage._has_task_heritable_storage(@__MODULE__) == true
    @test fetch(@async TaskHeritableStorage._has_task_heritable_storage(@__MODULE__)) == true
end)

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
        @test_throws TaskFailedException psort(1:10, lt=less_than) == 1:10
        # The error is a KeyError, because :reverse is no longer in the task_local_storage:
        e = try                          psort(1:10, lt=less_than) == 1:10; catch e; e end
        @test e.task.exception == KeyError(:reverse)
    end

    @testset "SOLUTION: task_heritable_storage is composable" begin
        @task_heritable_storage()[:reverse] = false
        reversed() = @task_heritable_storage()[:reverse]

        less_than = (a,b) -> reversed() ? a>b : a<b
        @test sort(1:10, lt=less_than) == 1:10

        # NOW, if the author of sort wants to parallelize it, everything is *okay*! :)
        @test psort(1:10, lt=less_than) == 1:10
    end
end

@testset "functional interface" begin
    @test haskey(@task_heritable_storage(), :x) == false
    @task_heritable_storage(:x, 1) do
        # Same Task
        @test @task_heritable_storage()[:x] == 1
        # Nested Task
        @test fetch(@async @task_heritable_storage()[:x]) == 1
    end
    # Storage removed after the function returns
    @test haskey(@task_heritable_storage(), :x) == false
end

end
