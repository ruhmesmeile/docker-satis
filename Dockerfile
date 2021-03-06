FROM debian:stretch-slim

MAINTAINER Yannick Pereira-Reis <yannick.pereira.reis@gmail.com>

ENV DEBIAN_FRONTEND noninteractive

RUN apt-get update \
    && apt-get upgrade -y \
    && apt-get install -y --no-install-recommends \
        ca-certificates \
        build-essential \
        software-properties-common \
        cron \
        nano \
        wget \
        sudo \
        lsb-release \
        apt-transport-https \
        git \
        curl \
        supervisor \
        nginx \
        ssh \
        unzip \
        libmcrypt-dev \
    && wget -O /etc/apt/trusted.gpg.d/php.gpg https://packages.sury.org/php/apt.gpg \
        && echo "deb https://packages.sury.org/php/ $(lsb_release -sc) main" >> /etc/apt/sources.list.d/php.list \
        && apt-get update \
        && apt-get install -y --no-install-recommends \
        php7.3 \
        php7.3-tidy \
        php7.3-cli \
        php7.3-common \
        php7.3-curl \
        php7.3-intl \
        php7.3-fpm \
        php7.3-zip \
        php7.3-apcu \
        php7.3-xml \
        php7.3-mbstring \
	&& apt-get clean \
    && rm -Rf /var/lib/apt/lists/* /usr/share/man/* /usr/share/doc/* /tmp/* /var/tmp/*

RUN sed -i "s/;date.timezone =.*/date.timezone = UTC/" /etc/php/7.3/cli/php.ini \
	&& sed -i "s/;date.timezone =.*/date.timezone = UTC/" /etc/php/7.3/fpm/php.ini \
	&& echo "daemon off;" >> /etc/nginx/nginx.conf \
	&& sed -i -e "s/;daemonize\s*=\s*yes/daemonize = no/g" /etc/php/7.3/fpm/php-fpm.conf \
	&& sed -i "s/;cgi.fix_pathinfo=1/cgi.fix_pathinfo=0/" /etc/php/7.3/fpm/php.ini \
	&& sed -i "s/memory_limit = 128M/memory_limit = 2G/" /etc/php/7.3/fpm/php.ini

ADD nginx/default   /etc/nginx/sites-available/default

# Install ssh key
ENV USER_HOME /var/www
RUN mkdir -p $USER_HOME/.ssh/ && touch $USER_HOME/.ssh/known_hosts

# Install Composer, satis and satisfy
ENV COMPOSER_HOME /tmp/.composer
COPY --from=composer:1.8.6 /usr/bin/composer /usr/bin/composer
RUN composer global require hirak/prestissimo

#############################################################################################"
##
## Install from dist
##
#ADD https://github.com/ludofleury/satisfy/archive/3.1.zip /
#RUN unzip 3.1.zip \
#    && mv /satisfy-3.1 /satisfy \
#    && rm -rf 3.1.zip

##
##
## Install from composer/packagist
#RUN composer create-project playbloom/satisfy:dev-master

##
## Install from git clone
##
RUN git clone https://github.com/ludofleury/satisfy.git
#############################################################################################"


RUN cd /satisfy \
    && composer install \
    && chmod -R 777 /satisfy

ADD scripts /app/scripts

ADD scripts/crontab /etc/cron.d/satis-cron
ADD config/ /satisfy/config

RUN chmod 0644 /etc/cron.d/satis-cron \
	&& touch /var/log/satis-cron.log \
	&& chmod +x /app/scripts/startup.sh \
	&& mkdir -p /satisfy/var/composer

ADD supervisor/0-install.conf /etc/supervisor/conf.d/0-install.conf
ADD supervisor/1-cron.conf /etc/supervisor/conf.d/1-cron.conf
ADD supervisor/2-nginx.conf /etc/supervisor/conf.d/2-nginx.conf
ADD supervisor/3-php.conf /etc/supervisor/conf.d/3-php.conf

ADD satisfy-overwrites/Kernel.php /satisfy/src/Kernel.php
ADD satisfy-overwrites/SatisController.php /satisfy/src/Playbloom/Satisfy/Controller/SatisController.php
ADD satisfy-overwrites/services.yml /satisfy/src/Playbloom/Satisfy/Resources/config/services.yml
ADD satisfy-overwrites/home.html.twig /satisfy/src/Playbloom/Satisfy/Resources/views/home.html.twig
ADD satisfy-overwrites/satis_build_repo.html.twig /satisfy/src/Playbloom/Satisfy/Resources/views/satis_build_repo.html.twig
ADD satisfy-overwrites/SatisBuildRunner.php /satisfy/src/Playbloom/Satisfy/Runner/SatisBuildRunner.php
ADD satisfy-overwrites/BuildRepoEvent.php /satisfy/src/Playbloom/Satisfy/Event/BuildRepoEvent.php

RUN chmod -R 777 /satisfy

WORKDIR /app

CMD ["/usr/bin/supervisord", "-n", "-c", "/etc/supervisor/supervisord.conf"]

EXPOSE 80
EXPOSE 443

