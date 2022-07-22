FROM ubuntu:14.04

ENV DEBIAN_FRONTEND=noninteractive
ENV CHEF_LICENSE=accept-silent

COPY .metasploitable3 /opt/metasploitable3
COPY .chef.deb /usr/local/src/chef.deb
## Install dependencies for recipes
RUN apt-get update \
  && dpkg -i /usr/local/src/chef.deb  \
	&& apt-get install -f --no-install-recommends --no-install-suggests -y\
  curl \
  wget \
  mlocate \
  sudo \
  openssh-server \
  mysql-server \
  supervisor \
  remote-login-service


RUN mkdir -p /lost+found \
	&& mkdir -p /var/run/sshd

COPY drupal.rb /opt/metasploitable3/chef/cookbooks/metasploitable/recipes/drupal.rb
COPY flags.rb /opt/metasploitable3/chef/cookbooks/metasploitable/recipes/flags.rb
COPY install_recipies /usr/local/src/install_recipies
COPY solo.rb /opt/metasploitable3/solo.rb
## Run the recipes
RUN chef-solo -c /opt/metasploitable3/solo.rb -o "$(cat /usr/local/src/install_recipies)"

## Dependencies for services

## Clean up
RUN apt-get remove -y chef \
	&& apt-get autoremove -y \
	&& apt-get clean -y \
	&& rm -rf /var/lib/apt/lists/* \
	&& rm -rf /opt/metasploitable3 \
	&& rm /tmp/chatbot.zip \
	&& rm /tmp/phpMyAdmin*.tar.gz

## Create vuln user for management
RUN useradd --create-home -s /bin/bash vuln \
        && echo vuln:vuln | chpasswd \
	&& usermod -aG sudo vuln

## Copy files for services to start on container run
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf
COPY start.sh /start.sh

CMD [ "/usr/bin/supervisord" ]
