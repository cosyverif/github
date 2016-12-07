FROM cosyverif/docker-images:openresty
MAINTAINER Alban Linard <alban@linard.fr>

ADD .               /src/cosy/github
ADD mime.types      /mime.types
ADD nginx.conf      /nginx.conf
ADD models.lua      /models.lua
ADD migrations.lua  /migrations.lua
ADD views           /views

RUN   apk add --no-cache --virtual .build-deps \
          build-base \
          make \
          perl \
          openssl-dev \
          skalibs-dev \
  &&  apk add --no-cache \
          openssh-client \
          skalibs \
  &&  cd /src/cosy/github/ \
  &&  git clone https://github.com/jprjr/sockexec.git \
  &&  cd sockexec && make && make install && cd .. \
  &&  luarocks install rockspec/lua-resty-qless-develop-0.rockspec \
  &&  luarocks make    rockspec/cosy-github-master-1.rockspec \
  &&  rm -rf /src/cosy/github \
  &&  apk del .build-deps

ENTRYPOINT ["cosy"]
