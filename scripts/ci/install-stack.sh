#!/bin/sh

BINDIR="$1"; shift

stack_dir="$(mktemp --tmpdir -d "install-stack.XXXXXXXXX")"
trap 'rm -rf '"$stack_dir" 0 2 15

ver=$(ghc --numeric-version)
resolver=$(cat stack-resolvers | grep -F "$ver" | awk '{ print $2 }')

cabal v2-install \
      --symlink-bindir="$BINDIR" \
      --package-env=/dev/null \
      hpack || exit 1

cd "$stack_dir"

git clone \
    --depth=1 \
    --branch=stable \
    https://github.com/commercialhaskell/stack "$stack_dir" \
        || exit 1

wget -q https://www.stackage.org/"$resolver"/cabal.config \
     -O /dev/stdout | grep -v -e ' \+stack ' -e ' \+hpack ' -e ' \+Cabal '\
                           > cabal.project.freeze

echo 'packages: .' > cabal.project

"$BINDIR/hpack"
cabal v2-install \
      --symlink-bindir="$BINDIR" \
      --package-env=/dev/null \
      --constraint "Cabal == 2.4.0.1" \
      . || exit 1
