#!/usr/bin/env bash
set -u

echo "== AWS Databases + Analytics: local preflight =="
echo "This script is read-only and creates no AWS resources."
echo

if ! command -v aws >/dev/null 2>&1; then
  echo "ERROR: AWS CLI was not found. Install/configure AWS CLI before continuing."
  exit 1
fi

echo "-- AWS CLI version --"
aws --version
echo

echo "-- Current CLI configuration (sensitive values are not printed) --"
printf 'AWS_PROFILE=%s\n' "${AWS_PROFILE:-<default profile>}"
printf 'AWS_REGION=%s\n' "${AWS_REGION:-${AWS_DEFAULT_REGION:-<not set in environment>}}"
echo

echo "-- Read-only identity check --"
if aws sts get-caller-identity --output table; then
  echo
  echo "PASS: AWS credentials are available for a read-only identity check."
  echo "Next: confirm the intended account/profile and region before any deployment."
else
  echo
  echo "STOP: AWS identity check failed. No resources were created."
  echo "Check your AWS CLI profile/login and retry this script."
  exit 2
fi
