#!/bin/bash

# Pyth Hermes API - Fetch current prices for all tokens
# Usage: ./scripts/fetch-prices.sh

echo "========================================="
echo "Fetching prices from Pyth Hermes API"
echo "========================================="

# Pyth Hermes API endpoint
HERMES_URL="https://hermes.pyth.network/v2/updates/price/latest"

# Pyth Feed IDs
XSGD_FEED_ID="0x396a969a9c1480fa15ed50bc59149e2c0075a72fe8f458ed941ddec48bdb4918"
THBT_FEED_ID="0x6693afcd49878bbd622e46bd805e7177932cf6ab0b1c91b135d71151b9207433"
IDRT_FEED_ID="0xab1bdad3d2984801e48480cca22df5d709fdfd2149246c9aef6e06a17a0a9394"
USDT_FEED_ID="0x2b89b9dc8fdf9f34709a5b106b472f0f39bb6ca9ce04b0fd7f2e971688e2e53b"

# Fetch prices for all tokens
echo -e "\nFetching prices..."
curl -s "$HERMES_URL?ids[]=$XSGD_FEED_ID&ids[]=$THBT_FEED_ID&ids[]=$IDRT_FEED_ID&ids[]=$USDT_FEED_ID" | jq '.'

echo -e "\n========================================="
echo "Price Summary"
echo "========================================="

echo -e "\n1. XSGD (Singapore Dollar):"
curl -s "$HERMES_URL?ids[]=$XSGD_FEED_ID" | jq '.parsed[0].price | {price: .price, expo: .expo, conf: .conf, publish_time: .publish_time}'

echo -e "\n2. THBT (Thai Baht):"
curl -s "$HERMES_URL?ids[]=$THBT_FEED_ID" | jq '.parsed[0].price | {price: .price, expo: .expo, conf: .conf, publish_time: .publish_time}'

echo -e "\n3. IDRT (Indonesian Rupiah):"
curl -s "$HERMES_URL?ids[]=$IDRT_FEED_ID" | jq '.parsed[0].price | {price: .price, expo: .expo, conf: .conf, publish_time: .publish_time}'

echo -e "\n4. USDT (Tether USD):"
curl -s "$HERMES_URL?ids[]=$USDT_FEED_ID" | jq '.parsed[0].price | {price: .price, expo: .expo, conf: .conf, publish_time: .publish_time}'

echo -e "\n========================================="
echo "Formatted for Solidity"
echo "========================================="
echo -e "\nCopy these values for updatePrices() function:\n"

echo "XSGD:"
curl -s "$HERMES_URL?ids[]=$XSGD_FEED_ID" | jq -r '"  PythStructs.Price memory xsgdPrice = PythStructs.Price({
    price: \(.parsed[0].price.price),
    conf: \(.parsed[0].price.conf),
    expo: \(.parsed[0].price.expo),
    publishTime: uint64(\(.parsed[0].price.publish_time))
  });"'

echo -e "\nTHBT:"
curl -s "$HERMES_URL?ids[]=$THBT_FEED_ID" | jq -r '"  PythStructs.Price memory thbtPrice = PythStructs.Price({
    price: \(.parsed[0].price.price),
    conf: \(.parsed[0].price.conf),
    expo: \(.parsed[0].price.expo),
    publishTime: uint64(\(.parsed[0].price.publish_time))
  });"'

echo -e "\nIDRT:"
curl -s "$HERMES_URL?ids[]=$IDRT_FEED_ID" | jq -r '"  PythStructs.Price memory idrtPrice = PythStructs.Price({
    price: \(.parsed[0].price.price),
    conf: \(.parsed[0].price.conf),
    expo: \(.parsed[0].price.expo),
    publishTime: uint64(\(.parsed[0].price.publish_time))
  });"'

echo -e "\nUSDT:"
curl -s "$HERMES_URL?ids[]=$USDT_FEED_ID" | jq -r '"  PythStructs.Price memory usdtPrice = PythStructs.Price({
    price: \(.parsed[0].price.price),
    conf: \(.parsed[0].price.conf),
    expo: \(.parsed[0].price.expo),
    publishTime: uint64(\(.parsed[0].price.publish_time))
  });"'

echo -e "\n========================================="
