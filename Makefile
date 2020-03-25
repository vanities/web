IMAGE_NAME ?= vanities/web
IMAGE_VERSION ?= latest
DOCKER_TAG := $(IMAGE_NAME):$(IMAGE_VERSION)

DOCKER_PATH = docker-compose.yml
WEB_URL ?= catwebm.com
RIOT_POSTGRES_PASSWORD ?= some-pass

EC2_PRIVATE_KEY_PATH ?= catwebm.pem
# ec2-3-132-85-69.us-east-2.compute.amazonaws.com
EC2_URL ?= ubuntu@3.132.85.69

# apps
NGINX := nginx/$(DOCKER_PATH)
SANIC := sanic/$(DOCKER_PATH)
RIOT := riot/$(DOCKER_PATH)

DOCKER_COMPOSE = docker-compose \
				 --file $(NGINX) \
				 --file $(SANIC)

# init
DOCKER_INIT_PATH = docker-compose.init.yml
RIOT_INIT := riot/$(DOCKER_INIT_PATH)
DOCKER_COMPOSE_INIT = docker-compose \
					  --file $(RIOT_INIT)

image:
	$(DOCKER_COMPOSE) build

shell:
	 ssh -i $(EC2_PRIVATE_KEY_PATH) $(EC2_URL)

init:
	sed -e "s/server_name.*/server_name $(WEB_URL);/g" nginx/nginx.init.conf > tmp
	mv -- tmp nginx/nginx.init.conf
	sed -e "s/server_name.*/server_name $(WEB_URL);/g" nginx/nginx.conf > tmp
	mv -- tmp nginx/nginx.conf
	sed -e "s/Host:.*/Host:$(WEB_URL);\"/g" nginx/docker-compose.yml > tmp
	mv -- tmp nginx/docker-compose.yml
	docker-compose --rm --file nginx/docker-compose.init.yml up

up: image
	POSTGRES_PASSWORD=$(RIOT_POSTGRES_PASSWORD) \
	FQDN=$(WEB_URL) \
	  $(DOCKER_COMPOSE) up

release: image
	docker push $(DOCKER_TAG)

release_aws:
	 rsync -i $(EC2_PRIVATE_KEY_PATH) \
	   --exclude $(EC2_PRIVATE_KEY_PATH) \
	   -r . $(EC2_URL):~/

renew_cert:
	docker-compose --rm --file nginx/docker-compose.init.yml up -d
	docker run -it --rm \
		-v /${PWD}/certs:/etc/letsencrypt \
		-v /${PWD}/certs-data:/data/letsencrypt \
		deliverous/certbot certonly \
		--webroot --webroot-path=/data/letsencrypt -d $(WEB_URL)

service:
	sudo cp services/* /etc/systemd/system
	systemctl start web.service
	systemctl enable web.service

down: 
	 $(DOCKER_COMPOSE) down
	 $(DOCKER_COMPOSE_INIT) down

default: image
