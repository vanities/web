SERVICE_NAME = web
IMAGE_NAME ?= vanities/$(SERVICE_NAME)
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
				 --file $(SANIC) \
				 --file $(NGINX) \


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

up:
	$(DOCKER_COMPOSE) up

config:
	$(DOCKER_COMPOSE) config

release_aws:
	 rsync -i $(EC2_PRIVATE_KEY_PATH) \
	   --exclude $(EC2_PRIVATE_KEY_PATH) \
	   -r . $(EC2_URL):~/

renew_cert:

service_start:
	sudo cp services/* /etc/systemd/system
	sudo systemctl start $(SERVICE_NAME).service
	sudo systemctl enable $(SERVICE_NAME).service

service_restart:
	sudo systemctl restart $(SERVICE_NAME).service

service_reload:
	sudo systemctl daemon-reload

service_status:
	sudo systemctl status $(SERVICE_NAME).service
down: 
	 $(DOCKER_COMPOSE) down

default: image
