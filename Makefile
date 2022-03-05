PROJECT_NAME:=aws-ec2-pipeline-spring-boot
MAVEN_PROJECT_NAME:=basic-web-spring-boot

init:
	INIT_BUCKET_NAME=$(PROJECT_NAME)-init && \
	mvn clean -f $(MAVEN_PROJECT_NAME)/pom.xml && \
	zip -r $(PROJECT_NAME).zip * && \
	aws s3 mb s3://$${INIT_BUCKET_NAME} &&\
	aws s3 cp $(PROJECT_NAME).zip s3://$${INIT_BUCKET_NAME}/init/ && \
	aws cloudformation deploy \
		--capabilities CAPABILITY_NAMED_IAM \
		--template-file ./infra/pipeline/init.yml \
		--stack-name $(PROJECT_NAME)-init \
		--parameter-overrides \
			ProjectName=$(PROJECT_NAME) \
			ArtifactInputBucketName=$${INIT_BUCKET_NAME} && \
	./infra/utils/git_init.sh $(PROJECT_NAME)

deploy:
	MAVEN_PROJECT_VERSION=$$(./infra/utils/get_mvn_project_version.sh $(MAVEN_PROJECT_NAME)) && \
 	SUB_MODULE_SHA1=$$(git submodule status $(MAVEN_PROJECT_NAME) | grep -o "[0-9a-f]\{40\}") && \
	aws cloudformation deploy \
		--capabilities CAPABILITY_NAMED_IAM \
		--template-file ./infra/pipeline/cicd.yml \
		--stack-name $(PROJECT_NAME)-cicd \
		--parameter-overrides \
			ProjectName=$(PROJECT_NAME) \
			ProjectVersion=$${MAVEN_PROJECT_VERSION} \
			MavenProjectName=$(MAVEN_PROJECT_NAME) \
			InfrastructureStackName=$(PROJECT_NAME)-infrastructure \
			SubModuleSha1=$${SUB_MODULE_SHA1}

trigger:
	MAVEN_PROJECT_VERSION=$$(./infra/utils/get_mvn_project_version.sh $(MAVEN_PROJECT_NAME)) && \
	aws codepipeline start-pipeline-execution --name "$(PROJECT_NAME)-$${MAVEN_PROJECT_VERSION}"

destroy:
	INIT_BUCKET_NAME=$(PROJECT_NAME)-init && \
	aws s3 rm s3://$(PROJECT_NAME)-output --recursive || true && \
	aws s3 rm s3://$${INIT_BUCKET_NAME} --recursive || true && \
	aws s3 rb s3://$${INIT_BUCKET_NAME}  || true && \
	aws cloudformation delete-stack --stack-name $(PROJECT_NAME)-cicd || true && \
	aws cloudformation delete-stack --stack-name $(PROJECT_NAME)-infrastructure || true && \
	aws cloudformation delete-stack --stack-name $(PROJECT_NAME)-init || true && \
	git remote remove origin  && \
	git remote add origin git@github.com:erwanjouan/$(PROJECT_NAME).git || true

check:
	cd ./infra/utils/ && ./control_page.sh && cat control_page.html && cd -
