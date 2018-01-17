#!/bin/bash

echo "whoami: $(whoami)"
echo "USER: ${USER}"
#chown -R jenkins /app
echo "users: $(users)"
echo "groups: $(groups)"

echo "/etc/passwd: $(cat /etc/passwd)"
echo "/etc/sudoers: $(cat /etc/sudoers)"

echo "\${LANG}: ${LANG}"
echo "\${LANGUAGE}: ${LANGUAGE}"
echo "\${LC_ALL}: ${LC_ALL}"

export MURANO_USERNAME="${LANDON_USERNAME}"
export MURANO_PASSWORD="${LANDON_PASSWORD}"
echo "\${MURANO_USERNAME}: ${MURANO_USERNAME}"
echo "\${MURANO_PASSWORD}: ${MURANO_PASSWORD}"
echo "\${WORKSPACE}: ${WORKSPACE}"
echo "\$(pwd): $(pwd)"

#export LANG=en_US.UTF-8
#export LANGUAGE=en_US.UTF-8
#export LC_ALL=en_US.UTF-8

echo "ll /app"
/bin/ls -la /app

export WORKSPACE=${WORKSPACE:-/app/murano}
echo "ll ${WORKSPACE}"
/bin/ls -la ${WORKSPACE}
mkdir -p ${WORKSPACE}

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
/bin/ls /app

echo "USER: ${USER}"
echo "HOME: ${HOME}"
/bin/ls /home
mkdir -p /home/jenkins

# ***

ruby -v

#cd /app && gem install bundler && gem install rspec && bundler install && rake build

echo "GEM_DIR: $(ruby -rubygems -e 'puts Gem.dir')"

ruby -e 'require "/app/lib/MrMurano/version.rb"; puts MrMurano::VERSION'

#ERROR:  While executing gem ... (Errno::EACCES)
#    Permission denied @ rb_sysopen - /usr/local/bundle/gems/MuranoCLI-3.1.0.beta.3/.dockerignore
gem install -i \
	$(ruby -rubygems -e 'puts Gem.dir') \
	pkg/MuranoCLI-$(ruby -e \
		'require "/app/lib/MrMurano/version.rb"; puts MrMurano::VERSION' \
	).gem

#/bin/chmod -R go+w /app

# ***

echo "RAKE!"
#rake test_clean_up test
#rake test_clean_up -t
ruby -Ilib bin/murano solutions expunge -y --no-progress --no-color --ascii

echo "RAKE2!"
#rake test -t
echo "XXXXX"
echo "Bad????: ‘murclitestprod3cdb49e09c74aab7’"
pwd
#mkdir -p /app/report
cd /app
RVERS=$(ruby -rubygems -e "puts RUBY_VERSION.tr('.', '_')")
PATH=${PATH}:/usr/local/bundle/bin
echo "PATH: ${PATH}"
/bin/ls -la


echo "SUDO"
#su root -c "chmod 2777 /app/report"
#sudo: unknown uid 1001: who are you?
sudo chmod 2777 /app/report
echo "SUDONT"



echo "Testing \"$(murano -v)\" on \"$(ruby -v)\""

#cd /app && rspec --format html --out report/index-${RVERS}.html --format documentation
#cd /app && rspec --format html --out report/index-${RVERS}.html --format documentation --example "a number value fiftyHalf"
#LANG=en_US.UTF-8
#LC_ALL=en_US.UTF-8
#LC_ALL=en_US.UTF-8
#ruby --external-encoding=UTF-8
cd /app && rspec --format html --out /app/report/index-${RVERS}.html --format documentation --example 'murano link with project unlinks'

#ERROR: Directory '/tmp/jenkins-ff750fb5/workspace/MuranoCLI/MrMurano Tests/report' exists but failed copying to '/var/lib/jenkins/jobs/MuranoCLI/jobs/MrMurano Tests/htmlreports/RSpec_Report'.
#ERROR: This is especially strange since your build otherwise succeeded.

echo "ll ${WORKSPACE}"
/bin/ls -la "${WORKSPACE}"
echo "ll ${WORKSPACE}/report"
/bin/ls -la "${WORKSPACE}/report"
chmod 2777 "${WORKSPACE}/report"
echo "SUDO POWER"
sudo chmod 2777 "${WORKSPACE}/report"

echo "ll /app"
/bin/ls -la /app
echo "ll /app/report"
/bin/ls -la /app/report

