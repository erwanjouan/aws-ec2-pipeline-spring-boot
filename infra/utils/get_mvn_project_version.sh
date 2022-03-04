#!/bin/sh
mvn \
  org.apache.maven.plugins:maven-help-plugin:2.1.1:evaluate \
  -Dexpression=project.version \
  -f $1/pom.xml | grep -v '\['