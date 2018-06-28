ARG debian_code_name=stretch
ARG dumb_init_version="1.2.1"
FROM debian:${debian_code_name}-slim

ENV CACHE_DIR="/var/cache/r10k" \
    ENVIRONMENTS_BASE_DIR="/etc/puppetlabs/code/environments" \
    GIT_REMOTE="https://gitlab+deploy-token-3:FoSURJ3yossz9MAfD7pz@gitlab.spbtv.com/Trezin/Templates/puppet-environment.git" \
    GIT_TEMP_DIR="/tmp/git" \
    HEALTHCHECK_ENVIRONMENT="production" \
    PATH=/opt/puppetlabs/server/bin:/opt/puppetlabs/puppet/bin:/opt/puppetlabs/bin:$PATH \
    PUPPETSERVER_JAVA_ARGS="-Xms1g -Xmx1g -Djruby.logger.class=com.puppetlabs.jruby_utils.jruby.Slf4jLogger" \
    R10K_CONFIG_TEMPLATE="/r10k.yaml.erb" \
    R10K_CONFIG_DIR="/etc/puppetlabs/r10k" \
    R10K_CONFIG_FILE="$R10K_CONFIG_DIR/r10k.yaml"

RUN apt-get update && \
    apt-get install -y wget && \
    wget https://apt.puppetlabs.com/puppet5-release-"${debian_code_name}".deb && \
    wget https://github.com/Yelp/dumb-init/releases/download/v"${dumb_init_version}"/dumb-init_"${dumb_init_version}"_amd64.deb && \
    dpkg -i puppet5-release-"${debian_code_name}".deb && \
    dpkg -i dumb-init_"${dumb_init_version}"_amd64.deb && \
    rm puppet5-release-"${debian_code_name}".deb dumb-init_"${dumb_init_version}"_amd64.deb && \
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

COPY init.rb /
COPY r10k.yaml.erb /
COPY entrypoint.sh /

RUN puppet config set autosign true --section master && \
    puppet config set basemodulepath '$codedir/modules:$codedir/vendor/modules:/opt/puppetlabs/puppet/modules' --section main && \
    puppet config set libdir /etc/puppetlabs/code/lib --section master

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
