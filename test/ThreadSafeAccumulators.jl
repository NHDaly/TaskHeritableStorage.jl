module ThreadSafeAccumulatorsRuntests

using Test
include("../examples/ThreadSafeAccumulators.jl")
using .ThreadSafeAccumulators

@test collect(Accumulator()) == Any[]
@test collect(Accumulator{Int}()) == Int[]
@test collect(push!(Accumulator{Int}(), 2)) == [2]
@test collect(push!(push!(Accumulator{Int}(), 1,2),3,4)) == 1:4
# constructors / convert
@test collect(Accumulator([])) == collect(Accumulator())
@test collect(Accumulator([1,2,3])) == 1:3
@test collect(Accumulator{Float64}([1])) == Float64[1]

@test eltype(Accumulator{Int}()) == Int
@test eltype(Accumulator([1,2,3])) == Int

end
