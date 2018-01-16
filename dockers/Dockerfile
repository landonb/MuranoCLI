FROM ruby:2.3.6-jessie

WORKDIR /app
#USER jenkins
COPY . /app

RUN echo XXXX
RUN cat /etc/passwd

# NOTE: Environs from Jenkins, like ${WORKSPACE} or any passwords you
#   inject, are not available from here.

RUN ruby -v

RUN cd /app && gem install bundler && bundler install && rake build

RUN ruby -rubygems -e 'puts Gem.dir'

RUN ruby -e 'require "/app/lib/MrMurano/version.rb"; puts MrMurano::VERSION'

RUN gem install -i \
	$(ruby -rubygems -e 'puts Gem.dir') \
	pkg/MuranoCLI-$(ruby -e \
		'require "/app/lib/MrMurano/version.rb"; puts MrMurano::VERSION' \
	).gem

# vim:tw=0:ts=4:sw=4:noet:ft=conf:

