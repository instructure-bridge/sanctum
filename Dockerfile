FROM ruby:2.5-alpine

USER root

ENV VERSION 1.0.1
ADD https://releases.hashicorp.com/vault/${VERSION}/vault_${VERSION}_linux_amd64.zip /tmp/
ADD https://releases.hashicorp.com/vault/${VERSION}/vault_${VERSION}_SHA256SUMS /tmp/
ADD https://releases.hashicorp.com/vault/${VERSION}/vault_${VERSION}_SHA256SUMS.sig /tmp/

# Install additional dependencies
# As well as nice to haves locally
RUN apk --no-cache add git vim busybox-extras curl gpgme \
  && gpg --keyserver pgp.mit.edu --recv-key 0x348FFC4C \
  && gpg --verify /tmp/vault_${VERSION}_SHA256SUMS.sig \
  && cat /tmp/vault_${VERSION}_SHA256SUMS | grep linux_amd64 | sha256sum /tmp/vault_${VERSION}_linux_amd64.zip \
  && unzip /tmp/vault_${VERSION}_linux_amd64.zip \
  && mv vault /usr/local/bin/ \
  && rm -rf /tmp/*

# Setup up app directory
ENV APP_HOME /usr/src/app/
WORKDIR $APP_HOME

# Add app code
COPY . $APP_HOME

# Install gems
RUN bundle install --jobs=8

# Install sanctum gem
RUN bundle exec rake install
