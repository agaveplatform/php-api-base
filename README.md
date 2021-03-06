## Agave PHP API Base Image

This is the base image used to create the Agave PHP API Images. It has Apache2 and PHP 5.5 installed and configured with a custom php.ini and apache config. Webapps using this image may access a database connection to a [MySQL](https://registry.hub.docker.com/u/library/mysql) or [MariaDB](https://registry.hub.docker.com/u/library/mariadb) container defined in the environment and/or linked at runtime. CORS is already bundled into the apache
rewrite rules fo the virutal host, so no need to worry about that.

## What is the Agave Platform?

The Agave Platform ([http://agaveapi.co](http://agaveapi.co)) is an open source, science-as-a-service API platform for powering your digital lab. Agave allows you to bring together your public, private, and shared high performance computing (HPC), high throughput computing (HTC), Cloud, and Big Data resources under a single, web-friendly REST API.

* Run scientific codes

  *your own or community provided codes*

* ...on HPC, HTC, or cloud resources

  *your own, shared, or commercial systems*

* ...and manage your data

  *reliable, multi-protocol, async data movement*

* ...from the web

  *webhooks, rest, json, cors, OAuth2*

* ...and remember how you did it

  *deep provenance, history, and reproducibility built in*

For more information, visit the [Agave Developer’s Portal](http://agaveapi.co) at [http://agaveapi.co](http://agaveapi.co).


## Extending this image

This image can be used as a base image for all PHP APIs. Simply create a Dockerfile that inherits this base image and add your PHP app to the web root folder at /var/www/html.

### Developing with this image

If you are developing with this image, mount your code into the `/var/www/html` directory in the container. Your local changes will be reflected instantly when you refresh your page.

```
docker run -h docker.example.com
           -p 80:80 \
           --name apache \
           -v `pwd`:/var/www/html \
           --link mysql:mysql
           -e DOCUMENT_ROOT=/var/www/html
           agaveapi/php-api-base:latest
```

Alternatively, you can specify a different web root if needed by your application. For example, if you had a Laravel project where the project `composer.json` file was located at `/usr/local/src/laravel/composer.json`, the following would start the container with the proper web root for the project.

```
docker run -h docker.example.com
           -p 80:80 \
           --name apache \
           -v /usr/local/src/laravel:/var/www \
           --link mysql:mysql
           -e DOCUMENT_ROOT=/var/www/public
           agaveapi/php-api-base:latest
```


### Running in production

When running in production, both the access and error logs will stream to standard out so they can be access via the Docker logs facility by default.

```
docker run -h docker.example.com \
           -p 80:80 \
           -p 443:443 \
           --name apache \
           -e MYSQL_USERNAME=agaveuser \
           -e MYSQL_PASSWORD=password \
           -e MYSQL_HOST=mysql \
           -e MYSQL_PORT=3306 \
           agaveapi/php-api-base:latest
```

### SSL Support

To add ssl support, volume mount your ssl cert, key, ca cert file, and ca chain file as needed. In the following example, a folder containing the necessary files is volume mounted to /ssl in the container.

```
docker run -h docker.example.com \
           -p 80:80 \
           -p 443:443 \
           --name apache \
           -e MYSQL_USERNAME=agaveuser \
           -e MYSQL_PASSWORD=password \
           -e MYSQL_HOST=mysql \
           -e MYSQL_PORT=3306 \
           -v `pwd`/ssl:/ssl \
           -e SSL_CERT=/ssl/docker_example_com_cert.cer \
           -e SSL_KEY=/ssl/docker.example.com.key \
           -e SSL_CA_CERT=/ssl/docker_example_com.cer \
           agaveapi/php-api-base:latest
```
