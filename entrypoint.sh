#!/bin/bash

chown -R puppet:puppet /etc/puppetlabs/puppet/ssl
chown -R puppet:puppet /opt/puppetlabs/server/data/puppetserver/

export GIT_SSH_COMMAND="ssh -i ${GIT_PRIVATE_KEY_FILE} -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no"

function loop_update_from_git {
  while true; do
    if [ $(ls -A /etc/puppetlabs/code) ]; then
      cd /etc/puppetlabs/code
      last_tag=$(git ls-remote origin -h refs/heads/master | cut -f1)
      changed=0
      git show $last_tag >/dev/null 2>/dev/null || changed=1

      if [[ $changed == 1 ]]; then
        git reset --quiet --hard >/dev/null
        git clean --quiet -fd
        git pull origin master >/dev/null 2>&1
        librarian-puppet install

        # Clear environment cache
        curl --resolve 'puppet:8140:127.0.0.1' \
          --cert   $(puppet config print hostcert) \
          --key    $(puppet config print hostprivkey) \
          --cacert $(puppet config print localcacert) \
          https://puppet:8140/puppet-admin-api/v1/environment-cache \

      fi
    else
      git clone "${GIT_CODE}" /etc/puppetlabs/code
    fi

    sleep ${GIT_TIMEOUT}
  done
}

if [ -n "${GIT_CODE}" ]; then
  loop_update_from_git &
fi


if [ -n "${PUPPETDB_SERVER_URLS}" ]; then
  sed -i "s@^server_urls.*@server_urls = ${PUPPETDB_SERVER_URLS}@" /etc/puppetlabs/puppet/puppetdb.conf
fi

sleep ${GIT_TIMEOUT}

exec /opt/puppetlabs/bin/puppetserver "$@"
