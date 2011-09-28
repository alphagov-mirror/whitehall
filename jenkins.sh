#!/bin/bash -x
source '/usr/local/lib/rvm'
export GEM_HOME="/home/jenkins/bundles/${JOB_NAME}"
mkdir -p "${GEM_HOME}"
bundle install && bundle exec rake db:create db:migrate db:test:prepare && RAILS_ENV=test bundle exec rake test cucumber --trace