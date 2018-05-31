# Puppetserver

puppetsever = 2.6.0
puppet-agent = 1.7.1

### Environment Variables

* GIT_PRIVATE_KEY_FILE = "/etc/puppetlabs/git/id_rsa"
* GIT_SOURCE = "git://repository/project.git"
* GIT_SSH_COMMAND = "ssh -i ${GIT_PRIVATE_KEY_FILE} -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no"
* GIT_TIMEOUT = "30"
