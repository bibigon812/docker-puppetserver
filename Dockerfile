ARG DEBIAN_CODE_NAME=stretch
FROM debian:${DEBIAN_CODE_NAME}-slim

ENV CACHE_DIR="/var/cache/r10k" \
    DEBIAN_CODE_NAME=${DEBIAN_CODE_NAME} \
    DUMB_INIT_VERSION="1.2.1" \
    ENVIRONMENTS_BASE_DIR="/etc/puppetlabs/code/environments" \
    GIT_REMOTE="https://gitlab+deploy-token-3:FoSURJ3yossz9MAfD7pz@gitlab.spbtv.com/Trezin/Templates/puppet-environment.git" \
    GIT_TEMP_DIR="/tmp/git" \
    HEALTHCHECK_ENVIRONMENT="production" \
    LIBRARIAN_PUPPET_VERSION="3.0.0" \
    PATH=/opt/puppetlabs/server/bin:/opt/puppetlabs/puppet/bin:/opt/puppetlabs/bin:$PATH \
    PUPPETSERVER_JAVA_ARGS="-Xms1g -Xmx1g -Djruby.logger.class=com.puppetlabs.jruby_utils.jruby.Slf4jLogger" \
    R10K_CONFIG_TEMPLATE="/r10k.yaml.erb" \
    R10K_CONFIG_DIR="/etc/puppetlabs/r10k" \
    R10K_CONFIG_FILE="${R10K_CONFIG_DIR}/r10k.yaml"

RUN apt-get update && \
    apt-get install -y wget=1.17.1-1ubuntu1 && \
    wget https://apt.puppetlabs.com/puppet5-release-"${CODE_NAME}".deb && \
    wget https://github.com/Yelp/dumb-init/releases/download/v"$DUMB_INIT_VERSION"/dumb-init_"$DUMB_INIT_VERSION"_amd64.deb && \
    dpkg -i puppet5-release-"${CODE_NAME}".deb && \
    dpkg -i dumb-init_"$DUMB_INIT_VERSION"_amd64.deb && \
    rm puppet5-release-"${CODE_NAME}".deb dumb-init_"$DUMB_INIT_VERSION"_amd64.deb && \
    apt-get update && \
    apt-get install --no-install-recommends --assume-yes git puppetserver && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* && \
    gem install --no-rdoc --no-ri librarian-puppet && \
    gem install --no-rdoc --no-ri r10k

COPY puppetserver /etc/default/puppetserver
COPY auth.conf /etc/puppetlabs/puppetserver/conf.d/
COPY logback.xml /etc/puppetlabs/puppetserver/
COPY request-logging.xml /etc/puppetlabs/puppetserver/

RUN puppet config set autosign true --section master && \
    puppet config set basemodulepath '$codedir/modules:$codedir/vendor/modules:/opt/puppetlabs/puppet/modules' --section main && \
    puppet config set libdir /etc/puppetlabs/code/lib --section master

COPY init.rb /
COPY r10k.yaml.erb /
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
    https://puppet:8140/${HEALTHCHECK_ENVIRONMENT}/status/test \
    |  grep -q '"is_alive":true' \
    || exit 1

COPY Dockerfile /
