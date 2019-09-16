#!/bin/bash

set -e

if [[ "$PACKAGER" == conda* ]]; then
    source activate $VIRTUALENV
elif [[ "$PACKAGER" == "pip" ]]; then
    # we actually use conda to install the base environment:
    source activate $VIRTUALENV
elif [[ "$PACKAGER" == "ubuntu" ]]; then
    source $VIRTUALENV/bin/activate
    PYTHONPATH="." python continuous_integration/display_versions.py

    # ldd /usr/lib/python3.5/dist-packages/numpy/linalg/lapack_lite*
    sudo find / -name 'lapack_lite*'

    if [[ ! -z $APT_BLAS2 ]]; then
        sudo apt-get install $APT_BLAS2
    fi

    PYTHONPATH="." python continuous_integration/display_versions.py

    # ldd /usr/lib/python3.5/dist-packages/numpy/linalg/lapack_lite*

fi

set -x
PYTHONPATH="." python continuous_integration/display_versions.py

pytest -vlrxXs --junitxml=$JUNITXML --cov=threadpoolctl
