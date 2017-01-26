#!/bin/bash

set -e

secrets=/src/secrets.toml

/usr/sbin/rsyslogd

export RUST_BACKTRACE=1

set -ex

letsencrypt certonly \
    --webroot \
    -w /usr/share/nginx/html \
    -d `tq nginx.hostname < $secrets`

rbars $secrets /src/nginx.conf.template > /tmp/nginx.conf
nginx -c /tmp/nginx.conf

cancelbot \
  --travis `tq cancelbot.travis-token < $secrets` \
  --appveyor `tq cancelbot.rust-appveyor-token < $secrets` \
  --appveyor-account rust-lang \
  --branch auto \
  --interval 60 \
  rust-lang/rust \
  2>&1 | logger --tag cancelbot-rust &

cancelbot \
  --travis `tq cancelbot.travis-token < $secrets` \
  --appveyor `tq cancelbot.cargo-appveyor-token < $secrets` \
  --appveyor-account rust-lang-libs \
  --branch auto-cargo \
  --interval 60 \
  rust-lang/cargo \
  2>&1 | logger --tag cancelbot-cargo &

rbars $secrets /src/homu.toml.template > /tmp/homu.toml
homu -c /tmp/homu.toml 2>&1 | logger --tag homu
