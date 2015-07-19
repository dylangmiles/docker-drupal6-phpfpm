FROM debian:wheezy

MAINTAINER "Dylan Miles" <dylan.g.miles@gmail.com>

RUN echo "deb http://snapshot.debian.org/archive/debian/20120221T041601Z/ unstable main" >> /etc/apt/sources.list
RUN echo "deb-src http://snapshot.debian.org/archive/debian/20120221T041601Z/ unstable main" >> /etc/apt/sources.list


# Install PHP-FPM and popular/laravel required extensions
RUN apt-get -o Acquire::Check-Valid-Until=false update -y && \
    apt-get install -y \
    php5-common=5.3.10-2 \
    php5-cli=5.3.10-2 \
    php5-fpm=5.3.10-2 \
    php5-curl=5.3.10-2 \
    php5-gd=5.3.10-2 \
    # php5-geoip=5.3.10-2 \
    # php5-imagick=5.3.10-2 \
    # php5-imap=5.3.10-2 \
    # php5-json=5.3.10-2 \
    # php5-ldap \
    php5-mcrypt=5.3.10-2 \
    # php5-memcache=5.3.10-2 \
    # php5-memcached=5.3.10-2 \
    # php5-mongo=5.3.10-2 \
    # php5-mssql=5.3.10-2 \
    php5-mysqlnd=5.3.10-2 \
    # php5-pgsql \
    # php5-redis=5.3.10-2 \
    # php5-sqlite \
    # php5-xdebug=5.3.10-2 \
    php5-xmlrpc=5.3.10-2 \
    # php5-xcache=5.3.10-2 \
    php5-tidy=5.3.10-2 \
    php5-dev=5.3.10-2 \
    php-pear=5.3.10-2 \

    # Build apache solr php module
    build-essential \
    libcurl4-gnutls-dev \
    libxml2 \
    libxml2-dev \
    libpcre3-dev \
    && pecl install -n solr-1.1.1 \
    
    #Pear mail
    && pear install mail \
    && pear install Net_SMTP

# Configure PHP-FPM
RUN sed -i "s/;date.timezone =.*/date.timezone = UTC/" /etc/php5/fpm/php.ini && \
    sed -i "s/;cgi.fix_pathinfo=1/cgi.fix_pathinfo=0/" /etc/php5/fpm/php.ini && \
    sed -i "s/display_errors = Off/display_errors = stderr/" /etc/php5/fpm/php.ini && \
    sed -i "s/upload_max_filesize = 2M/upload_max_filesize = 30M/" /etc/php5/fpm/php.ini && \
    sed -i "s/;opcache.enable=0/opcache.enable=0/" /etc/php5/fpm/php.ini && \
    sed -i "s/max_execution_time = 30/max_execution_time = 300/" /etc/php5/fpm/php.ini && \
    sed -i -e "s/;daemonize\s*=\s*yes/daemonize = no/g" /etc/php5/fpm/php-fpm.conf && \
    sed -i '/^listen = /clisten = 9000' /etc/php5/fpm/pool.d/www.conf && \
    sed -i '/^listen.allowed_clients/c;listen.allowed_clients =' /etc/php5/fpm/pool.d/www.conf && \
    sed -i '/^;catch_workers_output/ccatch_workers_output = yes' /etc/php5/fpm/pool.d/www.conf && \
    sed -i '/^;env\[TEMP\] = .*/aenv[DB_PORT_3306_TCP_ADDR] = $DB_PORT_3306_TCP_ADDR' /etc/php5/fpm/pool.d/www.conf \
    && echo "extension=solr.so" > /etc/php5/fpm/conf.d/solr.ini \
    && echo "extension=solr.so" > /etc/php5/cli/conf.d/solr.ini

#Patch pear mail to allow for certificate exceptions
RUN sed -i "s/\$this->_socket_options = \$socket_options;/\$this->_socket_options = array('ssl' => array('verify_peer' => false, 'verify_peer_name' => false, 'allow_self_signed' => true));/" /usr/share/php/Net/SMTP.php

RUN mkdir -p /data
VOLUME ["/data"]

EXPOSE 9000

ENTRYPOINT ["/usr/sbin/php5-fpm"]
