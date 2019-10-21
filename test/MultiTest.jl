include("../src/TaskHeritableStorage.jl")

# Test the behavior in MultiTest.jl to override Test.@testset to track nested parallel tests
# NOTE: This overrides the behavior of Test functions
include("../src/MultiTest.jl")

using Test

# Test that the now-fixed Test.TestSets do correctly embed their nested testsets
begin
    t = @testset "outer" begin
        @sync begin
            @async begin
                @testset "inner" begin
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

    @test length(t.results) == 2
end
