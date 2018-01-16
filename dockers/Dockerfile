FROM ruby:2.3.6-jessie

WORKDIR /app
COPY . /app

RUN echo XXXX
RUN cat /etc/passwd

# NOTE: Environs from Jenkins, like ${WORKSPACE} or any passwords you
#   inject, are not available from here.

RUN ruby -v

#RUN cd /app && gem install bundler && bundler install && rake build
RUN cd /app && gem install bundler && gem install rspec && bundler install && rake build

RUN rspec -v
RUN whereis rspec
RUN command -v rspec

RUN ruby -rubygems -e 'puts Gem.dir'

RUN ruby -e 'require "/app/lib/MrMurano/version.rb"; puts MrMurano::VERSION'

RUN gem install -i \
	$(ruby -rubygems -e 'puts Gem.dir') \
	pkg/MuranoCLI-$(ruby -e \
		'require "/app/lib/MrMurano/version.rb"; puts MrMurano::VERSION' \
	).gem

##RUN useradd -ms /bin/bash jenkins
##USER jenkins
##RUN chown -R jenkins:jenkins /app
##   sudo find $dest_dir -type d -exec chmod 2775 {} +
##   sudo find $dest_dir -type f -exec chmod u+rw,g+rw,o+r {} +
RUN /bin/chmod -R go+w /app
RUN /bin/chmod 2777 /app

# vim:tw=0:ts=4:sw=4:noet:ft=conf:


RUN /bin/ls -la /usr/local/bundle
RUN /bin/ls -la /usr/local/bundle/bin

# install things globally, for great justice
# https://github.com/docker-library/ruby/issues/53
ENV GEM_HOME /usr/local/bundle
ENV PATH $GEM_HOME/bin:$PATH

RUN  bundle config --global path "$GEM_HOME" \
    && bundle config --global bin "$GEM_HOME/bin"



