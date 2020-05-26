#!/bin/bash

set -euf

./create-infra.sh

say "The Azure cluster has been created"

./install-agent.sh

say "Sysdig agent installed"

sleep 30

./install.sh

say "The audit log integration was succesfully installed"


