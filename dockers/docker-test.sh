#!/bin/bash

# Jenkins' Build's Execute Shell is run in the Docker container as
# user 'jenkins', sort of: If the Dockerfile does not set up the user
# first, you'll see these responses herein:
#
#   $ whoami
#   sudo: unknown uid 1001: who are you?
#   $ sudo whoami
#   whoami: cannot find name for user ID 1001
#   whoami:
#   $ echo ${USER}
#   jenkins
#   $ users
#   $ groups
#   cannot find name for group ID 1001
#   1001
#
# To work around this, the Dockerfile calls `useradd ... jenkins`,
# and we set the Jenkins Build Environment "User group" to 'root'.
#
# FIXME: (lb): Follow up with Ops. We might be working around an
#        issue that's better solved by Ops tweaking Jenkins.

# Jenkins runs the command from the ${WORKSPACE} directory, e.g.,
#   /tmp/jenkins-ff750fb5/workspace/MuranoCLI/MrMurano Tests
# which is actually outside the Docker container (on the host).
# We use the advanced Docker option, Volumes, to wire our container to
# the host. Specifically, Dockerfile wires /app/report and /app/coverage
# to ${WORKSPACE}/report and ${WORKSPACE}/coverage, respectively.

#XXX #echo "whoami: $(whoami)"
#XXX #echo "USER: ${USER}"
#XXX ##chown -R jenkins /app
#XXX #echo "users: $(users)"
#XXX #echo "groups: $(groups)"
#XXX #
#XXX #echo "/etc/passwd: $(cat /etc/passwd)"
#XXX #echo "/etc/sudoers: $(cat /etc/sudoers)"

#XXX #echo "\${LANG}: ${LANG}"
#XXX #echo "\${LANGUAGE}: ${LANGUAGE}"
#XXX #echo "\${LC_ALL}: ${LC_ALL}"

# Jenkins sets a few environs, like ${WORKSPACE}, and we pull in a few
# more from the Jenkins Environment Injector Plugin.

export MURANO_USERNAME="${LANDON_USERNAME}"
export MURANO_PASSWORD="${LANDON_PASSWORD}"

[[ -z ${MURANO_USERNAME} ]] && echo "ERROR: Please set MURANO_USERNAME" && exit 1
[[ -z ${MURANO_PASSWORD} ]] && echo "ERROR: Please set MURANO_PASSWORD" && exit 1

[[ -z ${WORKSPACE} ]] && echo "ERROR: Expected WORKSPACE to be set" && exit 1

#XXX #echo "\${MURANO_USERNAME}: ${MURANO_USERNAME}"
#XXX #echo "\${MURANO_PASSWORD}: ${MURANO_PASSWORD}"
#XXX #echo "\${WORKSPACE}: ${WORKSPACE}"
#XXX #echo "\$(pwd): $(pwd)"

#XXX #export LANG=en_US.UTF-8
#XXX #export LANGUAGE=en_US.UTF-8
#XXX #export LC_ALL=en_US.UTF-8

#XXX echo "ll /app"
#XXX /bin/ls -la /app

#XXX export WORKSPACE=${WORKSPACE:-/app/murano}
#XXX echo "ll ${WORKSPACE}"
#XXX /bin/ls -la ${WORKSPACE}
#XXX mkdir -p ${WORKSPACE}

cat > "${WORKSPACE}/test.run.muranocfg" <<-EOCFB
[user]
  name = landonbouma+jenkins-nix@exosite.com
[business]
  id = hd7opcgbyjfqd7vi
[net]
  host = bizapi.hosted.exosite.io
EOCFB
export MURANO_CONFIGFILE="${WORKSPACE}/test.run.muranocfg"

cd /app
#XXX /bin/ls /app

#XXX echo "USER: ${USER}"
#XXX echo "HOME: ${HOME}"
#XXX /bin/ls /home
#XXX mkdir -p /home/jenkins

#XXX ruby -v

#XXX #cd /app && gem install bundler && gem install rspec && bundler install && rake build

#XXX echo "GEM_DIR: $(ruby -rubygems -e 'puts Gem.dir')"

#XXX ruby -e 'require "/app/lib/MrMurano/version.rb"; puts MrMurano::VERSION'

#ERROR:  While executing gem ... (Errno::EACCES)
#    Permission denied @ rb_sysopen - /usr/local/bundle/gems/MuranoCLI-3.1.0.beta.3/.dockerignore
#
#gem install -i \
#	$(ruby -rubygems -e 'puts Gem.dir') \
#	pkg/MuranoCLI-$(ruby -e \
#		'require "/app/lib/MrMurano/version.rb"; puts MrMurano::VERSION' \
#	).gem

#XXX #/bin/chmod -R go+w /app

# ***

#XXX echo "RAKE!"
#XXX #rake test_clean_up test
# In lieu of `rake test_clean_up -t`, make the output more readable.
ruby -Ilib bin/murano solutions expunge -y --no-progress --no-color --ascii

#XXX echo "RAKE2!"
#XXX #rake test -t
#XXX echo "XXXXX"
#XXX echo "Bad????: ‘murclitestprod3cdb49e09c74aab7’"
#XXX pwd
#XXX #mkdir -p /app/report
#XXX cd /app
#XXX RVERS=$(ruby -rubygems -e "puts RUBY_VERSION.tr('.', '_')")
PATH=${PATH}:/usr/local/bundle/bin
echo "PATH: ${PATH}"
#XXX /bin/ls -la


#XXX echo "SUDO"
#XXX #su root -c "chmod 2777 /app/report"
#XXX #sudo: unknown uid 1001: who are you?

#WARNING: Could not write example statuses to .rspec_examples.txt (configured as `config.example_status_persistence_file_path`) due to a system error: #<Errno::EACCES: Permission denied @ rb_sysopen - .rspec_examples.txt>. Please check that the config option is set to an accessible, valid file path.

# CAN I GET BY WITHOUT??
#sudo chmod 2777 /app/report
#sudo chmod 2777 /app/coverage
#XXX echo "SUDONT"
#chmod 2777 /app/report
#chmod 2777 /app/coverage


##sudo /bin/chmod -R go+w /app
##sudo /bin/chmod 2777 /app
#sudo /bin/chown -R go+w /app
#sudo /bin/chown 2777 /app




echo "#####################################################################"
echo "Testing \"$(murano -v)\" on \"$(ruby -v)\""
echo "#####################################################################"

#XXX #cd /app && rspec --format html --out report/index-${RVERS}.html --format documentation
#XXX #cd /app && rspec --format html --out report/index-${RVERS}.html --format documentation --example "a number value fiftyHalf"
#XXX #LANG=en_US.UTF-8
#XXX #LC_ALL=en_US.UTF-8
#XXX #LC_ALL=en_US.UTF-8
#XXX #ruby --external-encoding=UTF-8
cd /app && rspec --format html --out /app/report/index-${RVERS}.html --format documentation --example 'murano link with project unlinks'


#XXX echo "ll ${WORKSPACE}"
#XXX /bin/ls -la "${WORKSPACE}"
#XXX echo "ll ${WORKSPACE}/report"
#XXX /bin/ls -la "${WORKSPACE}/report"
#XXX #chmod 2777 "${WORKSPACE}/report"
#XXX #chmod 2777 "${WORKSPACE}/coverage"
#XXX #echo "SUDO POWER"
# ERROR: Directory '/tmp/jenkins-ff750fb5/workspace/MuranoCLI/MrMurano Tests/report' exists but failed copying to '/var/lib/jenkins/jobs/MuranoCLI/jobs/MrMurano Tests/htmlreports/RSpec_Report'.
# ERROR: This is especially strange since your build otherwise succeeded.

# STILL NEED SUDO?
#sudo chmod 2777 "${WORKSPACE}/report"
#sudo chmod 2777 "${WORKSPACE}/coverage"
#chmod 2777 "${WORKSPACE}/report"
#chmod 2777 "${WORKSPACE}/coverage"

#XXX echo "ll /app"
#XXX /bin/ls -la /app
#XXX echo "ll /app/report"
#XXX /bin/ls -la /app/report

