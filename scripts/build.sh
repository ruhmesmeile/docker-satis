#!/usr/bin/env bash
# check for first argument repository-url, to only reload that specific repo
if [ "$#" -lt 1 ]; then
  sudo -u www-data bash -c "id; cd /satisfy && /satisfy/bin/satis build --skip-errors --no-ansi --verbose"
else
  REPOSITORY=$(echo ${1} | sed "s/ssh:\/\/git@bitbucket-internal\.services\.ruhmesmeile\.local:7999/ssh:\/\/git@bitbucket\.ruhmesmeile\.tools:7999/g")
  sudo -u www-data bash -c "id; cd /satisfy && /satisfy/bin/satis build --skip-errors --no-ansi --verbose --repository-url $REPOSITORY"
fi
