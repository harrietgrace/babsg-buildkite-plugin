FROM python:3.6.3-alpine
MAINTAINER Stuart Auld <sauld@cozero.com.au>

ENV BATS_VERSION 0.4.0

RUN \
# install dependencies
     apk --no-cache --update add \
       bash \
       bc \
       ca-certificates \
       curl \
       jq \
       make \
# install BATS
  && curl -o "/tmp/v${BATS_VERSION}.tar.gz" -L \
       "https://github.com/sstephenson/bats/archive/v${BATS_VERSION}.tar.gz" \
  && tar -zxf "/tmp/v${BATS_VERSION}.tar.gz" -C /tmp/ \
  && bash "/tmp/bats-${BATS_VERSION}/install.sh" /usr/local \
  && rm -rf /tmp/* \
# install aws cli
  && pip install awscli

COPY . /mnt
WORKDIR /mnt

# install BKBH
RUN  \
  make install

ENTRYPOINT ["/usr/local/bin/bats"]

CMD ["-v"]
