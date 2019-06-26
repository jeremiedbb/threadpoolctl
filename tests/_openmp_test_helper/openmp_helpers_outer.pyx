cimport openmp
from cython.parallel import parallel, prange
from libc.stdlib cimport malloc, free

from openmp_helpers_inner cimport inner_openmp_loop
from openmp_helpers_inner cimport threadpool_func
from openmp_helpers_inner cimport get_set_num_threads_funcs
from openmp_helpers_inner cimport set_num_threads



def check_nested_openmp_loops(int n, nthreads=None):
    """Run a short parallel section with OpenMP with nested calls

    The inner OpenMP loop has not necessarily been built/linked with the
    same runtime OpenMP runtime.
    """
    cdef:
        int outer_num_threads = -1
        int inner_num_threads = -1
        int num_threads = nthreads or openmp.omp_get_max_threads()
        int i

    for i in prange(n, num_threads=num_threads, nogil=True):
        inner_num_threads = inner_openmp_loop(n)
        outer_num_threads = openmp.omp_get_num_threads()
        
    return outer_num_threads, inner_num_threads


def check_nested_openmp_loops_with_cython_helpers(int n, nthreads_outer=None, int nthreads_inner=1):
    """Run a short parallel section with OpenMP with nested calls

    The inner OpenMP loop has not necessarily been built/linked with the
    same runtime OpenMP runtime.
    """
    cdef:
        int outer_num_threads = -1
        int inner_num_threads = -1
        int num_threads = nthreads_outer or openmp.omp_get_max_threads()
        int i

        threadpool_func *set_num_threads_funcs = <threadpool_func*> malloc(sizeof(threadpool_func))
        int n_funcs

    n_funcs = get_set_num_threads_funcs(set_num_threads_funcs)

    with nogil, parallel(num_threads=num_threads):
        set_num_threads(set_num_threads_funcs, n_funcs, nthreads_inner)

        for i in prange(n):
            inner_num_threads = inner_openmp_loop(n)
            outer_num_threads = openmp.omp_get_num_threads()

    free(set_num_threads_funcs)

    return outer_num_threads, inner_num_threads


def get_compiler():
    return CC_OUTER_LOOP
