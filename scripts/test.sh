#!/usr/bin/env bash
# Runs the test suite (make installcheck) against one or more PostgreSQL
# versions using Docker. No local PostgreSQL installation required.
#
#   scripts/test.sh            # default versions
#   scripts/test.sh 14 18      # chosen versions
set -euo pipefail

cd "$(dirname "$0")/.."
SRC="$(pwd)"
if command -v cygpath >/dev/null 2>&1; then
	SRC="$(cygpath -w "$SRC")"   # Git Bash on Windows
fi
export MSYS_NO_PATHCONV=1

VERSIONS="${*:-14 15 16 17 18}"
failed=""

for v in $VERSIONS; do
	name="jsonvd-test-$v"
	echo "==> PostgreSQL $v"
	docker rm -f "$name" >/dev/null 2>&1 || true
	docker run -d --name "$name" -e POSTGRES_HOST_AUTH_METHOD=trust \
		-v "$SRC:/src:ro" "postgres:$v" >/dev/null

	# The temporary initdb server only listens on the socket; wait for the real one over TCP.
	until docker exec "$name" pg_isready -h 127.0.0.1 -U postgres >/dev/null 2>&1; do sleep 1; done

	if docker exec "$name" bash -c "
		set -e
		export DEBIAN_FRONTEND=noninteractive
		apt-get update -qq >/dev/null
		apt-get install -y -qq make postgresql-server-dev-$v >/dev/null
		cp -r /src /build && cd /build
		make install >/dev/null
		make installcheck PGUSER=postgres || { cat regression.diffs; exit 1; }
	"; then
		echo "==> PostgreSQL $v: OK"
	else
		echo "==> PostgreSQL $v: FAILED"
		failed="$failed $v"
	fi

	docker rm -f "$name" >/dev/null
done

if [ -n "$failed" ]; then
	echo "Failed:$failed"
	exit 1
fi
echo "All versions passed: $VERSIONS"
