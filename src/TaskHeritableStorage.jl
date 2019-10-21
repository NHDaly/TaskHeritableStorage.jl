module TaskHeritableStorage # end

export task_heritable_storage

const heritable_storage_name = Symbol("##__nhdaly-task_heritable_storage__##")
task_heritable_storage() = get!(task_local_storage(), heritable_storage_name, IdDict{Any,Any}())

function _copy_task_heritable_storage(dict)
    task_local_storage()[heritable_storage_name] = copy(dict)
end
# _copy_task_heritable_storage(Dict())

# DANGEROUS: Override the Core Task() constructor to copy the task heritable storage
@warn "About to replace Core._Task() definition, to enable TaskHeritableStorage. The following warning is expected:"
#  EEP: type-piracy!  (In the future, this would be implemented in julia itself) ☠️
function __Task(@nospecialize(f), reserved_stack::Int, completion_future)
    return ccall(:jl_new_task, Ref{Task}, (Any, Any, Int), f, completion_future, reserved_stack)
end
function Core._Task(@nospecialize(f), reserved_stack::Int, completion_future)
    let storage = task_heritable_storage()
        wrapped = () -> begin
            _copy_task_heritable_storage(storage);
            f();
        end
        return __Task(wrapped, reserved_stack, completion_future)
    end
end

# The below macros aren't needed, because we want to implement this in the core Task()
# constructor so that it _always happens_.

#macro h_spawn(expr)
#    # Get the users current task_heritable_storage dict, and copy it into the new task's.
#    expr = :(
#        $_copy_task_heritable_storage($(task_heritable_storage()));
#        $expr;
#    )
#    esc(:( @spawn $expr ))
#end
#macro h_async(expr)
#    # Get the users current task_heritable_storage dict, and copy it into the new task's.
#    expr = :(
#        $_copy_task_heritable_storage($(task_heritable_storage()));
#        $expr;
#    )
#    esc(:( @async $expr ))
#end

end
