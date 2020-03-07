IMAGE_NAME ?= vanities/web
IMAGE_VERSION ?= latest
DOCKER_TAG := $(IMAGE_NAME):$(IMAGE_VERSION)

DOCKER_PATH = docker-compose.yml
WEB_URL ?= catwebm.com
RIOT_POSTGRES_PASSWORD ?= some-pass

EC2_PRIVATE_KEY_PATH ?= keys.pem
EC2_URL ?=ubuntu@ec2-18-224-138-105.us-east-2.compute.amazonaws.com

# apps
RIOT := riot/$(DOCKER_PATH)

DOCKER_COMPOSE = docker-compose \
				 --file $(RIOT)

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
	sed -e "s/server_name:.*/server_name:$(WEB_URL)/g" riot/nginx.init.conf > tmp
	mv -- tmp riot/nginx.init.conf
	sed -e "s/server_name:.*/server_name:$(WEB_URL)/g" riot/nginx.conf > tmp
	mv -- tmp riot/nginx.conf
	POSTGRES_PASSWORD=$(RIOT_POSTGRES_PASSWORD) \
	FQDN=$(WEB_URL) \
	  $(DOCKER_COMPOSE_INIT) up -d
	riot/./renew-cert.sh $(WEB_URL)
	$(DOCKER_COMPOSE_INIT) down

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

down: 
	 $(DOCKER_COMPOSE) down
	 $(DOCKER_COMPOSE_INIT) down

default: image