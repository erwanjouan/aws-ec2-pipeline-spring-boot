#!/bin/sh
mvn \
  org.apache.maven.plugins:maven-help-plugin:2.1.1:evaluate \
  -Dexpression=project.version \
  -f code/pom.xml | grep -v '\['