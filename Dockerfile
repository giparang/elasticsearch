#
# Elasticsearch Dockerfile
#
# https://github.com/dockerfile/elasticsearch
#

# Pull base image.
FROM dockerfile/java:oracle-java8

ENV ES_PKG_NAME elasticsearch-1.5.0

ENV MECAB_KO mecab-0.996-ko-0.9.2
ENV MECAB_KO_DIC mecab-ko-dic-1.6.1-20140814
ENV MECAB_JAVA mecab-java-0.996
ENV ES_ANALYSIS_MECAB_KO elasticsearch-analysis-mecab-ko-0.16.3

# Install Elasticsearch.
RUN \
  cd / && \
  wget https://download.elasticsearch.org/elasticsearch/elasticsearch/$ES_PKG_NAME.tar.gz && \
  tar xvzf $ES_PKG_NAME.tar.gz && \
  rm -f $ES_PKG_NAME.tar.gz && \
  mv /$ES_PKG_NAME /elasticsearch

# Download korean plugin files 
RUN \
  mkdir /es-korean-plugin && cd /es-korean-plugin && \
  wget https://bitbucket.org/eunjeon/mecab-ko/downloads/$MECAB_KO.tar.gz && \
  tar xvzf $MECAB_KO.tar.gz && \
  rm -f $MECAB_KO.tar.gz && \
  wget https://bitbucket.org/eunjeon/mecab-ko-dic/downloads/$MECAB_KO_DIC.tar.gz && \
  tar xvzf $MECAB_KO_DIC.tar.gz && \
  rm -f $MECAB_KO_DIC.tar.gz && \
  wget https://mecab.googlecode.com/files/$MECAB_JAVA.tar.gz && \
  tar xvzf $MECAB_JAVA.tar.gz && \
  rm -f $MECAB_JAVA.tar.gz

# Update and install prerequisite
RUN \
  apt-get update && \
  apt-get install -y automake1.11

# Install mecab-ko
RUN \
  cd /es-korean-plugin/$MECAB_KO && \
  ./configure && \
  make && \
  make check && \
  make install && \
  ldconfig

# Install mecab-ko-dic
RUN \
  cd /es-korean-plugin/$MECAB_KO_DIC && \
  ./configure && \
  make && \
  make install

# Install mecab-java
RUN \
  cd /es-korean-plugin/$MECAB_JAVA && \
  sed 's/^INCLUDE=.*$/INCLUDE=\$$JAVA_HOME\/include/' Makefile > Makefile.tmp && mv -f Makefile.tmp Makefile && \
  sed 's/$(CXX) -O3 -c/$(CXX) -O1 -c/' Makefile > Makefile.tmp && mv -f Makefile.tmp Makefile && \
  sed 's/$(JAVAC) test.java/$(JAVAC) -cp . test.java/' Makefile > Makefile.tmp && mv -f Makefile.tmp Makefile && \
  export JAVA_TOOL_OPTIONS=-Dfile.encoding=UTF8 && \
  make && \
  cp libMeCab.so /usr/local/lib

# Install elasticsearch plugin
RUN \
  /elasticsearch/bin/plugin --install $ES_ANALYSIS_MECAB_KO --url https://bitbucket.org/eunjeon/mecab-ko-lucene-analyzer/downloads/$ES_ANALYSIS_MECAB_KO.zip

# Define mountable directories.
VOLUME ["/data"]

# Mount elasticsearch.yml config
ADD config/elasticsearch.yml /elasticsearch/config/elasticsearch.yml

# Define working directory.
WORKDIR /data

# Define default command.
CMD ["/elasticsearch/bin/elasticsearch", "-Djava.library.path=/usr/local/lib"]

# Expose ports.
#   - 9200: HTTP
#   - 9300: transport
EXPOSE 9200
EXPOSE 9300
