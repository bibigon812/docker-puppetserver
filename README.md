# Puppetserver

This docker container contains puppetserver, r10k, librarian-puppet. It checks
$GIT_REMOTE repo for changes and runs `r10k deploy environment`.
Librarian-puppet installs all modules from Puppetfile with their dependencies
for each environment.

The $GIT_REMOTE tree might look like this:

```shell
├── Puppetfile
├── README.md
├── data
│   ├── common
...
│   └── nodes
├── environment.conf
├── hiera.yaml
├── manifests
│   └── site.pp
└── modules
```

## Environment Variables

$GIT_REMOTE contains a URL with a user name and a token, for example
https://username:token@git.example.com/a/b.git

### Defaults

- CACHE_DIR="/var/cache/r10k"
- ENVIRONMENTS_BASE_DIR="/etc/puppetlabs/code/environments"
- R10K_CONFIG_TEMPLATE="/r10k.yaml.erb"
- R10K_CONFIG_DIR="/etc/puppetlbas/r10k"
- GIT_TIMEOUT = "30"

## Deployment

```shell
docker run --rm --name puppetserver \
    --env GIT_REMOTE=https://username:token@git.example.com/a/b.git \
    --volume /srv/puppet/ssl:/etc/puppetlabs/puppet/ssl/ \
    --volume /srv/puppet/serverdata:/opt/puppetlabs/server/data/puppetserver/ \
    --hostname puppet --dns-search . bibigon812/puppetserver
```
