FROM ruby:2.3.6-jessie

WORKDIR /app
COPY . /app

RUN echo XXXX
RUN cat /etc/passwd

#RUN apt-get -qq update
#RUN apt-get upgrade -y

#RUN apt-get install -y language-pack-en
ENV LANGUAGE en_US.UTF-8
ENV LANG en_US.UTF-8
ENV LC_ALL en_US.UTF-8
#RUN locale-gen en_US.UTF-8

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

#RUN gem install -i \
#	$(ruby -rubygems -e 'puts Gem.dir') \
#	pkg/MuranoCLI-$(ruby -e \
#		'require "/app/lib/MrMurano/version.rb"; puts MrMurano::VERSION' \
#	).gem
RUN gem install \
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

RUN chmod 2777 /usr/local/bundle
RUN chmod 2777 /usr/local/bundle/bin
RUN find /usr/local/bundle -type d -exec chmod 2777 {} +
RUN find /usr/local/bundle -type f -exec chmod u+rw,g+rw,o+rw {} +
RUN /bin/ls -la /usr/local/bundle
RUN /bin/ls -la /usr/local/bundle/bin

RUN mkdir -p /home/jenkins
RUN chmod 2777 /home
RUN chmod 2777 /home/jenkins

# install things globally, for great justice
# https://github.com/docker-library/ruby/issues/53
# FIXME: TEST WITHOUT THESE TWO:
ENV GEM_HOME /usr/local/bundle
ENV PATH $GEM_HOME/bin:$PATH

RUN bundle config
#RUN bundle config --global path "$GEM_HOME" \
#    && bundle config --global bin "$GEM_HOME/bin"

