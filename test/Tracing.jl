module TracingTests #end

include("../examples/Tracing.jl")
using .Tracing

begin
    trace()
    tasks, funcs = get_traces()
    @info tasks
    @info funcs
end

begin
    clear_traces()
    trace()
    Threads.@spawn begin
        trace()
        Threads.@spawn begin
            trace()
        end
        Threads.@spawn begin
            trace()
        end
    end

    tasks, funcs = get_traces()
    @info tasks
    @info funcs
end

end
