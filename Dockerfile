FROM ubuntu:focal

ARG DEGAST_VERSION
ARG LDC_VERSION="1.28.0"

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update

RUN apt-get install -y bash curl git xz-utils gpg libxml2 gcc

# Install ldc
RUN curl -fsS https://dlang.org/install.sh | bash -s ldc-${LDC_VERSION}

# RUN find /root/dlang -maxdepth 1 -iname 'ldc*' -print

ENV PATH="/root/dlang/ldc-${LDC_VERSION}/bin:"$PATH

# RUN echo $PATH

RUN mkdir -p /degast

# Download degast
RUN git clone -b ${DEGAST_VERSION} https://github.com/asperan/degast.git /degast

WORKDIR /degast

RUN dub build --build=release
RUN strip degast

RUN cp /degast/degast /bin/dgst

WORKDIR /