#!/bin/bash

set -ex

# c.f. https://conda-forge.org/docs/maintainer/knowledge_base/#cross-compilation-examples
# Get an updated config.sub and config.guess
cp $BUILD_PREFIX/share/gnuconfig/config.* .

autoreconf --install --force

# Cross-compilation: pre-seed autoconf cache for file existence checks.
# AC_CHECK_FILE cannot check for file existence when cross-compiling.
# The configure script checks if pyext/rivet/core.cpp exists to determine
# if Cython needs to regenerate it. Since Cython is available in the build
# environment, the file will be generated during the build.
if [[ "${CONDA_BUILD_CROSS_COMPILATION:-}" == "1" ]]; then
    export ac_cv_file_pyext_rivet_core_cpp=no
fi

./configure --help

./configure \
    --prefix=$PREFIX \
    --enable-shared=yes \
    --enable-static=no \
    --disable-doxygen \
    --with-yoda=$PREFIX \
    --with-hepmc3=$PREFIX \
    --with-fastjet=$PREFIX \
    --with-fjcontrib=$PREFIX \
    --with-zlib=$PREFIX \
    PYTHON=$PYTHON

make --jobs="${CPU_COUNT}"

# Skip ``make check`` when cross-compiling
if [[ "${CONDA_BUILD_CROSS_COMPILATION:-}" != "1" || "${CROSSCOMPILING_EMULATOR:-}" != "" ]]; then
  make check
fi
make install
make clean
