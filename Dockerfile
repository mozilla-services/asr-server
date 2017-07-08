FROM debian:9

# Install all our dependencies and set some required build changes
RUN mkdir /app && \
    apt-get update && \
    apt-get install -y git zlib1g-dev make gcc automake autoconf bzip2 wget \
                       libtool subversion python2.7 libatlas3-base g++ \
                       libfcgi-dev unzip nginx && \
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
RUN wget https://github.com/api-ai/api-ai-english-asr-model/releases/download/1.0/api.ai-kaldi-asr-model.zip && \
	unzip api.ai-kaldi-asr-model.zip -d /app/

# Copy nginx config
COPY nginx.conf /etc/nginx/sites-enabled/default

# Set the default command
WORKDIR /app/api.ai-kaldi-asr-model
CMD service nginx start && ../asr-server/fcgi-nnet3-decoder --fcgi-socket=:8000
