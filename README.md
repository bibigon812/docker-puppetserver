# Puppetserver

## Environment Variables

Just specify GIT_REMOTE.

### Defaults

- CACHE_DIR="/var/cache/r10k"
- ENVIRONMENTS_BASE_DIR="/etc/puppetlabs/code/environments"
- R10K_CONFIG_TEMPLATE="/r10k.yaml.erb"
- R10K_CONFIG_DIR="/etc/puppetlbas/r10k"
- GIT_TIMEOUT = "30"

## Deployment

```yaml
---
name: puppet
image: bibigon812/puppetserver
ports:
    - 8140:8140
env:
    GIT_REMOTE: https://username:token@git.example.com/project/repo.git
volumes:
    - /srv/puppet/ssl:/etc/puppetlabs/puppet/ssl/
    - /srv/puppet/serverdata:/opt/puppetlabs/server/data/puppetserver/
```
