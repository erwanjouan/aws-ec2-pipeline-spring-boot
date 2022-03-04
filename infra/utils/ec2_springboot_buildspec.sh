#!/bin/sh
cat <<EOF > buildspec.yml
version: 0.2
env:
  git-credential-helper: yes
phases:
  install:
    runtime-versions:
      java: corretto11
    commands:
      - java -version
  build:
    commands:
      - echo Build started on `date`
      - mvn clean install
  post_build:
    commands:
      - cp \$MAVEN_PROJECT_NAME/target/*.jar app.jar
      - cp infra/pipeline/infrastructure.yml .
      - echo Build completed on `date`
artifacts:
  files:
    - app.jar
    - infrastructure.yml
  discard-paths: yes
cache:
  paths:
    - '/root/.m2/**/*'
EOF