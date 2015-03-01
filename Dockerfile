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

ADD mosquitto-1.4.tar.gz /src/mosquitto/
WORKDIR /src/mosquitto/mosquitto-1.4
RUN sed -i "s/WITH_WEBSOCKETS:=no/WITH_WEBSOCKETS:=yes/" config.mk
RUN make binary
RUN make install
COPY libwebsockets-x86_64.conf /etc/ld.so.conf.d/
RUN ldconfig
RUN useradd -r mosquitto -m -d /mosquitto
COPY mosquitto.conf /mosquitto/
WORKDIR /mosquitto
VOLUME [ "/mosquitto/"]
EXPOSE 1883 10001
ENTRYPOINT ["/usr/local/sbin/mosquitto", "-v", "-c", "mosquitto.conf"]
