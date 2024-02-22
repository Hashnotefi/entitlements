#!/usr/bin/env bash

echo "Deployed Commit?..."
read deployed

echo ""

echo "Current Commit?..."
read current

echo ""

git diff $deployed $current -- src/core/SimpleSettlement.sol