IMAGE_NAME ?= ghcr.io/kenahrens/newboots
TAG ?= latest

.PHONY: test jar docker run lint

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
