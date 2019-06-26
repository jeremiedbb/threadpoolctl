cdef int inner_openmp_loop(int) nogil

ctypedef void (*threadpool_func)(int) nogil

cdef int get_set_num_threads_funcs(threadpool_func*)
cdef void set_num_threads(threadpool_func*, int, int) nogil
