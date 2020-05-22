#!/bin/bash

set -euf

#source fish set-globals.fish

./create-infra.sh

./install-agent.sh

sleep 30

./install.sh



