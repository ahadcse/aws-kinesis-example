#!/usr/bin/env bash

ENVIRONMENT ?= dev
SERVICE ?= aws-kinesis-example
AWS_REGION ?= eu-west-1
BITBUCKET_BUILD_NUMBER ?= localbuild

# Following bucket should be available. Otherwise deployment will not work. We can add this to CloudFormation template and deploy that before actial deployment.
# TODO: Add deployment bucket to template
ARTIFACTS_BUCKET:=artifactory-$(ENVIRONMENT)
ARTIFACTS_PREFIX:=$(SERVICE)

cfn-package = mkdir -p cloudformation/dist && \
	aws cloudformation package \
	--template-file cloudformation/${1}.yml \
	--output-template-file cloudformation/dist/${1}.yml \
	--s3-bucket $(ARTIFACTS_BUCKET) \
	--s3-prefix $(ARTIFACTS_PREFIX)

cfn-deploy = aws cloudformation deploy \
	--template-file cloudformation/dist/${1}.yml \
	--stack-name $(SERVICE) \
	--capabilities CAPABILITY_NAMED_IAM \
	--region $(AWS_REGION) \
	--tags BitbucketBuildNumber=$(BITBUCKET_BUILD_NUMBER) \
	--no-fail-on-empty-changeset \
	--parameter-overrides \
		Service=$(SERVICE) \
		Environment=$(ENVIRONMENT) \
		Region=${AWS_REGION}

.PHONY: deploy
deploy:
	$(call cfn-package,cf)
	$(call cfn-deploy,cf)

.PHONY: package
package:
	$(call cfn-package,cf)

lint:
	@echo "Running esling"
	npm run lint

.PHONY: test
test:
	@echo "Running unit tests"
	npm run test

install:
	npm install
	for f in src/*; do \
		([ -d $$f ] && cd "$$f" && npm install) \
  done;

install_production:
	npm install --production
	for f in src/*; do \
		([ -d $$f ] && cd "$$f" && npm install --production) \
  done;

prune:
	npm prune --production
	for f in src/*; do \
		([ -d $$f ] && cd "$$f" && npm prune --production) \
  done;

ci: install lint prune
