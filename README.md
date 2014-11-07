## Agave PHP API Base Image

This is the base image used to create the Agave PHP API Images. It has Apache2 and PHP 5.4 installed and configured with a custom php.ini and apache config.

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


## Using this image

This image can be used as a base image for all PHP APIs. Simply create a Dockerfile that inherits this base image and add your PHP app to the web root folder at /var/www/html.


### Running this image

This image extends the trusted php:5.4-apache image.

		> docker run -d -h agave.example.com         	\
		           -p 8888:80                   			\ # Apache
		           --name apache-php
               -v `pwd`/logs:/var/www/http        \ # mount the log directory
		           agaveapi/php-api-base
