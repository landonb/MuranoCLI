FROM ruby:2.3.6-jessie

# NOTE: Environs from Jenkins, like ${WORKSPACE} or any passwords you
#   inject, are not available from here.

WORKDIR /app
COPY . /app

#RUN /bin/ls -la

RUN ruby -v

RUN cd /app && gem install bundler && bundler install && rake build

RUN ruby -rubygems -e 'puts Gem.dir'

RUN ruby -e 'require "/app/lib/MrMurano/version.rb"; puts MrMurano::VERSION'

RUN gem install -i \
	$(ruby -rubygems -e 'puts Gem.dir') \
	pkg/MuranoCLI-$(ruby -e \
		'require "/app/lib/MrMurano/version.rb"; puts MrMurano::VERSION' \
	).gem

#ENV MURANO_USERNAME $MURANO_USERNAME
#ENV MURANO_PASSWORD $MURANO_PASSWORD
#ENV LANDON_PASSWORD $LANDON_PASSWORD
#ENV OTHER_PASSWORD $OTHER_PASSWORD
#ENV WORKSPACE $WORKSPACE

# vim:tw=0:ts=4:sw=4:noet:ft=conf:

