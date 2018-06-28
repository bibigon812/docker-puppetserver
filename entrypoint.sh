#!/bin/bash

chown -R puppet:puppet /etc/puppetlabs/puppet/ssl
chown -R puppet:puppet /opt/puppetlabs/server/data/puppetserver/

# BEGIN Setup r10k
mkdir -p ${CACHE_DIR}
mkdir -p ${R10K_CONFIG_DIR}
/init.rb
# END Setup r10k

mkdir -p ${GIT_TEMP_DIR}

function loop_update_from_git {
  while true; do
    pushd ${GIT_TEMP_DIR}

    if [ ! -d '.git' ]; then
      git init
      git remote add origin ${GIT_REMOTE}
    fi

    last_commit=$(git ls-remote origin | cut -f1)
    changed=0
    git show $last_commit >/dev/null 2>/dev/null || changed=1

    if [[ $changed == 1 ]]; then
      git fetch --all
      r10k deploy environment
      pushd ${ENVIRONMENTS_BASE_DIR}
      for dir in $(find . -maxdepth 1 -type d \( ! -name . \)); do
        echo "Find ${dir} environment"
        pushd ${dir}
        librarian-puppet install
        popd
      done
      popd
      curl --resolve "$(hostname -f):8140:127.0.0.1" \
        --cert   $(puppet config print hostcert) \
        --key    $(puppet config print hostprivkey) \
        --cacert $(puppet config print localcacert) \
        -X DELETE \
        "https://$(hostname -f):8140/puppet-admin-api/v1/environment-cache"
    fi
    popd

    sleep ${GIT_TIMEOUT}
  done
}

if [ -n "${GIT_REMOTE}" ]; then
  loop_update_from_git &
fi


if [ -n "${PUPPETDB_SERVER_URLS}" ]; then
  sed -i "s@^server_urls.*@server_urls = ${PUPPETDB_SERVER_URLS}@" /etc/puppetlabs/puppet/puppetdb.conf
fi

exec /opt/puppetlabs/bin/puppetserver "$@"
