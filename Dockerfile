FROM centos/nginx-18-centos7

# This image provides a Node.JS environment you can use to run your Node.JS
# applications.

MAINTAINER Jeremy Zahner <zahner@joshmartin.ch>

EXPOSE 8080

USER root

# This image will be initialized with "npm run $NPM_RUN"
# See https://docs.npmjs.com/misc/scripts, and your repo's package.json
# file for possible values of NPM_RUN

ENV NPM_BUILD_COMMAND=start \
    NODE_VERSION=7.7.4 \
    NPM_CONFIG_LOGLEVEL=info \
    NPM_CONFIG_PREFIX=$HOME/.npm-global \
    PATH=$HOME/node_modules/.bin/:$HOME/.npm-global/bin/:$PATH \
    NPM_VERSION=4 \
    YARN_VERSION=0.21.3 \
    DEBUG_PORT=5858 \
    NODE_ENV=production \
    DEV_MODE=false

LABEL io.k8s.description="Plattform for building and running static sites with NodeJS and NGINX." \
      io.k8s.display-name="build-nodejs-nginx" \
      io.openshift.expose-services="8080:http" \
      io.openshift.tags="builder,nodejs,nodejs$NODE_VERSION,nginx" \
      com.redhat.deployments-dir="/opt/app-root/src"

# Download and install a binary from nodejs.org
# Add the gpg keys listed at https://github.com/nodejs/node
RUN set -ex && \
  for key in \
    9554F04D7259F04124DE6B476D5A82AC7E37093B \
    94AE36675C464D64BAFA68DD7434390BDBE9B9C5 \
    0034A06D9D9B0064CE8ADF6BF1747F4AD2306D93 \
    FD3A5288F042B6850C66B31F09FE44734EB7990E \
    71DCFD284A79C3B38668286BC97EC7A07EDE3FC1 \
    DD8F2338BAE7501E3DD5AC78C2F7D83545D \
    B9AE9905FFD7803F25714661B63B535A4C206CA9 \
    C4F0DFFF4E8C1A8236409D08E73BC641CC11F4C8 \
  ; do \
    gpg --keyserver ha.pool.sks-keyservers.net --recv-keys "$key"; \
  done && \
  INSTALL_PKGS="httpd-tools bzip2 nss_wrapper" && \
  yum install -y --setopt=tsflags=nodocs $INSTALL_PKGS && \
  rpm -V $INSTALL_PKGS && \
  yum clean all -y && \
  curl -o node-v${NODE_VERSION}-linux-x64.tar.gz -sSL https://nodejs.org/dist/v${NODE_VERSION}/node-v${NODE_VERSION}-linux-x64.tar.gz && \
  curl -o SHASUMS256.txt.asc -sSL https://nodejs.org/dist/v${NODE_VERSION}/SHASUMS256.txt.asc && \
  gpg --batch -d SHASUMS256.txt.asc | grep " node-v${NODE_VERSION}-linux-x64.tar.gz\$" | sha256sum -c - && \
  tar -zxf node-v${NODE_VERSION}-linux-x64.tar.gz -C /usr/local --strip-components=1 && \
  npm install -g npm@${NPM_VERSION} && \
  wget https://dl.yarnpkg.com/rpm/yarn.repo -O /etc/yum.repos.d/yarn.repo  && \
  yum install -y --setopt=tsflags=nodocs yarn-${YARN_VERSION} && \
  rpm -V yarn-${YARN_VERSION} && \
  yum clean all -y && \
  find /usr/local/lib/node_modules/npm -name test -o -name .bin -type d | xargs rm -rf; \
  rm -rf ~/node-v${NODE_VERSION}-linux-x64.tar.gz ~/SHASUMS256.txt.asc /tmp/node-v${NODE_VERSION} ~/.npm ~/.node-gyp ~/.gnupg \
    /usr/share/man /tmp/* /usr/local/lib/node_modules/npm/man /usr/local/lib/node_modules/npm/doc /usr/local/lib/node_modules/npm/html

# Add s2i nginx custom files
ADD ./contrib/nginx.default.conf /opt/app-root/etc/nginx.default.conf

# Copy the S2I scripts from the specific language image to $STI_SCRIPTS_PATH
COPY ./s2i/bin/ $STI_SCRIPTS_PATH

USER 1001

# Set the default CMD to print the usage of the language image
CMD $STI_SCRIPTS_PATH/usage
