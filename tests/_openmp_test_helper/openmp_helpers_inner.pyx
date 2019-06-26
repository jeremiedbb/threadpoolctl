import ctypes

cimport openmp
from cython.parallel import prange
from libc.stdlib cimport realloc

from threadpoolctl import _set_num_threads_funcs


def check_openmp_num_threads(int n):
    """Run a short parallel section with OpenMP

    Return the number of threads that where effectively used by the
    OpenMP runtime.
    """
    cdef int num_threads = -1

    with nogil:
        num_threads = inner_openmp_loop(n)
    return num_threads


cdef int inner_openmp_loop(int n) nogil:
    """Run a short parallel section with OpenMP

    Return the number of threads that where effectively used by the
    OpenMP runtime.

    This function is expected to run without the GIL and can be called
    by an outer OpenMP / prange loop written in Cython in anoter file.
    """
    cdef long n_sum = 0
    cdef int i, num_threads

    for i in prange(n):
        num_threads = openmp.omp_get_num_threads()
        n_sum += i

    if n_sum != (n - 1) * n / 2:
        # error
        return -1

    return num_threads


cdef int get_set_num_threads_funcs(threadpool_func* funcs):
    funcs_from_tpctl = _set_num_threads_funcs()

    cdef int n = len(funcs_from_tpctl)

    funcs = <threadpool_func*> realloc(funcs, n * sizeof(threadpool_func))

    cdef int i

    for i in range(n):
        funcs[i] = (<threadpool_func*><size_t>ctypes.addressof(funcs_from_tpctl[i]))[0]

    return n


cdef void set_num_threads(threadpool_func *funcs, int n_funcs, int n_threads) nogil:
    cdef int i

    for i in range(n_funcs):
        funcs[i](n_threads)


def get_compiler():
    return CC_INNER_LOOP
