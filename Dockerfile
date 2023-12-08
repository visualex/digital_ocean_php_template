FROM php:7.2-apache

# this line is to break cache and rebuild this image
RUN echo "latest"
#
# Timezone in containers, there are alternatives like mounting hosts /etc/localtime (to be considered if we split up the datacenter)
# keeping this section separated for extra clarity in dependencies (tzdata)
# RUN export DEBIAN_FRONTEND=noninteractive
ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=America/Los_Angeles
RUN apt-get install -y tzdata && rm -rf /var/lib/apt/lists/*
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

# security notes
#
#
# apache is executed by root but drops to www-data when scripts are executed from the front end:
# (same old functionality apache always had) making this container safe
# please see composer notes below
# set root password to a random string to avoid privilege escalation & disable su for non root users

RUN echo "root:"$(head /dev/urandom | tr -dc A-Za-z0-9 | head -c 99 ; echo '') | chpasswd
RUN chmod 4700 /bin/su

RUN apt-get update && apt-get install -y \
    dnsutils \
    g++ \
    libfreetype6-dev \
    libicu-dev \
    libc-client-dev \
    libjpeg-dev \
    libkrb5-dev \
    libmcrypt-dev \
    libpng-dev \
    libsqlite3-dev \
    libtidy-dev \
    libxml2-dev \
    links \
    openssl \
    sqlite3 \
    vim \
    wget \
    whois \
    zlib1g-dev \
    && rm -rf /var/lib/apt/lists/*

RUN docker-php-ext-install bcmath
RUN docker-php-ext-install calendar
RUN docker-php-ext-install ctype
RUN docker-php-ext-install dba
RUN docker-php-ext-install dom
RUN docker-php-ext-install exif
RUN docker-php-ext-install fileinfo
RUN docker-php-ext-configure imap --with-kerberos --with-imap-ssl
RUN docker-php-ext-install imap
RUN docker-php-ext-configure intl
RUN docker-php-ext-install intl
RUN docker-php-ext-install json
RUN docker-php-ext-install mbstring
RUN docker-php-ext-install mysqli
RUN docker-php-ext-install pdo pdo_mysql pdo_sqlite
RUN docker-php-ext-install posix
RUN docker-php-ext-install session
RUN docker-php-ext-install shmop
RUN docker-php-ext-install simplexml
RUN docker-php-ext-install sockets
RUN docker-php-ext-install tidy
RUN docker-php-ext-install zip
RUN docker-php-ext-configure gd \
    --with-png-dir=/usr/lib \
    --with-jpeg-dir=/usr/lib \
    --with-freetype-dir=/usr/include/freetype2 \
    --with-png-dir=/usr/include \
    --with-jpeg-dir=/usr/include
RUN docker-php-ext-install gd
COPY php.ini /usr/local/etc/php/

# COMPOSER (globally available (note that we move it to $PATH))
# We must install composer packages with the user ucomposer:
# plugins & scripts can be executed and therefore should not be executed by root
# Please see the descendant Dockerfiles to see how composer should be invoked
RUN wget https://getcomposer.org/installer
RUN php installer
RUN chmod 775 composer.phar && mv composer.phar /usr/local/bin/composer
RUN groupadd ucomposer
RUN useradd -g ucomposer ucomposer

# needed for whois
COPY etc/services /etc/services
RUN chown root:root /etc/services
RUN chmod 644 /etc/services

# APACHE
RUN a2enmod rewrite
ADD ./apache/apache2.conf /etc/apache2/apache2.conf
ADD ./apache/000-default.conf /etc/apache2/sites-enabled/
RUN rm -f /etc/apache2/sites-available/default-ssl.conf

EXPOSE 80

