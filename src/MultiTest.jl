module MultiTest
using ..TaskHeritableStorage

const THS = TaskHeritableStorage

# Override @testset to use task-heritable storage
import Test

@eval Test begin
    #-----------------------------------------------------------------------
    # Various helper methods for test sets

    function get_testset()
        testsets = get($THS.task_heritable_storage(), :__BASETESTNEXT__, AbstractTestSet[])
        return isempty(testsets) ? fallback_testset : testsets[end]
    end

    function push_testset(ts::AbstractTestSet)
        testsets = get($THS.task_heritable_storage(), :__BASETESTNEXT__, AbstractTestSet[])
        push!(testsets, ts)
        setindex!($THS.task_heritable_storage(), testsets, :__BASETESTNEXT__)
    end

    function pop_testset()
        testsets = get($THS.task_heritable_storage(), :__BASETESTNEXT__, AbstractTestSet[])
        ret = isempty(testsets) ? fallback_testset : pop!(testsets)
        setindex!($THS.task_heritable_storage(), testsets, :__BASETESTNEXT__)
        return ret
    end

    function get_testset_depth()
        testsets = get($THS.task_heritable_storage(), :__BASETESTNEXT__, AbstractTestSet[])
        return length(testsets)
    end
end

end
