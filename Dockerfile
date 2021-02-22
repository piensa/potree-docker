FROM httpd:2.4

RUN apt-get -qq update
RUN apt-get -y -qq install supervisor 
RUN apt-get install -y -qq build-essential cmake git
RUN echo "deb http://ftp.us.debian.org/debian testing main contrib non-free" > /etc/apt/sources.list.d/testing.list 
RUN apt-get -qq update 
RUN apt-get install -y  g++-7
RUN apt-get install -y -qq -t testing g++-7
RUN update-alternatives --install /usr/bin/g++ g++ /usr/bin/g++-7 10
RUN apt-get clean
RUN rm -rf /var/lib/apt/lists/*

RUN mkdir -p  ~/dev/workspaces/lastools && \
  cd ~/dev/workspaces/lastools && \
  git clone https://github.com/m-schuetz/LAStools.git master && \
  cd master/LASzip && \
  mkdir build && \
  cd build && \
  cmake -DCMAKE_BUILD_TYPE=Release .. && \
  make && \
  make install && \
  ldconfig

RUN mkdir -p ~/dev/workspaces/PotreeConverter  && \
  cd ~/dev/workspaces/PotreeConverter && \
  git clone https://github.com/potree/PotreeConverter.git master && \
  cd master && \
  mkdir build && \
  cd build && \
  cmake -DCMAKE_BUILD_TYPE=Release -DLASZIP_INCLUDE_DIRS=~/dev/workspaces/lastools/master/LASzip/dll -DLASZIP_LIBRARY=~/dev/workspaces/lastools/master/LASzip/build/src/liblaszip.so .. && \
  make && \
  make install

RUN cd ~/dev/workspaces/PotreeConverter/master/build/PotreeConverter && \
  cp -r ~/dev/workspaces/PotreeConverter/master/PotreeConverter/resources/ . && \
  for foo in $(find ~/dev/workspaces/lastools/master/data/ -name "*.laz") ; do ./PotreeConverter $foo --color-range -p $(basename $foo .laz) --material RGB -o /usr/local/apache2/htdocs/ ; done && \
  rm /usr/local/apache2/htdocs/index.html

COPY supervisord.apache2.conf /etc/supervisor/conf.d/apache2.conf

# Bind mount location
VOLUME [ "/shared" ]

COPY startup.sh /opt/

# Execute Startup script when container starts
ENTRYPOINT [ "/opt/startup.sh" ]
