module Tracing #end

export tracetasks, @tracetasks

using TaskHeritableStorage

include("ThreadSafeAccumulators.jl")
using .ThreadSafeAccumulators

# Key for Task Local Storage
struct TraceTLSKey
    id::Int  # Use a unique TLS key for each trace to allow composable tracing
    TraceTLSKey() = new(traceid[] += 1)
end
traceid = Threads.Atomic{Int}(0)
struct TraceTLSValue
    task_edges::Accumulator{Pair{Task,Task}}
    parent_task::Task  # Set to current_task()
    TraceTLSValue() = new(Accumulator([(current_task() => current_task())]), current_task())
    TraceTLSValue(edges, task) = new(edges, task)
end

function TaskHeritableStorage.fork_task_local_storage(k, v::TraceTLSValue)
    # It is thread-safe to push! to an Accumulator
    push!(v.task_edges, v.parent_task => current_task())
    # Fork a new "current task", but share the same edges accumulator:
    (k, TraceTLSValue(v.task_edges, current_task()))
end


"""
    @tracetasks expr

Equivalent to tracetasks() do ; expr; end
"""
macro tracetasks(e)
    :(tracetasks(()->$(esc(e))))
end

"""
    @tracetasks expr
    tracetasks() do ; end
    tracetasks(f::Function)

Run a function and trace all tasks that are spawned during its execution.
Returns an Array of pairs from `parent_task => child_task`. The root task is represented
with a special self-edge `t => t`.
"""
function tracetasks(f::Function)
    tls = task_local_storage()
    key = TraceTLSKey()
    task_local_storage(key, TraceTLSValue()) do
        f()
        return collect(task_local_storage()[key].task_edges)
    end
end

end  # module
