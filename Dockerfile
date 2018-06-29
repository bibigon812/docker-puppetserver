ARG code_name=xenial
FROM ubuntu:${code_name}

ENV CACHE_DIR="/var/cache/r10k" \
    CODE_NAME=${code_name:-xenial} \
    DUMB_INIT_VERSION="1.2.1" \
    ENVIRONMENTS_BASE_DIR="/etc/puppetlabs/code/environments" \
    GIT_TEMP_DIR="/tmp/git" \
    GIT_TIMEOUT=30 \
    HEALTHCHECK_ENVIRONMENT="production" \
    JAVA_ARGS="-Xms1g -Xmx1g" \
    PATH=/opt/puppetlabs/server/bin:/opt/puppetlabs/puppet/bin:/opt/puppetlabs/bin:$PATH \
    R10K_CONFIG_DIR="/etc/puppetlabs/r10k"

RUN apt-get update && \
    apt-get install -y wget && \
    wget https://apt.puppetlabs.com/puppet5-release-"$CODE_NAME".deb && \
    wget https://github.com/Yelp/dumb-init/releases/download/v"$DUMB_INIT_VERSION"/dumb-init_"$DUMB_INIT_VERSION"_amd64.deb && \
    dpkg -i puppet5-release-"$CODE_NAME".deb && \
    dpkg -i dumb-init_"$DUMB_INIT_VERSION"_amd64.deb && \
    rm puppet5-release-"$CODE_NAME".deb dumb-init_"$DUMB_INIT_VERSION"_amd64.deb && \
    apt-get update && \
    apt-get install --no-install-recommends --assume-yes git puppetserver && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* && \
    gem install --no-rdoc --no-ri librarian-puppet && \
    gem install --no-rdoc --no-ri r10k && \
    rm -rf /usr/share/man

COPY puppetserver /etc/default/puppetserver
COPY auth.conf /etc/puppetlabs/puppetserver/conf.d/
COPY logback.xml /etc/puppetlabs/puppetserver/
COPY request-logging.xml /etc/puppetlabs/puppetserver/

COPY init.rb /
COPY entrypoint.sh /

RUN puppet config set autosign true --section master

EXPOSE 8140

ENTRYPOINT ["dumb-init", "/entrypoint.sh"]
CMD ["foreground"]

HEALTHCHECK --interval=10s --timeout=10s --retries=90 CMD \
  curl --fail -H 'Accept: pson' \
    --resolve 'puppet:8140:127.0.0.1' \
    --cert   $(puppet config print hostcert) \
    --key    $(puppet config print hostprivkey) \
    --cacert $(puppet config print localcacert) \
    https://puppet:8140/${HEALTHCHECK_ENVIRONMENT}/status/test \
    |  grep -q '"is_alive":true' \
    || exit 1

COPY Dockerfile /
