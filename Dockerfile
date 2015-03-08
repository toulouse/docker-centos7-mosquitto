FROM centos:7
MAINTAINER toulouse

RUN yum -y update; yum clean all
RUN yum -y install sudo epel-release; yum clean all
RUN yum -y install gcc gcc-c++ clang cmake make; yum clean all
RUN yum -y install openssl-devel libuuid-devel c-ares-devel; yum clean all

ENV CC /usr/bin/clang
ENV CXX /usr/bin/clang++

ADD libwebsockets-1.3-chrome37-firefox30.tar.gz /src/libwebsockets/
WORKDIR /src/libwebsockets/libwebsockets-1.3-chrome37-firefox30
RUN mkdir build
WORKDIR build
RUN cmake .. -DLIB_SUFFIX=64
RUN make install
RUN make clean

ADD mosquitto-1.4.tar.gz /src/mosquitto/
WORKDIR /src/mosquitto/mosquitto-1.4
RUN sed -i "s/WITH_WEBSOCKETS:=no/WITH_WEBSOCKETS:=yes/" config.mk
RUN echo LIB_SUFFIX:=64 >> config.mk
RUN make binary
RUN make install
RUN make clean
COPY libwebsockets-x86_64.conf /etc/ld.so.conf.d/
RUN ldconfig
RUN useradd -r mosquitto -m -d /mosquitto
COPY mosquitto.conf /mosquitto/
RUN mkdir /mosquitto/conf.d/

RUN yum -y install postgresql-devel
ADD mosquitto-auth-plug-11466d7.tar.gz /src/mosquitto-auth-plug/
WORKDIR /src/mosquitto-auth-plug
RUN cp config.mk.in config.mk
RUN sed -i "s/BACKEND_MYSQL ?= yes/BACKEND_MYSQL ?= no/" config.mk
RUN sed -i "s/BACKEND_POSTGRES ?= no/BACKEND_POSTGRES ?= yes/" config.mk
RUN sed -i "s#MOSQUITTO_SRC =#MOSQUITTO_SRC = /src/mosquitto#" config.mk
RUN make
RUN cp /src/mosquitto-auth-plug/auth-plug.so /mosquitto/
COPY auth-plug.conf /mosquitto/conf.d/

WORKDIR /mosquitto
VOLUME [ "/mosquitto/"]
EXPOSE 1883 10001
ENTRYPOINT ["/usr/local/sbin/mosquitto", "-v", "-c", "mosquitto.conf"]
