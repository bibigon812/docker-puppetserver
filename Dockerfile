FROM ubuntu:16.04

ENV PUPPET_SERVER_VERSION="5.3.1" \
    DUMB_INIT_VERSION="1.2.1" \
    UBUNTU_CODENAME="xenial" \
    PUPPETSERVER_JAVA_ARGS="-Xms512m -Xmx512m" \
    PATH=/opt/puppetlabs/server/bin:/opt/puppetlabs/puppet/bin:/opt/puppetlabs/bin:$PATH \
    PUPPET_HEALTHCHECK_ENVIRONMENT="production"
    LIBRARIAN_PUPPET_VERSION="2.2.1"

RUN apt-get update && \
    apt-get install -y wget=1.17.1-1ubuntu1 && \
    wget https://apt.puppetlabs.com/puppetlabs-release-pc1-"$UBUNTU_CODENAME".deb && \
    wget https://github.com/Yelp/dumb-init/releases/download/v"$DUMB_INIT_VERSION"/dumb-init_"$DUMB_INIT_VERSION"_amd64.deb && \
    dpkg -i puppetlabs-release-pc1-"$UBUNTU_CODENAME".deb && \
    dpkg -i dumb-init_"$DUMB_INIT_VERSION"_amd64.deb && \
    rm puppetlabs-release-pc1-"$UBUNTU_CODENAME".deb dumb-init_"$DUMB_INIT_VERSION"_amd64.deb && \
    apt-get update && \
    apt-get install --no-install-recommends git -y puppetserver="$PUPPET_SERVER_VERSION"-1"$UBUNTU_CODENAME" && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* && \
    /opt/puppetlabs/puppet/bin/gem install librarian-puppet --version="$LIBRARIAN_PUPPET_VERSION"

COPY puppetserver /etc/default/puppetserver
COPY logback.xml /etc/puppetlabs/puppetserver/
COPY request-logging.xml /etc/puppetlabs/puppetserver/

COPY entrypoint.sh /

EXPOSE 8140

ENTRYPOINT ["dumb-init", "/entrypoint.sh"]
CMD ["foreground" ]

HEALTHCHECK --interval=10s --timeout=10s --retries=90 CMD \
  curl --fail -H 'Accept: pson' \
  --resolve 'puppet:8140:127.0.0.1' \
  --cert   $(puppet config print hostcert) \
  --key    $(puppet config print hostprivkey) \
  --cacert $(puppet config print localcacert) \
  https://puppet:8140/${PUPPET_HEALTHCHECK_ENVIRONMENT}/status/test \
  |  grep -q '"is_alive":true' \
  || exit 1

COPY Dockerfile /
