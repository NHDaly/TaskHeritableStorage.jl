module MultiTestRuntests #end

using TaskHeritableStorage

# Test the behavior in MultiTest.jl to override Test.@testset to track nested parallel tests
# NOTE: This overrides the behavior of Test functions
include("../examples/MultiTest.jl")

using Test
#using Testy.JuliaTestModified

@testset "" begin
    @test true
end

# Test that the now-fixed Test.TestSets do correctly embed their nested testsets
begin
    t = @testset "outer" begin
        @sync begin
            @async begin
                @testset "inner1" begin
                    @test true
                end
            end
            @async begin
                @testset "inner2" begin
                    @test true
                end
            end
        end
    end

    @show t.results
    @test length(t.results) == 2
end

if VERSION >= v"1.3-"
    @show Threads.nthreads()

    # Test that Testsets now work correctly across multiple threads
    @testset "outerest" begin
      @testset "outerer$i" for i in 1:3
        t = @testset "outer" begin
            @sync begin
                Threads.@spawn begin
                    @testset "inner" begin
                        @test true
                    end
                end
                Threads.@spawn begin
                    @testset "inner2" begin
                        @test true
                    end
                end
            end
        end

        @test length(t.results) == 2
      end
    end

end  # if julia 1.3

end # module
