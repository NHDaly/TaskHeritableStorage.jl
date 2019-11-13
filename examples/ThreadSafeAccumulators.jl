module ThreadSafeAccumulators #end

export Accumulator

"""
    Accumulator{T}
A thread-safe, push-only vector abstraction.
Collecting the results should only be done with all threads have finished pushing.

# Examples:
```julia
julia> a = Accumulator();

julia> for i in 1:5
           Threads.@spawn push!(a, i)
       end

julia> collect(a)
5-element Array{Any,1}:
 4
 5
 2
 1
 3
```
"""
struct Accumulator{T}
    nvectors::NTuple{Threads.nthreads(), Vector{T}}
    Accumulator{T}() where T = new{T}(Tuple(T[] for _ in 1:Threads.nthreads()))
end
Accumulator() = Accumulator{Any}()

Base.collect(a::Accumulator) = vcat(a.nvectors...)
Base.push!(a::Accumulator, v...) = (push!(a.nvectors[Threads.threadid()], v...); a)


# Construct from existing collections
Base.convert(t::Type{Accumulator}, collection) = t(collection)
Base.convert(t::Type{<:Accumulator}, x::Accumulator{S}) where {S} = t(collect(x))
Accumulator(collection) = Accumulator{eltype(collection)}(collection)
function Accumulator{T}(collection) where T
    a = Accumulator{T}()
    push!(a, collection...)
end

# Helpers
Base.eltype(::Type{Accumulator{T}}) where T = T

end
