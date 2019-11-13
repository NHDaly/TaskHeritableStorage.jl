module TaskHeritableStorageTests #end

using Test

using TaskHeritableStorage

# Examples
struct ShallowCopyKey{sym} end
TaskHeritableStorage.fork_task_local_storage(k::ShallowCopyKey, v) = (k,v)

const key = ShallowCopyKey{:tls}()

fetch(@async begin  # Put each test in its own Task so they don't share a task_heritable_storage
    task_local_storage()[key] = 5
    fetch(@async begin
        @test task_local_storage()[key] == 5
    end)
end)

@testset "assigning doesn't affect parent tasks" begin
    @sync @async begin
        task_local_storage()[key] = 1
        @sync @async begin
            @test task_local_storage()[key] == 1

            # Update it to 2 within this Task
            task_local_storage()[key] = 2
            @test task_local_storage()[key] == 2
        end
        # In the parent task, the value is still 1
        @test task_local_storage()[key] == 1
    end
    # In the outermost task, the value was never set
    @test !haskey(task_local_storage(), key)
end

@testset "callbacks" begin
    # Dummy function that "uses concurrency" when sorting
    function psort(args...; kwargs...)
        fetch(@async sort(args...; kwargs...))
    end

    @testset "PROBLEM: normal task_local_storage isn't composable" begin
        task_local_storage()[:reverse] = false
        reversed() = task_local_storage()[:reverse]

        less_than = (a,b) -> reversed() ? a>b : a<b
        # All good, we can access this task_local_storage
        @test sort(1:10, lt=less_than) == 1:10

        # SURPRISE: the author of sort decides to parallelize it (represented via `psort`)!
        @test_throws Exception psort(1:10, lt=less_than) == 1:10
        # The error is a KeyError, because :reverse is no longer in the task_local_storage:
        e = try                          psort(1:10, lt=less_than) == 1:10; catch e; e end
        @static if VERSION >= v"1.3-"
            @test e.task.exception == KeyError(:reverse)
        else
            @test e == KeyError(:reverse)
        end  # VERSION
    end

    @testset "SOLUTION: Using a `fork_task_local_storage()` override _is_ composable" begin
        reversekey = ShallowCopyKey{:reverse}()

        task_local_storage()[reversekey] = false
        reversed() = task_local_storage()[reversekey]

        less_than = (a,b) -> reversed() ? a>b : a<b
        @test sort(1:10, lt=less_than) == 1:10

        # NOW, if the author of sort wants to parallelize it, everything is *okay*! :)
        @test psort(1:10, lt=less_than) == 1:10
    end
end

@testset "functional interface" begin
    @test haskey(task_local_storage(), key) == false
    task_local_storage(key, 1) do
        # Same Task
        @test task_local_storage()[key] == 1
        # Nested Task
        @test fetch(@async task_local_storage()[key]) == 1
    end
    # Storage removed after the function returns
    @test haskey(task_local_storage(), key) == false
end

end
