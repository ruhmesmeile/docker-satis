#!/usr/bin/env bash
SATIS_PATH="/satisfy/vendor"
SATIS_BIN="/satisfy/bin/satis"
SATIS_PUBLIC="/satisfy/web/"

# check for first argument repository-url, to only reload that specific repo
if [ "$#" -lt 1 ]; then
  ${SATIS_BIN} -v -n build /app/config.json ${SATIS_PUBLIC}
else
  ${SATIS_BIN} -v -n build --repository-url "$1" /app/config.json ${SATIS_PUBLIC}
fi



