FROM ruby:2.3.6-jessie

# This is already a given, but just to be clear:
USER root

# XXX WORKDIR /app
# XXX COPY . /app

# This is a little hack so the Build step Execute Shell command
# can do as it pleases. Because Jenkins isn't quite configured
# properly, and otherwise the Docker user cannot do much.
# Give the unborn jenkins user sudo priveleges.

RUN echo "deb http://ftp.us.debian.org/debian/ jessie main contrib non-free" >> /etc/apt/sources.list
RUN echo "deb-src http://ftp.us.debian.org/debian/ jessie main contrib non-free" >> /etc/apt/sources.list
RUN apt-get -qq update

# For completeness, we could run upgrade, but that adds time to the build.
#RUN apt-get upgrade -y
##RUN apt-get dist-upgrade -y

RUN apt-get install -y sudo

#RUN echo "root	ALL=(ALL:ALL) ALL" >> /etc/sudoers
#RUN echo "1001	ALL=NOPASSWD: ALL" >> /etc/sudoers
## Members of the admin group may gain root privileges
#RUN echo "%admin	ALL=(ALL) ALL" >> /etc/sudoers
## Allow members of group sudo to execute any command
#RUN echo "%sudo	ALL=(ALL:ALL) ALL" >> /etc/sudoers
#RUN echo "%root	ALL=(ALL:ALL) ALL" >> /etc/sudoers
#
#???
RUN echo "ALL ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers




# Jenkins defaults to the ASCII encoding, but we want UTF-8.
# FIXME/MEH: (lb): Murano CLI still has encoding issues, e.g.,
#   invalid byte sequence in US-ASCII
# which we currently work around by running Murand CLI in ASCII, e.g.,
#   murano --no-progress --no-color --ascii ...
# which means our Jenkins/Docker test is not quite testing how
# people usually run the app. Oh well.
#
# NOTE: You cannot change the encoding from the Execute Shell
#       build command. You'll see, e.g.,:
#         $ export LC_ALL=en_US.UTF-8
#         setlocale: LC_ALL: cannot change locale (en_US.UTF-8)

ENV LANGUAGE en_US.UTF-8
ENV LANG en_US.UTF-8
#/bin/bash: warning: setlocale: LC_ALL: cannot change locale (en_US.UTF-8)
#ENV LC_ALL en_US.UTF-8

# NOTE: Environs from Jenkins, like ${WORKSPACE} or any passwords you
#   inject, are not available from here.



# Jenkins runs the Execute Shell script on Docker as the 'jenkins' user,
# but Docker is confused unless we create that user now and assign it the
# UID that gets used. ((lb): This is hacky; Ops might fix this eventually.)
# Without adding the user to the root group and having them run as such,
# we'd have to do the hideous, grotesque act of granting permissions to all:
#    RUN /bin/chmod -R go+w /app
#    RUN /bin/chmod 2777 /app
RUN useradd -m -s /bin/bash --uid 1001 -G root jenkins
#RUN /bin/chmod -R go+w /app
#RUN /bin/chmod 2777 /app
RUN mkdir /app && /bin/chown -R jenkins /app
USER jenkins

WORKDIR /app
COPY . /app





# XXX RUN ruby -v

#XXX #RUN cd /app && gem install bundler && bundler install && rake build
RUN cd /app && gem install bundler && gem install rspec && bundler install && rake build

#XXX RUN rspec -v
#XXX RUN whereis rspec
#XXX RUN command -v rspec

#XXX RUN ruby -rubygems -e 'puts Gem.dir'

#XXX RUN ruby -e 'require "/app/lib/MrMurano/version.rb"; puts MrMurano::VERSION'

#XXX #RUN gem install -i \
#XXX #	$(ruby -rubygems -e 'puts Gem.dir') \
#XXX #	pkg/MuranoCLI-$(ruby -e \
#XXX #		'require "/app/lib/MrMurano/version.rb"; puts MrMurano::VERSION' \
#XXX #	).gem
RUN gem install \
	pkg/MuranoCLI-$(ruby -e \
		'require "/app/lib/MrMurano/version.rb"; puts MrMurano::VERSION' \
	).gem
# If you're curious about GEM_HOME, et al, try:
# 
#   RUN bundle config


# XXX # Jenkins runs the Execute Shell script on Docker as the 'jenkins' user,
# but Docker is confused unless we create that user now and assign it the
# UID that gets used. ((lb): This is hacky; Ops might fix this eventually.)
# Without adding the user to the root group and having them run as such,
# we'd have to do the hideous, grotesque act of granting permissions to all:
#    RUN /bin/chmod -R go+w /app
#    RUN /bin/chmod 2777 /app
# WHERE IT WAS ORIGINALLY
#RUN useradd -m -s /bin/bash --uid 1001 -G root jenkins
#RUN /bin/chmod -R go+w /app
#RUN /bin/chmod 2777 /app


#XXX RUN /bin/ls -la /usr/local/bundle
#XXX RUN /bin/ls -la /usr/local/bundle/bin
RUN chmod 2777 /usr/local/bundle
RUN chmod 2777 /usr/local/bundle/bin
RUN find /usr/local/bundle -type d -exec chmod 2777 {} +
RUN find /usr/local/bundle -type f -exec chmod u+rw,g+rw,o+rw {} +
#XXX #RUN /bin/ls -la /usr/local/bundle
#XXX #RUN /bin/ls -la /usr/local/bundle/bin

#?
#RUN mkdir -p /home/jenkins
#RUN chmod 2777 /home
#RUN chmod 2777 /home/jenkins

#XXX # install things globally, for great justice
#XXX # https://github.com/docker-library/ruby/issues/53
#XXX # FIXME: TEST WITHOUT THESE TWO:
#XXX #ENV GEM_HOME /usr/local/bundle
#XXX #ENV PATH $GEM_HOME/bin:$PATH


#XXX #RUN bundle config --global path "$GEM_HOME" \
#XXX #    && bundle config --global bin "$GEM_HOME/bin"

#XXX #RUN mkdir -p /app/report
#XXX #RUN chmod 2777 /app/report

# vim:tw=0:ts=4:sw=4:noet:ft=conf:

