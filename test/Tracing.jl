module TracingTests #end

include("../examples/Tracing.jl")
using .Tracing

@static if VERSION >= v"1.3-"
    import Base.Threads: @spawn
else
    macro spawn(e) esc(:(@async(e))) end
end

using Test

@testset "Tracing example" begin

    edges = tracetasks() do
        @sync begin
            @async begin
                # Embedded trace within the parent trace
                inneredges = @tracetasks 2+2
                @assert length(inneredges) == 1
            end
            Threads.@spawn begin
            end
        end
    end

    @test length(edges) == 3

end

end  # module
