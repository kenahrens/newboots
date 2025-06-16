IMAGE_NAME ?= ghcr.io/kenahrens/newboots
TAG ?= latest

.PHONY: test jar docker run lint deploy patch

test:
	mvn test

jar:
	mvn clean package

run:
	mvn spring-boot:run

docker:
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
