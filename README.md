## Agave PHP API Base Image

This is the base image used to create the Agave PHP API Images. It has Apache2 and PHP 5.5 installed and configured with a custom php.ini and apache config.

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

If you are developing with this image, simply mount your code into the `/var/www/html` directory in the container. Your local changes will be reflected instantly when you refresh your page.

```
docker run -p 80:80 -v `pwd`:/var/www/html --name agave-php agaveapi/php-api-base
```

### Running in production

When running in production, take advantage of the centralized logging available from Agave's data volume by mounting the container logs into the  data volume. This will provide you persistent logs and, if you are using a db, persistent database content.

<pre>
docker run --name mydata agaveapi/api-data-volume echo "Data volume for my APIs"

docker run -d -e "SERVICE_NAME=my-php-api"      
           -p 80:80                    \ # HTTP
           --volumes-from mydata     \ # log to data volume
           -v /agave/logs/my-php-api:/var/log/apache2 		   --name my-php-api
           agaveapi/php-api-base
</pre>