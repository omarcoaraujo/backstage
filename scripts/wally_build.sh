#!/usr/bin/env bash
set -euo pipefail

rm -rf build/wally
mkdir -p build/wally

cp -r src build/wally/src
cp LICENSE README.md default.project.json build/wally/
find build/wally/src -name '*.luau' -exec sed -i 's#roblox_packages/vide#vide#g' {} +

version=$(grep -m1 '^version' pesde.toml | cut -d'"' -f2)

cat > build/wally/wally.toml <<TOML
[package]
name = "omarcoaraujo/backstage"
version = "$version"
registry = "https://github.com/UpliftGames/wally-index"
realm = "shared"
description = "Live tuning panel for Roblox Studio: edit game values in real time"
license = "MIT"
authors = ["omarcoaraujo <omarcoaraujo@outlook.com>"]
repository = "https://github.com/omarcoaraujo/backstage"

[dependencies]
vide = "centau/vide@0.4.0"
TOML
