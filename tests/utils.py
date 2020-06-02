import os
import sys
import tempfile
import textwrap
import threadpoolctl
from glob import glob
from os.path import dirname, normpath
from subprocess import check_output


# Path to shipped openblas for libraries such as numpy or scipy
libopenblas_patterns = []


try:
    # make sure the mkl/blas are loaded for test_threadpool_limits
    import numpy as np
    np.dot(np.ones(1000), np.ones(1000))

    libopenblas_patterns.append(os.path.join(np.__path__[0], ".libs",
                                             "libopenblas*"))
except ImportError:
    pass


try:
    import scipy
    import scipy.linalg  # noqa: F401
    scipy.linalg.svd([[1, 2], [3, 4]])

    libopenblas_patterns.append(os.path.join(scipy.__path__[0], ".libs",
                                             "libopenblas*"))
except ImportError:
    scipy = None

libopenblas_paths = set(path for pattern in libopenblas_patterns
                        for path in glob(pattern))


try:
    import tests._openmp_test_helper.openmp_helpers_inner  # noqa: F401
    cython_extensions_compiled = True
except ImportError:
    cython_extensions_compiled = False


def threadpool_info_from_subprocess(code):
    """Utility to call threadpool_info in a subprocess

    `code` is exectuted before calling threadpool_info
    """
    handle, filename = tempfile.mkstemp(suffix='.py')
    os.close(handle)

    src = code + textwrap.dedent("""
    from threadpoolctl import threadpool_info
    print(threadpool_info())
    """)

    path1 = normpath(dirname(threadpoolctl.__file__))
    path2 = os.path.join(path1, "tests", "_openmp_test_helper")
    pythonpath = os.pathsep.join([path1, path2])
    env = os.environ.copy()
    try:
        env["PYTHONPATH"] = os.pathsep.join([pythonpath, env["PYTHONPATH"]])
    except KeyError:
        env["PYTHONPATH"] = pythonpath

    try:
        with open(filename, "wb") as f:
            f.write(src.encode("utf-8"))
        cmd = [sys.executable, filename]
        out = check_output(cmd, env=env).decode("utf-8")
    finally:
        os.remove(filename)

    return eval(out)
