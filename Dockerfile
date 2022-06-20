FROM ruby:3.0.3-bullseye AS base
LABEL maintainer="jdwright@ldc.upenn.edu"
RUN apt-get update -yqq && apt-get install -yqq --no-install-recommends apt-transport-https
RUN curl -sL https://deb.nodesource.com/setup_16.x | bash -
RUN curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add -
RUN echo "deb https://dl.yarnpkg.com/debian/ stable main" | tee /etc/apt/sources.list.d/yarn.list
RUN apt-get update -yqq && apt-get install -yqq --no-install-recommends netcat nodejs yarn ffmpeg libpq5

RUN gem install sassc -v 2.4.0
RUN gem install pg -v 1.2.3
RUN gem install bootsnap -v 1.9.1
WORKDIR /ua
COPY package* /ua
COPY Gemfile* /ua

FROM base AS dev

RUN npm install
#ENV BUNDLE_PATH /gems
RUN bundle install
COPY . /ua/
RUN bundle lock --add-platform x86_64-linux
RUN ["chmod", "+x", "/ua/wait-for"]
ENTRYPOINT ["./docker-entrypoint.sh"]
CMD ["bin/rails", "s", "-b", "0.0.0.0"]
#CMD ["sleep", "300"]

FROM base AS build

ENV BUNDLE_APP_CONFIG=.bundle
ENV NODE_ENV=production
ENV RAILS_ENV=container_build
ENV RACK_ENV=container_build

COPY --from=dev /ua/package* /ua
RUN npm install

# set shell because echo -e fails in default shell; no idea why
SHELL ["/bin/bash", "-c"]
COPY --from=dev /ua/Gemfile* /ua
RUN bundle config set --local deployment 'true' && \
    bundle config set --local without 'development:test' && \
    bundle install
COPY --from=dev /ua /ua
RUN bin/rails assets:precompile

# do some cleanup of the bundle directory
# There's some junk left over from the gem builds, like 100mb of
# .o files, etc.

RUN find vendor -name "*.o" -delete \
             -o -name "*.c" -delete \
             -o -name "*.h" -delete \
             -o -name "*.cpp" -delete \
             -o -name "*.hpp" -delete \
             -o -name "*.java" -delete \
             -o -name "*.md" -delete \
             -o -name "*.rdoc" -delete \
             -o -name "*LICENSE*" -delete \
             -o -name "Rakefile" -delete \
             -o -name "Gemfile" -delete \
             -o -name "Makefile" -delete \
             -o -name "CHANGELOG" -delete \
             -o -name "CHANGES" -delete \
             -o -name "COPYING" -delete \
             -o -name ".gitignore" -delete \
             -o -path "*/release_notes/*" -delete \
             -o -name ".rspec" -delete


 FROM ruby:3.0.3-bullseye as deployable
 ENV BUNDLE_APP_CONFIG=.bundle
 ENV RAILS_ENV=aws
 ENV RACK_ENV=aws
 COPY --from=build /ua /ua
 RUN apt-get update && \ 
     apt-get upgrade -yqq && \
     apt-get install -yqq --no-install-recommends nodejs ffmpeg libpq5 imagemagick openssh-server libsqlite3-0
 RUN apt-get autoclean
 COPY shell/sshd_config /etc/ssh/sshd_config
 COPY shell/docker-entrypoint.sh /ua/docker-entrypoint.sh
 COPY shell/bashrc /root/.bashrc
 ADD shell/bin.tgz  /root/

 ADD https://s3.amazonaws.com/rds-downloads/rds-combined-ca-bundle.pem /root/.postgresql/root.crt
 WORKDIR /ua
 ENTRYPOINT ["./docker-entrypoint.sh"]
 CMD bundle exec bin/rails s -b 0.0.0.0 
