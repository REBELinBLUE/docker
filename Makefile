.DEFAULT_GOAL := help
.PHONY: help
.SILENT:

GREEN  := $(shell tput -Txterm setaf 2)
WHITE  := $(shell tput -Txterm setaf 7)
YELLOW := $(shell tput -Txterm setaf 3)
RESET  := $(shell tput -Txterm sgr0)

APPDIR="application/"

run: docker-up

build: install docker-up migrate create-admin

update: pull install docker-up
	docker-compose exec php-fpm php artisan app:update

install: clone
	@cd $(APPDIR) && $(MAKE) install

install-dev: clone
	@cd $(APPDIR) && $(MAKE) install-dev

clone:
	@if [ ! -e ./$(APPDIR) ]; then \
		git clone https://github.com/REBELinBLUE/deployer $(APPDIR); \
		cp env ./$(APPDIR)/.env; \
	fi

pull: clone
	@cd $(APPDIR) && git pull

docker-up:
	docker-compose up -d

docker-down:
	docker-compose down

create-admin:
	docker-compose exec php-fpm php artisan deployer:create-user admin admin@example.com changeme --no-email

migrate:
	docker-compose exec php-fpm php artisan migrate

mysql:
	docker-compose exec mysql mysql --i-am-a-dummy -udeployer -psecret deployer

logs:
	docker-compose logs

clean: docker-stop
	@cd $(APPDIR) && $(MAKE) clean

## Prints this help
help:
	@echo "\nUsage: make ${YELLOW}<target>${RESET}\n\nThe following targets are available:\n"
	@awk -v skip=1 \
		'/^##/ { sub(/^[#[:blank:]]*/, "", $$0); doc_h=$$0; doc=""; skip=0; next } \
		 skip  { next } \
		 /^#/  { doc=doc "\n" substr($$0, 2); next } \
		 /:/   { sub(/:.*/, "", $$0); printf "  ${YELLOW}%-30s${GREEN}%s${RESET} %s\n", $$0, doc_h, doc; skip=1 }' \
		$(MAKEFILE_LIST)
