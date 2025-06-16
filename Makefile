IMAGE_NAME ?= ghcr.io/kenahrens/newboots
TAG ?= latest

.PHONY: test jar docker

test:
	mvn test

jar:
	mvn clean package

docker:
	docker build -t $(IMAGE_NAME):$(TAG) .
	docker push $(IMAGE_NAME):$(TAG)
