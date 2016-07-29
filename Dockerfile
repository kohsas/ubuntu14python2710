FROM ubuntu:14.04
MAINTAINER ashok.satyanarayana@gmail.com

#
#shamelessly copied from https://github.com/docker-library/python/blob/8d03a5036b0170c12ae422ed8f10169e8db9b30b/2.7/Dockerfile
#


RUN apt-get update

# remove several traces of debian python
RUN apt-get purge -y python.*

# http://bugs.python.org/issue19846
# > At the moment, setting "LANG=C" on a Linux system *fundamentally breaks Python 3*, and that's not OK.
ENV LANG C.UTF-8

RUN apt-get update && apt-get install -y --no-install-recommends \
		ca-certificates \
		libsqlite3-0 \
		libssl1.0.0 \
	&& rm -rf /var/lib/apt/lists/*

# gpg: key 18ADD4FF: public key "Benjamin Peterson <benjamin@python.org>" imported
ENV GPG_KEY C01E1CAD5EA2C4F0B8E3571504C367C218ADD4FF

ENV PYTHON_VERSION 2.7.10

# if this is called "PIP_VERSION", pip explodes with "ValueError: invalid truth value '<VERSION>'"
ENV PYTHON_PIP_VERSION 8.1.2

RUN set -ex \
	&& buildDeps=' \
		curl \
		gcc \
		libbz2-dev \
		libc6-dev \
		libncurses-dev \
		libreadline-dev \
		libsqlite3-dev \
		libssl-dev \
		make \
		tcl-dev \
		tk-dev \
		xz-utils \
		zlib1g-dev \
	' \
	&& apt-get update && apt-get install -y $buildDeps --no-install-recommends && rm -rf /var/lib/apt/lists/* \
	&& curl -fSL "https://www.python.org/ftp/python/${PYTHON_VERSION%%[a-z]*}/Python-$PYTHON_VERSION.tar.xz" -o python.tar.xz \
	&& curl -fSL "https://www.python.org/ftp/python/${PYTHON_VERSION%%[a-z]*}/Python-$PYTHON_VERSION.tar.xz.asc" -o python.tar.xz.asc \
	&& export GNUPGHOME="$(mktemp -d)" \
	&& gpg --keyserver ha.pool.sks-keyservers.net --recv-keys "$GPG_KEY" \
	&& gpg --batch --verify python.tar.xz.asc python.tar.xz \
	&& rm -r "$GNUPGHOME" python.tar.xz.asc \
	&& mkdir -p /usr/src/python \
	&& tar -xJC /usr/src/python --strip-components=1 -f python.tar.xz \
	&& rm python.tar.xz \
	\
	&& cd /usr/src/python \
	&& ./configure \
		--enable-shared \
		--enable-unicode=ucs4 \
	&& make -j$(nproc) \
	&& make install \
	&& ldconfig \
	&& curl -fSL 'https://bootstrap.pypa.io/get-pip.py' | python2 \
	&& pip install --no-cache-dir --upgrade pip==$PYTHON_PIP_VERSION \
	&& [ "$(pip list | awk -F '[ ()]+' '$1 == "pip" { print $2; exit }')" = "$PYTHON_PIP_VERSION" ] \
	&& find /usr/local -depth \
		\( \
		    \( -type d -a -name test -o -name tests \) \
		    -o \
		    \( -type f -a -name '*.pyc' -o -name '*.pyo' \) \
		\) -exec rm -rf '{}' + \
	&& apt-get purge -y --auto-remove $buildDeps \
	&& rm -rf /usr/src/python ~/.cache
