#!/bin/bash

# 🚀 Deploy Base Vault Script
# Run this to deploy only the vault on Base Mainnet

set -e

echo "=================================================="
echo "🚀 Deploying Base Vault to Base Mainnet"
echo "=================================================="

# Check if .env exists
if [ ! -f .env ]; then
    echo "❌ Error: .env file not found!"
    echo "📝 Run: cp .env.example .env and fill in your values"
    exit 1
fi

# Load environment variables
source .env

# Check required variables
if [ -z "$PRIVATE_KEY" ]; then
    echo "❌ Error: PRIVATE_KEY not set in .env"
    exit 1
fi

if [ -z "$BASE_MAINNET_RPC_URL" ]; then
    echo "❌ Error: BASE_MAINNET_RPC_URL not set in .env"
    exit 1
fi

# Get deployer address
DEPLOYER=$(cast wallet address $PRIVATE_KEY)
echo "📍 Deployer Address: $DEPLOYER"

# Check balance
BALANCE=$(cast balance $DEPLOYER --rpc-url $BASE_MAINNET_RPC_URL)
BALANCE_ETH=$(echo "scale=4; $BALANCE / 1000000000000000000" | bc)
echo "💰 Balance: $BALANCE_ETH ETH"

if [ $(echo "$BALANCE_ETH < 0.01" | bc) -eq 1 ]; then
    echo "⚠️  Warning: Low balance! You need at least 0.01 ETH for deployment"
    echo "💳 Get Base ETH from: https://bridge.base.org/"
    read -p "Continue anyway? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

echo ""
echo "🔨 Building contracts..."
forge build

if [ $? -ne 0 ]; then
    echo "❌ Build failed!"
    exit 1
fi

echo "✅ Build successful!"
echo ""
echo "🚀 Deploying vault to Base Mainnet..."
echo ""

# Deploy with verification if API key is set
if [ -z "$BASESCAN_API_KEY" ]; then
    echo "⚠️  No BASESCAN_API_KEY found, deploying without verification"
    forge script script/DeployBaseVault.s.sol \
        --rpc-url $BASE_MAINNET_RPC_URL \
        --broadcast \
        -vvvv
else
    echo "✅ Deploying with contract verification"
    forge script script/DeployBaseVault.s.sol \
        --rpc-url $BASE_MAINNET_RPC_URL \
        --broadcast \
        --verify \
        --etherscan-api-key $BASESCAN_API_KEY \
        -vvvv
fi

if [ $? -ne 0 ]; then
    echo ""
    echo "❌ Deployment failed!"
    exit 1
fi

echo ""
echo "=================================================="
echo "✅ Base Vault Deployment Complete!"
echo "=================================================="
echo ""
echo "📝 Next Steps:"
echo "1. Copy the vault address from the output above"
echo "2. Update your .env file: BASE_VAULT_ADDRESS=0xYourVaultAddress"
echo "3. Run ./deploy-base-adapters.sh to deploy adapters"
echo "4. Set proper treasury address"
echo "5. Set Avail Nexus address"
echo "6. Set Vincent automation address"
echo ""
echo "🔍 View on BaseScan:"
echo "https://basescan.org/address/YOUR_VAULT_ADDRESS"
echo ""
