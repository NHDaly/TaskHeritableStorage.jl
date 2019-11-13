module TracingTests #end

include("../examples/Tracing.jl")
using .Tracing

@static if VERSION >= v"1.3-"
    import Base.Threads: @spawn
else
    macro spawn(e) esc(:(@async(e))) end
end

begin
    trace()
    tasks, funcs = get_traces()
    @info tasks
    @info funcs
end

begin
    clear_traces()
    trace()
    @spawn begin
        trace()
        @spawn begin
            trace()
        end
        @spawn begin
            trace()
        end
    end

    tasks, funcs = get_traces()
    @info tasks
    @info funcs
end

end
