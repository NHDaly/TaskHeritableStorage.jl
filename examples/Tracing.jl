module Tracing #end

export clear_traces, trace, get_traces

using TaskHeritableStorage

include("ThreadSafeAccumulators.jl")
using .ThreadSafeAccumulators

function clear_traces()
    global task_traces = Accumulator()
    global func_traces = Accumulator()
end
clear_traces()

function trace()
    ths = @task_heritable_storage()
    # If this is the first time tracing this Task, update the current task
    get!(task_local_storage(), (@__MODULE__, :task_is_traced)) do
        parent = get!(ths, :current_task, nothing)
        current = ths[:current_task] = current_task()
        push!(task_traces, (parent, current))
        true
    end

    push!(func_traces, (ths[:current_task], Base.stacktrace()))
end

function get_traces()
    collect(task_traces), collect(func_traces)
end

end
