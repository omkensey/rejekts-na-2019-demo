#!/bin/bash

kubectl config view --flatten -o json | jq -r '.users[] | select(.name == "admin") | .user."client-certificate-data"' | base64 -d | openssl x509 -noout -text
