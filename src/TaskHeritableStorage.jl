module TaskHeritableStorage # end

export task_heritable_storage

const heritable_storage_name = Symbol("##__nhdaly-task_heritable_storage__##")
task_heritable_storage() = get!(task_local_storage(), heritable_storage_name, IdDict{Any,Any}())
_has_task_heritable_storage() = haskey(task_local_storage(), heritable_storage_name)

function _copy_task_heritable_storage(dict)
    task_local_storage()[heritable_storage_name] = copy(dict)
end

# DANGEROUS: Override the Core Task() constructor to copy the task heritable storage
@warn "About to replace Core._Task() definition, to enable TaskHeritableStorage. The following warning is expected:"
#  EEP: type-piracy!  (In the future, this would be implemented in julia itself) ☠️
function __Task(@nospecialize(f), reserved_stack::Int, completion_future)
    return ccall(:jl_new_task, Ref{Task}, (Any, Any, Int), f, completion_future, reserved_stack)
end
function Core._Task(@nospecialize(f), reserved_stack::Int, completion_future)
    if _has_task_heritable_storage()
        let storage = task_heritable_storage()
            wrapped = () -> begin
                _copy_task_heritable_storage(storage);
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
    task_heritable_storage(body, key, value)

Call the function `body` with a modified task-heritable storage, in which `value` is assigned to
`key`; the previous value of `key`, or lack thereof, is restored afterwards.
"""
function task_heritable_storage(body::Function, key, val)
    tls = task_heritable_storage()
    hadkey = haskey(tls, key)
    old = get(tls, key, nothing)
    tls[key] = val
    try
        return body()
    finally
        hadkey ? (tls[key] = old) : delete!(tls, key)
    end
end

end
