FROM ghcr.io/toltec-dev/python:v1.1

RUN pip3 install okp

WORKDIR /rmkit
COPY . /rmkit/
RUN rm src/build -fr
