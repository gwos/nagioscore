FROM ubuntu:bionic

ARG GITHUB_TOKEN

# headless nagios
RUN apt-get update -qq \
    && DEBIAN_FRONTEND=noninteractive apt-get install -qqy \
        #apache2 \
        autoconf \
        gcc \
        #libapache2-mod-php7.2 \
        libc6 \
        libgd-dev \
        make \
        php \
        unzip \
        wget

# nagios deps
RUN apt-get install -qqy \
    autoconf \
    gcc \
    libc6 \
    libmcrypt-dev \
    make \
    libssl-dev \
    wget \
    bc \
    gawk \
    dc \
    build-essential \
    snmp \
    libnet-snmp-perl \
    gettext \
    dnsutils \
    openssh-client \
    libmysqlclient-dev \
    libpq-dev

# nagios plugins deps
RUN apt-get install -qqy \
    autoconf \
    gcc \
    libdatetime-perl \
    make \
    build-essential \
    g++ \
    python-dev \
    libconfig-inifiles-perl \
    libnumber-format-perl

# bronx deps
RUN apt-get install -qqy \
    libapr1-dev \
    libaprutil1-dev \
    libmcrypt-dev \
    libwrap0-dev \
    libdb5.3-dev

# That's this dir; we should COPY not wget
#WORKDIR /tmp
#RUN wget --progress=bar:force https://github.com/gwos/nagioscore/archive/GROUNDWORK.zip \
    #&& unzip -qq GROUNDWORK.zip \
    #&& rm -rf GROUNDWORK.zip
#WORKDIR /tmp/nagioscore-GROUNDWORK
#RUN CFLAGS='-pthread -DUSE_CHECK_RESULT_DOUBLE_LINKED_LIST -O2' ./configure --enable-event-broker
#RUN useradd nagios
#RUN make -s all \
    #&& make -s install \
    #&& make -s install-init \
    #&& make -s install-config \
    #&& make -s install-commandmode \
    #&& make -s install-headers
#RUN rm -rf /tmp/nagioscore-GROUNDWORK

RUN useradd nagios

WORKDIR /tmp/nagioscore-GROUNDWORK
COPY . /tmp/nagioscore-GROUNDWORK
RUN CFLAGS='-pthread -DUSE_CHECK_RESULT_DOUBLE_LINKED_LIST -O2' ./configure --enable-event-broker
RUN make -s all \
    && make -s install \
    && make -s install-init \
    && make -s install-config \
    && make -s install-commandmode \
    && make -s install-headers
RUN rm -rf /tmp/nagioscore-GROUNDWORK

# Bronx
WORKDIR /tmp
RUN wget --progress=bar:force --header="Authorization: token $GITHUB_TOKEN" -O master.zip https://api.github.com/repos/gwos/bronx/zipball \
    && unzip -qq master.zip \
    && rm -rf master.zip
RUN mv ./* gwos-bronx
WORKDIR /tmp/gwos-bronx
RUN make -s all \
    && make -s install \
    && rm -rf /tmp/gwos-bronx

# nagios plugins
WORKDIR /tmp
RUN wget --progress=bar:force -O nagios-plugins.tar.gz https://github.com/nagios-plugins/nagios-plugins/archive/release-2.2.1.tar.gz \
    && tar zxf nagios-plugins.tar.gz \
    && rm -rf /tmp/nagios-plugins.tar.gz
WORKDIR /tmp/nagios-plugins-release-2.2.1/
RUN ./tools/setup \
    && ./configure \
    && make -s \
    && make -s install \
    && rm -rf /tmp/nagios-plugins-release-2.2.1

# nagios nrpe plugin
WORKDIR /tmp
RUN wget --progress=bar:force https://github.com/NagiosEnterprises/nrpe/archive/nrpe-2-15.zip \
    && unzip -qq nrpe-2-15.zip \
    && rm -rf nrpe-2-15.zip
WORKDIR /tmp/nrpe-nrpe-2-15
RUN ./configure --with-ssl-lib=/usr/lib/x86_64-linux-gnu \
    && make -s all
RUN cp -p src/check_nrpe /usr/local/nagios/libexec
RUN cp -p src/nrpe /usr/local/bin
RUN rm -rf /tmp/nrpe-nrpe-2-15

# custom/extended nagios plugins
WORKDIR /tmp
RUN wget --progress=bar:force --header="Authorization: token ${GITHUB_TOKEN}" -O master.zip https://api.github.com/repos/gwos/nagios-plugins/zipball \
    && unzip -qq master.zip \
    && rm -rf master.zip

RUN mv gwos-nagios-plugins-* nagios-plugins-master
WORKDIR /tmp/nagios-plugins-master
RUN cp -pr libexec/* /usr/local/nagios/libexec
WORKDIR /tmp/nagios-plugins-master/src
RUN unzip -qq wmic-1.3.14.zip \
    && rm -rf wmic-1.3.14.zip
WORKDIR /tmp/nagios-plugins-master/src/wmic-master
ENV ZENHOME=/tmp/nagios-plugins-master
ENV PERL5LIB=/usr/local/groundwork/monarch/lib
RUN mkdir -p Samba/source/bin/static
RUN make -s "CPP=gcc -E -ffreestanding"

RUN cp -p /tmp/nagios-plugins-master/bin/winexe /usr/local/bin
RUN cp -p /tmp/nagios-plugins-master/bin/wmic /usr/local/bin
RUN rm -rf /tmp/nagios-plugins-master

CMD /src/docker_cmd.sh

HEALTHCHECK --interval=1m --timeout=3s \
  CMD /usr/local/nagios/bin/nagiostats
