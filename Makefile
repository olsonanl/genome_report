TOP_DIR = ../..
DEPLOY_RUNTIME ?= /disks/patric-common/runtime
TARGET ?= /tmp/deployment
include $(TOP_DIR)/tools/Makefile.common

SERVICE_SPEC = 
SERVICE_NAME = genome_report
SERVICE_DIR  = $(SERVICE_NAME)
SERVICE_APP_DIR      = $(TARGET)/lib/$(SERVICE_NAME)

APP_DIR = .
APP_COMPONENTS = config.json node_modules scripts templates lib

PATH := $(DEPLOY_RUNTIME)/build-tools/bin:$(PATH)
NPM = $(DEPLOY_RUNTIME)/bin/npm-v8
NODE = $(DEPLOY_RUNTIME)/bin/node-v8
export NODE

DATA_API_URL = https://p3.theseed.org/services/data_api
TEMPLATE_DIR = $(shell pwd)/templates
DEPLOY_TEMPLATE_DIR = $(SERVICE_APP_DIR)/templates

TPAGE_BUILD_ARGS =  \
	--define kb_top=$(TARGET) \
	--define kb_runtime=$(DEPLOY_RUNTIME) \
	--define template_dir=$(TEMPLATE_DIR)

TPAGE_DEPLOY_ARGS =  \
	--define kb_top=$(DEPLOY_TARGET) \
	--define kb_runtime=$(DEPLOY_RUNTIME) \
	--define template_dir=$(DEPLOY_TEMPLATE_DIR)

TPAGE_ARGS = \
	--define kb_service_name=$(SERVICE_NAME) \
	--define kb_service_dir=$(SERVICE_DIR) \
	--define kb_service_port=$(SERVICE_PORT) \
	--define kb_psgi=$(SERVICE_PSGI) \
	--define kb_app_dir=$(SERVICE_APP_DIR) \
	--define kb_app_script=$(APP_SCRIPT) \
	--define data_api_url=$(DATA_API_URL)

default: build-app $(BIN_NODEJS)

build-app: npm.completed config.json

npm.completed: package.json
	cd $(APP_DIR); $(NPM) install
	touch npm.completed

config.json: config.json.tt Makefile 
	$(TPAGE) $(TPAGE_BUILD_ARGS) $(TPAGE_ARGS) $< > $@

dist: 

test: 

deploy: deploy-client

deploy-all: deploy-client deploy-service

deploy-client: deploy-app deploy-nodejs-scripts

deploy-service: 

deploy-app: build-app 
	-mkdir $(SERVICE_APP_DIR)
	cd $(APP_DIR); rsync --delete -ar $(APP_COMPONENTS) $(SERVICE_APP_DIR)
	$(TPAGE) $(TPAGE_DEPLOY_ARGS) $(TPAGE_ARGS) config.json.tt > $(SERVICE_APP_DIR)/config.json

deploy-docs:
	-mkdir -p $(TARGET)/services/$(SERVICE_DIR)/webroot/.
	cp docs/*.html $(TARGET)/services/$(SERVICE_DIR)/webroot/.

deploy-nodejs-scripts:
	if [ "$(KB_OVERRIDE_TOP)" != "" ] ; then sbase=$(KB_OVERRIDE_TOP) ; else sbase=$(TARGET); fi; \
	export KB_TOP=$(TARGET); \
	export KB_RUNTIME=$(DEPLOY_RUNTIME); \
	for src in $(SRC_NODEJS) ; do \
		basefile=`basename $$src`; \
		base=`basename $$src .js`; \
		echo install $$src $$base ; \
		$(WRAP_NODEJS_SCRIPT) "$$sbase/lib/$(SERVICE_NAME)/scripts/$$basefile" $(TARGET)/bin/$$base ; \
	done 


build-libs:

$(BIN_DIR)/%: scripts/%.js $(TOP_DIR)/user-env.sh Makefile
	$(WRAP_NODEJS_SCRIPT) '$$KB_TOP/modules/$(CURRENT_DIR)/$<' $@


include $(TOP_DIR)/tools/Makefile.common.rules
