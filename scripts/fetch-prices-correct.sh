#!/bin/bash

# Fetch prices from Pyth Hermes API with CORRECT feed IDs
echo "========================================="
echo "Fetching prices with correct Feed IDs"
echo "========================================="

HERMES_URL="https://hermes.pyth.network/v2/updates/price/latest"

# CORRECT Pyth Feed IDs per user's specification:
# USD/IDR (IDRT): 0x6693afcd49878bbd622e46bd805e7177932cf6ab0b1c91b135d71151b9207433
# USD/THBT (THBT): 0xab1bdad3d2984801e48480cca22df5d709fdfd2149246c9aef6e06a17a0a9394
# USD/SGD (XSGD): 0x396a969a9c1480fa15ed50bc59149e2c0075a72fe8f458ed941ddec48bdb4918
# USDT/USD: 0x2b89b9dc8fdf9f34709a5b106b472f0f39bb6ca9ce04b0fd7f2e971688e2e53b

IDRT_FEED_ID="0x6693afcd49878bbd622e46bd805e7177932cf6ab0b1c91b135d71151b9207433"
THBT_FEED_ID="0xab1bdad3d2984801e48480cca22df5d709fdfd2149246c9aef6e06a17a0a9394"
XSGD_FEED_ID="0x396a969a9c1480fa15ed50bc59149e2c0075a72fe8f458ed941ddec48bdb4918"
USDT_FEED_ID="0x2b89b9dc8fdf9f34709a5b106b472f0f39bb6ca9ce04b0fd7f2e971688e2e53b"

echo -e "\n1. USD/SGD (XSGD):"
curl -s "$HERMES_URL?ids[]=$XSGD_FEED_ID" | jq '.parsed[0].price | {price: "USD " + (.price | tonumber | . * (10 | pow(.expo))), raw: .price, expo: .expo}'

echo -e "\n2. USD/THBT (THBT):"
curl -s "$HERMES_URL?ids[]=$THBT_FEED_ID" | jq '.parsed[0].price | {price: "USD " + (.price | tonumber | . * (10 | pow(.expo))), raw: .price, expo: .expo}'

echo -e "\n3. USD/IDR (IDRT):"
curl -s "$HERMES_URL?ids[]=$IDRT_FEED_ID" | jq '.parsed[0].price | {price: "USD " + (.price | tonumber | . * (10 | pow(.expo))), raw: .price, expo: .expo}'

echo -e "\n4. USDT/USD:"
curl -s "$HERMES_URL?ids[]=$USDT_FEED_ID" | jq '.parsed[0].price | {price: "USD " + (.price | tonumber | . * (10 | pow(.expo))), raw: .price, expo: .expo}'

echo -e "\n========================================="
