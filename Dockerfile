FROM php:8.3-apache

# Instala extensiones necesarias
RUN apt-get update && apt-get install -y \
    libxml2-dev \
    unzip \
    libzip-dev \
    && docker-php-ext-install pdo_mysql zip

# Instala Opcache (revalida ficheros para ver cambios sin reiniciar)
RUN docker-php-ext-install opcache \
    && printf "opcache.enable=1\nopcache.memory_consumption=128\nopcache.interned_strings_buffer=8\nopcache.max_accelerated_files=10000\nopcache.validate_timestamps=1\nopcache.revalidate_freq=0\n" > /usr/local/etc/php/conf.d/opcache.ini

# Instala Composer
COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

# Copia el proyecto al contenedor
COPY . /var/www/html/

# Cambia DocumentRoot a public/
ENV APACHE_DOCUMENT_ROOT=/var/www/html/public

# Ajusta configuración de Apache
RUN sed -ri -e "s!/var/www/html!${APACHE_DOCUMENT_ROOT}!g" /etc/apache2/sites-available/*.conf \
    && a2enmod rewrite \
    && chown -R www-data:www-data /var/www/html \
    && chmod -R 755 /var/www/html

WORKDIR /var/www/html

# Ajusta permisos de storage y bootstrap/cache al iniciar el contenedor
ENTRYPOINT ["/bin/bash", "-c", "chown -R www-data:www-data storage bootstrap/cache database && chmod -R 775 storage bootstrap/cache database && apache2-foreground"]
