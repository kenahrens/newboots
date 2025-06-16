IMAGE_NAME ?= ghcr.io/kenahrens/newboots
TAG ?= latest

.PHONY: test jar docker run lint deploy patch check-k8s-image docker-client docker-server

test:
	mvn test

jar:
	mvn clean package

run:
	mvn spring-boot:run

docker-client:
	docker build -f Dockerfile.client -t ghcr.io/kenahrens/newboots-client:latest .
	docker push ghcr.io/kenahrens/newboots-client:latest

docker-server:
	docker build -f Dockerfile.server -t ghcr.io/kenahrens/newboots-server:latest .
	docker push ghcr.io/kenahrens/newboots-server:latest

docker: docker-client docker-server
	docker build -t $(IMAGE_NAME):$(TAG) .
	docker push $(IMAGE_NAME):$(TAG)

lint:
	mvn checkstyle:check

deploy:
	kubectl apply -k k8s/overlays/default
	kubectl apply -k k8s/overlays/microservices

patch:
	kubectl patch deployment newboots -n microservices --patch-file k8s/patch-inject-newboots.yaml
	kubectl patch deployment newboots -n default --patch-file k8s/patch-inject-newboots.yaml

check-k8s-image:
	grep 'image: ghcr.io/kenahrens/newboots:latest' k8s/base-default/deploy.yaml
