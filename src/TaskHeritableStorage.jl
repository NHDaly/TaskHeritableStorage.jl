module TaskHeritableStorage # end

export task_heritable_storage, @task_heritable_storage

const _heritable_storage_name = Symbol("##__nhdaly-task_heritable_storage__##")

"""
    task_heritable_storage(m::Module)[:key] = value
    @task_heritable_storage()[:key] = value
"""
function task_heritable_storage(m::Module)
    get!(_task_heritable_storage_all_modules(), m, IdDict{Any,Any}())
end
_task_heritable_storage_all_modules() = get!(task_local_storage(), _heritable_storage_name, IdDict{Module,Any}())

"""
    @task_heritable_storage()[:key] = value
This is simply a synonym for [`task_heritable_storage(@__MODULE__)`](@ref).
"""
macro task_heritable_storage()
    :(task_heritable_storage($__module__))  # No esc needed, since no user inputs
end

# ----------------------
# Replace the definition of Core._Task() to clone task_heritable_storage on construction.

function _has_task_heritable_storage(m::Module)
    haskey(task_local_storage(), _heritable_storage_name) &&
        haskey(_task_heritable_storage_all_modules(), m)
end

function _clone_task_heritable_storage(dict)
    task_local_storage()[_heritable_storage_name] = copy(dict)
end

# DANGEROUS: Override the Core Task() constructor to copy the task heritable storage
@warn "About to replace Core._Task() definition, to enable TaskHeritableStorage. The following warning is expected:"
#  EEP: type-piracy!  (In the future, this would be implemented in julia itself) ☠️
function __Task(@nospecialize(f), reserved_stack::Int, completion_future)
    return ccall(:jl_new_task, Ref{Task}, (Any, Any, Int), f, completion_future, reserved_stack)
end
function Core._Task(@nospecialize(f), reserved_stack::Int, completion_future)
    if haskey(task_local_storage(), _heritable_storage_name)
        let all_storage = _task_heritable_storage_all_modules()
            wrapped = () -> begin
                _clone_task_heritable_storage(all_storage);
                f();
            end
            return __Task(wrapped, reserved_stack, completion_future)
        end
    else
        return __Task(f, reserved_stack, completion_future)
    end
end


# -------- Convenience APIs ----------------
"""
    task_heritable_storage(m::Module, key, value) do ... end
    @task_heritable_storage(key, value) do ... end

Call the function `body` with a modified task-heritable storage, in which `value` is assigned to
`key`; the previous value of `key`, or lack thereof, is restored afterwards.
"""
function task_heritable_storage(body::Function, m::Module, key, val)
    tls = task_heritable_storage(m)
    hadkey = haskey(tls, key)
    old = get(tls, key, nothing)
    tls[key] = val
    try
        return body()
    finally
        hadkey ? (tls[key] = old) : delete!(tls, key)
    end
end

"""
    @task_heritable_storage(key, value) do ... end

This is simply a synonym for [`task_heritable_storage(@__MODULE__, key, val)`](@ref).
"""
macro task_heritable_storage(body::Function, key, val)
    esc(:($task_heritable_storage(body, $__module__, key, val)))
end


end