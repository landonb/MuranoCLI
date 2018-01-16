#!/bin/bash

export WORKSPACE=${WORKSPACE:-/app/murano}
mkdir -p ${WORKSPACE}

export MURANO_CONFIGFILE=${WORKSPACE}/test.run.muranocfg

echo "\${MURANO_USERNAME}: ${MURANO_USERNAME}"
echo "\${MURANO_PASSWORD}: ${MURANO_PASSWORD}"
echo "\${LANDON_PASSWORD}: ${LANDON_PASSWORD}"
echo "\${WORKSPACE}: ${WORKSPACE}"

if [[ -z ${MURANO_PASSWORD} ]]; then
    >&2 echo "Please set MURANO_PASSWORD."
    exit 1
fi

cat > "${WORKSPACE}/test.run.muranocfg" <<-EOCFB
[user]
  name = landonbouma+jenkins-nix@exosite.com
[business]
  id = hd7opcgbyjfqd7vi
[net]
  host = bizapi.hosted.exosite.io
EOCFB

echo "Testing!"

cd /app

echo "ruby -v..."
ruby -v

echo "gem install bundler..."
gem install bundler

echo "bundler install..."
bundler install

# NOTE: `ruby -Ilib bin/murano -v` works now. Not sure why.

echo "rake rebuild..."
#rake rebuild
rake build

echo "gem install..."
ruby -rubygems -e 'puts Gem.dir'
ruby -e 'require "/app/lib/MrMurano/version.rb"; puts MrMurano::VERSION'
gem install -i $(ruby -rubygems -e 'puts Gem.dir') pkg/MuranoCLI-$(ruby -e 'require "/app/lib/MrMurano/version.rb"; puts MrMurano::VERSION').gem

# NOTE: `murano -v` works now. As expected.

#[ ${GIT_BRANCH} = "origin/feature/windows" ] && export MURANO_PASSWORD=${LANDON_PASSWORD}

echo "Testing \"$(murano -v)\" on \"$(ruby -v)\""
#rake test_clean_up test

