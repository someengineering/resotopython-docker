# This is the resoto python container. It includes CPython and is used
# as the common base for all the other containers. The main size contributor
# is the resoto-venv-python3 virtual environment which
# is required for all resoto packages. That's why size wise it made sense to
# use the same base package for all containers.
FROM ubuntu:20.04 as build-env
ENV DEBIAN_FRONTEND=noninteractive
ARG TARGETPLATFORM
ARG BUILDPLATFORM
ARG PYTHON_VERSION=3.11.0

ENV PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
RUN echo "I am running on ${BUILDPLATFORM}, building for ${TARGETPLATFORM}"

# Install Build dependencies
RUN apt-get update
RUN apt-get -y dist-upgrade
RUN apt-get -y install apt-utils
RUN apt-get -y install \
        build-essential \
        git \
        curl \
        unzip \
        zlib1g-dev \
        libncurses5-dev \
        libgdbm-dev \
        libgdbm-compat-dev \
        libnss3-dev \
        libreadline-dev \
        libsqlite3-dev \
        tk-dev \
        lzma \
        lzma-dev \
        liblzma-dev \
        uuid-dev \
        libbz2-dev \
        rustc \
        shellcheck \
        findutils \
        libtool \
        automake \
        autoconf \
        libffi-dev \
        libssl-dev \
        cargo \
        linux-headers-generic

# Download and install CPython
WORKDIR /build/python
RUN curl -L -o /tmp/python.tar.gz  https://www.python.org/ftp/python/${PYTHON_VERSION}/Python-${PYTHON_VERSION}.tgz
RUN tar xzvf /tmp/python.tar.gz --strip-components=1 -C /build/python
RUN ./configure --enable-optimizations --prefix /usr/local/python
RUN make -j 12
RUN make install
RUN /usr/local/python/bin/python3 -m ensurepip

# Create CPython venv
WORKDIR /usr/local
RUN /usr/local/python/bin/python3 -m venv resoto-venv-python3

# Download and install Python test tools
RUN . /usr/local/resoto-venv-python3/bin/activate && python -m pip install -U pip wheel tox flake8


# Setup main image
FROM ubuntu:20.04
ENV DEBIAN_FRONTEND=noninteractive
ENV LANG="en_US.UTF-8"
COPY --from=build-env /usr/local /usr/local
ENV PATH=/usr/local/python/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
WORKDIR /
RUN apt-get update \
    && apt-get -y --no-install-recommends install apt-utils \
    && apt-get -y dist-upgrade \
    && apt-get -y install \
        build-essential \
        git \
        curl \
        unzip \
        zlib1g-dev \
        libncurses5-dev \
        libgdbm-dev \
        libgdbm-compat-dev \
        libnss3-dev \
        libreadline-dev \
        libsqlite3-dev \
        tk-dev \
        lzma \
        lzma-dev \
        liblzma-dev \
        uuid-dev \
        libbz2-dev \
        rustc \
        shellcheck \
        findutils \
        libtool \
        automake \
        autoconf \
        libffi-dev \
        libssl-dev \
        cargo \
        linux-headers-generic \
        dumb-init \
        iproute2 \
        libffi7 \
        openssl \
        procps \
        dateutils \
        jq \
        cron \
        ca-certificates \
        openssh-client \
        locales \
        nano \
        nvi \
    && echo 'LANG="en_US.UTF-8"' > /etc/default/locale \
    && echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen \
    && rm -f /bin/sh \
    && ln -s /bin/bash /bin/sh \
    && locale-gen \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

ENTRYPOINT ["/bin/dumb-init", "--"]
CMD ["/bin/bash"]
