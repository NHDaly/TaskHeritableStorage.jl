module MultiTest

using TaskHeritableStorage

const THS = TaskHeritableStorage

# Override @testset to use task-heritable storage
import Test

@eval Test begin
    #-----------------------------------------------------------------------
    # Various helper methods for test sets

#    function get_testset()
#        testsets = get($THS.@task_heritable_storage(), :__BASETESTNEXT__, AbstractTestSet[])
#        return isempty(testsets) ? fallback_testset : testsets[end]
#    end
#
#    function push_testset(ts::AbstractTestSet)
#        testsets = get($THS.@task_heritable_storage(), :__BASETESTNEXT__, AbstractTestSet[])
#        push!(testsets, ts)
#        setindex!($THS.@task_heritable_storage(), testsets, :__BASETESTNEXT__)
#    end
#
#    function pop_testset()
#        testsets = get($THS.@task_heritable_storage(), :__BASETESTNEXT__, AbstractTestSet[])
#        ret = isempty(testsets) ? fallback_testset : pop!(testsets)
#        setindex!($THS.@task_heritable_storage(), testsets, :__BASETESTNEXT__)
#        return ret
#    end
#
#    function get_testset_depth()
#        testsets = get($THS.@task_heritable_storage(), :__BASETESTNEXT__, AbstractTestSet[])
#        return length(testsets)
#    end

function get_testset()
    # Get the currently executing testset, falling back to those inherited from parent tasks
    testsets = get(task_local_storage(), :__BASETESTNEXT__,
                    # If not present in task_local_storage, read it from (potential) parent
                    get($THS.@task_heritable_storage(), :__BASETESTNEXT__, AbstractTestSet[]))
    return isempty(testsets) ? fallback_testset : testsets[end]
end

function push_testset(ts::AbstractTestSet)
    @info "push_testset(" ts ")"
    testsets = get(task_local_storage(), :__BASETESTNEXT__,
                    # If not present in task_local_storage, copy it from (potential) parent
                    get($THS.@task_heritable_storage(), :__BASETESTNEXT__, AbstractTestSet[]))
    # copy the array so we aren't modifying the parent Task's testsets
    testsets = copy(testsets)
    push!(testsets, ts)
    # Overwrite the binding so our child-tasks share this array.
    setindex!($THS.@task_heritable_storage(), testsets, :__BASETESTNEXT__)
    # Set the binding in task_local_storage as well, and use that from now on.
    setindex!(task_local_storage(), testsets, :__BASETESTNEXT__)
end

function pop_testset()
    @info "pop_testset()"
    @assert haskey(task_local_storage(), :__BASETESTNEXT__) """
        Programming Error: I misunderstand something; this should never happen.
        Trying to pop_testset() with nothing in task_local_storage()
        """
    testsets = get(task_local_storage(), :__BASETESTNEXT__, AbstractTestSet[])
    ret = isempty(testsets) ? fallback_testset : pop!(testsets)
    # Overwrite the binding so our child-tasks see the updated testsets
    setindex!($THS.@task_heritable_storage(), testsets, :__BASETESTNEXT__)
    # This line is copied from the old thing, but should be redundant
    setindex!(task_local_storage(), testsets, :__BASETESTNEXT__)
    return ret
end

function get_testset_depth()
    # Read from the inherited set of TestSets
    testsets = get(task_local_storage(), :__BASETESTNEXT__,
                    # If not present in task_local_storage, read it from (potential) parent
                    get($THS.@task_heritable_storage(), :__BASETESTNEXT__, AbstractTestSet[]))
    return length(testsets)
end

end

end
