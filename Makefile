TAG := $(shell git describe --tags --always --dirty)
IMAGE ?= ghcr.io/superbrothers/myhubot:$(TAG)
ARCH ?= amd64
ALL_ARCH ?= amd64 arm64

DOCKER_BUILD ?= DOCKER_BUILDKIT=1 docker build --pull --progress=plain
QEMU_VERSION ?= 5.2.0-2

docker-build:
ifneq ($(ARCH),amd64)
	docker run --rm --privileged docker.io/multiarch/qemu-user-static:$(QEMU_VERSION) --reset -p yes
endif
	docker buildx version
	BUILDER=$$(docker buildx create --use)
	$(DOCKER_BUILD) --platform $(ARCH) -t $(IMAGE)-$(ARCH) .
	docker buildx rm "$${BUILDER}"

docker-build-%:
	$(MAKE) ARCH=$* docker-build

.PHONY: docker-build-all
docker-build-all: $(addprefix docker-build-,$(ALL_ARCH))

.PHONY: docker-push
docker-push:
	docker push $(IMAGE)-$(ARCH)

docker-push-%:
	$(MAKE) ARCH=$* docker-push

.PHONY: docker-push-all
docker-push-all: $(addprefix docker-push-,$(ALL_ARCH))

.PHONY: docker-manifest-push
docker-manifest-push:
	docker manifest create --amend $(IMAGE) $(addprefix $(IMAGE)-,$(ALL_ARCH))
	@for arch in $(ALL_ARCH); do docker manifest annotate --arch $${arch} $(IMAGE) $(IMAGE)-$${arch}; done
	docker manifest push --purge $(IMAGE)

.PHONY: push-all
push-all: docker-push-all docker-manifest-push
