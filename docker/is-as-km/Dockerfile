# ------------------------------------------------------------------------
# Dockerfile for WSO2 Identity Server as Key Manager
# ------------------------------------------------------------------------

# set base Docker image to WSO2 Identity Server Docker image with latest WSO2 Updates
ARG BASE_DOCKER_IMAGE_REGISTRY="docker.wso2.com"
ARG BASE_PRODUCT_VERSION=5.11.0.0
FROM ${BASE_DOCKER_IMAGE_REGISTRY}/wso2is:${BASE_PRODUCT_VERSION}

# build arguments for external artifacts
ARG MYSQL_CONNECTOR_VERSION=8.0.17

# add MySQL JDBC connector to server home as a third party library
ADD --chown=wso2carbon:wso2 https://repo1.maven.org/maven2/mysql/mysql-connector-java/${MYSQL_CONNECTOR_VERSION}/mysql-connector-java-${MYSQL_CONNECTOR_VERSION}.jar ${WSO2_SERVER_HOME}/repository/components/dropins/

# copy extensions to the identity server home
COPY dropins ${WSO2_SERVER_HOME}/repository/components/dropins/
# copy customized webapps to the identity server home
COPY webapps ${WSO2_SERVER_HOME}/repository/deployment/server/webapps/
