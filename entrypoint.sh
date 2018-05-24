#!/bin/bash

chown -R puppet:puppet /etc/puppetlabs/puppet/ssl
chown -R puppet:puppet /opt/puppetlabs/server/data/puppetserver/

if test -n "${PUPPETDB_SERVER_URLS}" ; then
  sed -i "s@^server_urls.*@server_urls = ${PUPPETDB_SERVER_URLS}@" /etc/puppetlabs/puppet/puppetdb.conf
fi

exec cd /etc/puppetlabs/code && /opt/puppetlabs/puppet/bin/librarian-puppet install
exec /opt/puppetlabs/bin/puppetserver "$@"
