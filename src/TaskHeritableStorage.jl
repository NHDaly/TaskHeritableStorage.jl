module TaskHeritableStorage # end

"""
    fork_task_local_storage(key, value) -> (key,value) or nothing

Whenever a new `Task` is created, all `(key,value)` pairs in the parent Task's
`task_local_storage` are passed to this function, which gives a chance to _fork_ those pairs
into the new child `Task`'s task local storage.

Whatever new `(key, value)` pair is returned will be inserted into the new Task's
`task_local_storage`. If `nothing` is returned, the child Task's storage will not be
modified. This is the default behavior.

This function is called from inside the newly created `Task` before anything else happens,
so within this function `current_task()` will return the new Task.
"""
function fork_task_local_storage(key, value)
    nothing
end


# ----------------------
# Replace the definition of Core._Task() to clone task_heritable_storage on construction.

function _fork_task_local_storage_from_parent(parent_tls)
    tls = task_local_storage()
    # Fork all (k,v) pairs from the parent's TLS into this task's TLS
    for (k, v) in parent_tls
        out = fork_task_local_storage(k,v)
        if out !== nothing
            (newkey, newval) = out
            tls[newkey] = newval
        end
    end
end

# DANGEROUS: Override the Core Task() constructor to copy the task heritable storage
@warn "About to replace Core._Task() definition, to enable TaskHeritableStorage. The following warning is expected:"
#  EEP: type-piracy!  (In the future, this would be implemented in julia itself) ☠️
function __Task(@nospecialize(f), reserved_stack::Int, completion_future)
    return ccall(:jl_new_task, Ref{Task}, (Any, Any, Int), f, completion_future, reserved_stack)
end
function Core._Task(@nospecialize(f), reserved_stack::Int, completion_future)
    if current_task().storage !== nothing
        let parent_tls = task_local_storage()
            wrapped = () -> begin
                _fork_task_local_storage_from_parent(parent_tls);
                f();
            end
            return __Task(wrapped, reserved_stack, completion_future)
        end
    else
        return __Task(f, reserved_stack, completion_future)
    end
end


end
