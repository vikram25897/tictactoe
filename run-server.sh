#!/usr/bin/env bash

set -e

echo "Setting up environment"
asdf install

echo "Fetching And Installing Dependencies"
mix deps.get
mix local.hex --force
mix local.rebar --force

echo "Starting Server"
mix phx.server