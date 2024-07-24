#!/bin/bash

if [ -n "$1" ]; then
	ENV="--environment $1"
else
	ENV=""
fi

echo starting hugo-dev on http://localhost:8095

export HUGO_VERSION=$(grep "FROM docker.io/floryn90/hugo" Dockerfile | sed 's/FROM docker.io\/floryn90\/hugo://g' | sed 's/ AS builder//g')
docker run \
  --rm --interactive \
  --publish 8095:8095 \
  --name hugo-dev \
  -v $(pwd):/src \
  floryn90/hugo:${HUGO_VERSION} \
  server -p 8095 --bind 0.0.0.0 --enableGitInfo=false ${ENV} 

