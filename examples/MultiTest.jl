module MultiTest

# Override @testset to use task-heritable storage
import Test

@eval Test using TaskHeritableStorage
@eval Test begin
    #-----------------------------------------------------------------------
    # Various helper methods for test sets

    # Update Test helper methods to store the stack of active testsets in Task Heritable
    # Storage instead of in task_local_storage, which makes Test support concurrent testsets.

    # This is not enough to make them *thread-safe*, since the `results` array in
    # DefaultTestSet is written to in parallel. The next block of code, below, addresses
    # that by adding a lock around setters. A nicer fix would be to use a lock-free accumulator.

    # Key for Task Local Storage
    struct TestSetStackKey end

    # Fork the stack of testsets when new tasks are spawned, so that child tasks don't
    # clobber eachother's stacks.
    TaskHeritableStorage.fork_task_local_storage(k::TestSetStackKey, v) = (k, copy(v))

    # Get the stack of currently executing testsets, inherited from parent tasks
    function get_current_testsets()
        get!(task_local_storage(), TestSetStackKey(), AbstractTestSet[])
    end

    function get_testset()
        testsets = get_current_testsets()
        return isempty(testsets) ? fallback_testset : testsets[end]
    end

    function push_testset(ts::AbstractTestSet)
        testsets = get_current_testsets()
        push!(testsets, ts)
    end

    function pop_testset()
        testsets = get_current_testsets()
        ret = isempty(testsets) ? fallback_testset : pop!(testsets)
        return ret
    end

    function get_testset_depth()
        testsets = get_current_testsets()
        return length(testsets)
    end

    # ------------------------------------------
    # Make Test _thread-safe_ by locking when writing to the results of a parent testset:

    if VERSION >= v"1.3-"

        test_lock_ = ReentrantLock()

        record(ts::DefaultTestSet, t::Broken) = begin
            lock(test_lock_); push!(ts.results, t); unlock(test_lock_);
            t
        end
        # For a passed result, do not store the result since it uses a lot of memory
        record(ts::DefaultTestSet, t::Pass) = begin
            lock(test_lock_); ts.n_passed += 1; unlock(test_lock_);
            t
        end

        # For the other result types, immediately print the error message
        # but do not terminate. Print a backtrace.
        function record(ts::DefaultTestSet, t::Union{Fail, Error})
            if myid() == 1
                printstyled(ts.description, ": ", color=:white)
                # don't print for interrupted tests
                if !(t isa Error) || t.test_type != :test_interrupted
                    print(t)
                    # don't print the backtrace for Errors because it gets printed in the show
                    # method
                    if !isa(t, Error)
                        Base.show_backtrace(stdout, scrub_backtrace(backtrace()))
                    end
                    println()
                end
            end
            lock(test_lock_); push!(ts.results, t); unlock(test_lock_);
            t, isa(t, Error) || backtrace()
        end

        # When a DefaultTestSet finishes, it records itself to its parent
        # testset, if there is one. This allows for recursive printing of
        # the results at the end of the tests
        record(ts::DefaultTestSet, t::AbstractTestSet) = begin
            lock(test_lock_); push!(ts.results, t); unlock(test_lock_);
        end


        function record(ts::DefaultTestSet, t::LogTestFailure)
            if myid() == 1
                printstyled(ts.description, ": ", color=:white)
                print(t)
                Base.show_backtrace(stdout, scrub_backtrace(backtrace()))
                println()
            end
            # Hack: convert to `Fail` so that test summarization works correctly
            lock(test_lock_);
            push!(ts.results, Fail(:test, t.orig_expr, t.logs, nothing, t.source))
            unlock(test_lock_);
            t
        end

    end  # VERSION >= v1.3
end

end
