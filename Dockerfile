FROM nvidia/cuda:11.7.1-cudnn8-devel-ubuntu22.04 AS builder

RUN ln -sf /usr/share/zoneinfo/Asia/Tokyo /etc/localtime
ENV LANG=en_US.UTF-8

ENV OPENPOSE_DIR=/usr/lib/openpose

# install dependencies
RUN apt-get update && apt-get install -y \
    cmake \
    libopencv-dev \
    git \
    wget \
    libprotobuf-dev \
    # protobuf-compiler \
    sudo

# download openpose src
WORKDIR ${OPENPOSE_DIR}/..
RUN git clone https://github.com/CMU-Perceptual-Computing-Lab/openpose
WORKDIR ${OPENPOSE_DIR}
RUN git submodule update --init --recursive --remote

# install dependencies
WORKDIR ${OPENPOSE_DIR}
RUN bash ${OPENPOSE_DIR}/scripts/ubuntu/install_deps.sh

# build
WORKDIR ${OPENPOSE_DIR}/build
RUN cmake \
    -DBUILD_PYTHON=ON \
    -DDOWNLOAD_BODY_25_MODEL=OFF \
    -DDOWNLOAD_FACE_MODEL=OFF \
    -DDOWNLOAD_HAND_MODEL=OFF \
    -DUSE_CUDNN=OFF \
    .. && \
    make -j`nproc`


FROM nvidia/cuda:11.7.1-cudnn8-devel-ubuntu22.04

ENV OPENPOSE_DIR=/usr/lib/openpose

RUN apt-get update && apt-get install -y \
    wget

# download models
WORKDIR ${OPENPOSE_DIR}/models/pose/body_25
RUN wget -c https://www.dropbox.com/s/3x0xambj2rkyrap/pose_iter_584000.caffemodel
WORKDIR ${OPENPOSE_DIR}/models/face
RUN wget -c https://www.dropbox.com/s/d08srojpvwnk252/pose_iter_116000.caffemodel
WORKDIR ${OPENPOSE_DIR}/models/hand
RUN wget -c https://www.dropbox.com/s/gqgsme6sgoo0zxf/pose_iter_102000.caffemodel

# install python dependencies
COPY --from=builder ${OPENPOSE_DIR}/build/python ${OPENPOSE_DIR}
COPY --from=builder ${OPENPOSE_DIR}/models ${OPENPOSE_DIR}/models

ENV OPENPOSE_MODEL_PATH=${OPENPOSE_DIR}/models
ENV PYTHONPATH=${OPENPOSE_DIR}/openpose

# uninstall old python
# RUN apt-get remove -y python3.10 python3-pip
