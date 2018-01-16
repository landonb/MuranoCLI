FROM ruby:2.3.6-jessie

# 2017-05-30: Adding `netcat` for testing beanstalk.
#RUN apt-get update && \
#	apt-get upgrade -y && \
#	apt-get dist-upgrade -y && \
#	apt-get install -y ruby && \
#	apt-get install -y netcat && \
#	apt-get clean && \
#	rm -rf /var/lib/apt/lists/*

#RUN gem install rake --no-rdoc --no-ri

WORKDIR /app
COPY . /app

RUN /bin/ls -la
#RUN cd /app && git init
#RUN cd /app && git submodule init && git submodule update

ENV MURANO_USERNAME $MURANO_USERNAME
ENV MURANO_PASSWORD $MURANO_PASSWORD
ENV LANDON_PASSWORD $LANDON_PASSWORD
ENV OTHER_PASSWORD $OTHER_PASSWORD
ENV WORKSPACE $WORKSPACE

# Dockerfile cache invalidator: 1.
RUN echo "MURANO_USERNAME: ${MURANO_USERNAME}"
RUN echo "MURANO_PASSWORD: ${MURANO_PASSWORD}"
RUN echo "LANDON_PASSWORD: ${LANDON_PASSWORD}"
RUN echo "WORKSPACE: ${WORKSPACE}"

RUN echo "OTHER_PASSWORD: ${OTHER_PASSWORD}"
RUN echo "OTHER_PASSWORD: ${#OTHER_PASSWORD}"
RUN echo "Hidden! 12345 Is it?"

#Step 14/17 : RUN echo "OTHER_PASSWORD: ${OTHER_PASSWORD}"
# ---> Running in 090dfcf2a969
#OTHER_PASSWORD: 
#Removing intermediate container 090dfcf2a969
# ---> 60d13478aed7
#Step 15/17 : RUN echo "OTHER_PASSWORD: ${#OTHER_PASSWORD}"
# ---> Running in 9199c3000388
#OTHER_PASSWORD: 0
#Removing intermediate container 9199c3000388
# ---> d503ce122904
#Step 16/17 : RUN echo "Hidden! [*******] Is it?"
# ---> Running in 2aad94a5c078
#Hidden! [*******] Is it?

# Avoid:
#  /var/lib/gems/2.1.0/gems/rake-11.3.0/lib/rake/file_utils.rb:56:
#   warning: Insecure world writable dir /go/bin in PATH, mode 040777
#RUN /bin/chmod go-w /go /go/bin

#RUN rake -f /app/Rakefile goose thirdwish

#EXPOSE 3000

#ENTRYPOINT ["/app/bin/third-wish"]
#ENTRYPOINT ["/app/dockers/docker-test.sh"]
#
#RUN /app/dockers/docker-test.sh
RUN cd /app && ./dockers/docker-test.sh
#ENTRYPOINT ["/app/dockers/docker-test.sh"]

# docker exec --tty 9c5ded298ca4be3c6e6395ef97fdd48a8cd3948d5c91a83dff0f111280eb05c1 env

# vim:tw=0:ts=4:sw=4:noet:ft=conf:

