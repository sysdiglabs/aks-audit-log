#!/bin/bash


docker build -f Dockerfile .. \
    -t test-aksaudit \
    -t vicenteherrera/test-aksaudit \
    -t vicenteherrera/test-aksaudit:latest &&
    docker push vicenteherrera/test-aksaudit
