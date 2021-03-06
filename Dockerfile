# An integration test & dev container which builds and installs RAPIDS from latest source branches
ARG CUDA_VERSION=9.2
ARG LINUX_VERSION=ubuntu18.04
FROM nvidia/cuda:${CUDA_VERSION}-devel-${LINUX_VERSION}
ENV LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/usr/local/cuda/lib64:/usr/local/lib
# Needed for cudf.concat(), avoids "OSError: library nvvm not found"
ENV NUMBAPRO_NVVM=/usr/local/cuda/nvvm/lib64/libnvvm.so
ENV NUMBAPRO_LIBDEVICE=/usr/local/cuda/nvvm/libdevice/
# Needed for promptless tzdata install
ENV DEBIAN_FRONTEND=noninteractive

ARG CC=7
ARG CXX=7
RUN apt update -y --fix-missing && \
    apt upgrade -y && \
      apt install -y \
      git \
      gcc-${CC} \
      g++-${CXX} \
      libboost-all-dev \
      tzdata \
      locales

# Install conda
#ADD https://repo.continuum.io/miniconda/Miniconda3-latest-Linux-x86_64.sh /miniconda.sh
ADD Miniconda3-latest-Linux-x86_64.sh /miniconda.sh
RUN sh /miniconda.sh -b -p /conda && /conda/bin/conda update -n base conda
ENV PATH=${PATH}:/conda/bin
# Enables "source activate conda"
SHELL ["/bin/bash", "-c"]

# Build cuDF conda env
ENV CONDA_ENV=rapids
ADD rapids_dev.yml /conda/environments/rapids_dev.yml
RUN conda env create --name ${CONDA_ENV} --file /conda/environments/rapids_dev.yml
ENV LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/conda/envs/${CONDA_ENV}/lib

# Added here to prevent re-downloading after changes to custrings, cudf, cugraph src, etc
RUN source activate ${CONDA_ENV} && conda install -c nvidia/label/cuda10.0 -c defaults \
    nvgraph jupyterlab bokeh s3fs scikit-learn scipy

ENV PYNI_PATH=/conda/envs/${CONDA_ENV}
ENV PYTHON_VERSION=3.7
RUN locale-gen en_US.UTF-8
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:en
ENV LC_ALL en_US.UTF-8
ENV CC=/usr/bin/gcc-${CC}
ENV CXX=/usr/bin/g++-${CXX}

ADD custrings/LICENSE /custrings/LICENSE
ADD custrings/cpp /custrings/cpp
ADD custrings/thirdparty /custrings/thirdparty

# Build/install custrings
ENV CMAKE_CXX11_ABI=ON
RUN source activate ${CONDA_ENV} && \
    mkdir -p /custrings/cpp/build && \
    cd /custrings/cpp/build && \
    cmake .. -DCMAKE_INSTALL_PREFIX=${CONDA_PREFIX} -DCMAKE_CXX11_ABI=ON && \
    make -j install
#WORKDIR /custrings/cpp
#RUN source activate ${CONDA_ENV} && \
#    make -f Makefile.with_python
ADD custrings/python /custrings/python
WORKDIR /custrings/python
RUN source activate ${CONDA_ENV} && pip install cmake_setuptools
RUN source activate ${CONDA_ENV} && python setup.py install

# build/install libcudf
ADD cudf/thirdparty /cudf/thirdparty
ADD cudf/cpp /cudf/cpp
WORKDIR /cudf/cpp
RUN source activate ${CONDA_ENV} && \
    mkdir -p /cudf/cpp/build && \
    cd /cudf/cpp/build && \
    cmake .. -DCMAKE_INSTALL_PREFIX=${CONDA_PREFIX} -DCMAKE_CXX11_ABI=ON -DCMAKE_BUILD_TYPE=Debug && \
    make -j install && \
    make python_cffi && \
    make install_python


# Python bindings change faster than underlying c++ libs
# Build/Install them
# cuDF python bindings build/install
ADD cudf/.git /cudf/.git
ADD cudf/python /cudf/python
RUN source activate ${CONDA_ENV} && \
    cd /cudf/python && \
    python setup.py build_ext --inplace && \
    python setup.py install

ADD cuml/python /cuml/python
WORKDIR /cuml/python
RUN source activate ${CONDA_ENV} && \
    python setup.py build_ext --inplace && \
    python setup.py install


# doc builds
ADD custrings/docs /custrings/docs
ADD cudf/docs /cudf/docs
ADD cuml/docs /cuml/docs
ADD cugraph/docs /cugraph/docs

# install dask-cuda
ADD dask-cuda /dask-cuda
WORKDIR /dask-cuda
RUN source activate ${CONDA_ENV} && python setup.py install

# install dask-cudf
ADD dask-cudf /dask-cudf
WORKDIR /dask-cudf
RUN source activate ${CONDA_ENV} && python setup.py install


WORKDIR /notebooks
CMD source activate ${CONDA_ENV} && jupyter-lab --allow-root --ip='0.0.0.0' --NotebookApp.token=''
