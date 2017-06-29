FROM debian:9

# Install all our dependencies and set some required build changes
RUN mkdir /app && \
    apt-get update && \
    apt-get install -y git zlib1g-dev make gcc automake autoconf bzip2 wget \
                       libtool subversion python2.7 libatlas3-base g++ \
                       libfcgi-dev && \
    apt-get clean && \
    ln -s /usr/bin/python2.7 /usr/bin/python && \
    echo "dash dash/sh boolean false" \
      | debconf-set-selections && dpkg-reconfigure -f noninteractive dash

# Build kaldi
COPY kaldi /app/kaldi
RUN cd /app/kaldi/tools && make
RUN cd /app/kaldi/src && ./configure --shared && make depend && make

# Build asr-server
COPY asr-server /app/asr-server
COPY apiai.mk /app/asr-server/apiai.mk
RUN cd /app/asr-server && make

# Add the model
COPY api.ai-kaldi-asr-model /app/api.ai-kaldi-asr-model

# Set the default command
WORKDIR /app/api.ai-kaldi-asr-model
CMD ../asr-server/fcgi-nnet3-decoder --fcgi-socket=:8000
