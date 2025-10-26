#!/bin/bash

# 🚀 Deploy Script for Arbitrum Mainnet
# Run this after setting up your .env file with Arbitrum Mainnet configuration

set -e

echo "=================================================="
echo "🚀 Deploying Smart Yield Optimizer to Arbitrum Mainnet"
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

if [ -z "$ARBITRUM_MAINNET_RPC_URL" ]; then
    echo "❌ Error: ARBITRUM_MAINNET_RPC_URL not set in .env"
    exit 1
fi

# Get deployer address
DEPLOYER=$(cast wallet address $PRIVATE_KEY)
echo "📍 Deployer Address: $DEPLOYER"

# Check balance
BALANCE=$(cast balance $DEPLOYER --rpc-url $ARBITRUM_MAINNET_RPC_URL)
BALANCE_ETH=$(echo "scale=4; $BALANCE / 1000000000000000000" | bc)
echo "💰 Balance: $BALANCE_ETH ETH"

if [ $(echo "$BALANCE_ETH < 0.01" | bc) -eq 1 ]; then
    echo "⚠️  Warning: Low balance! You need at least 0.01 ETH for deployment"
    echo "💳 Get Arbitrum ETH from: https://bridge.arbitrum.io/"
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
echo "🚀 Deploying contracts to Arbitrum Mainnet..."
echo ""

# Deploy with verification if API key is set
if [ -z "$ARBISCAN_API_KEY" ]; then
    echo "⚠️  No ARBISCAN_API_KEY found, deploying without verification"
    forge script script/DeployArbitrum.s.sol \
        --rpc-url $ARBITRUM_MAINNET_RPC_URL \
        --broadcast \
        -vvvv
else
    echo "✅ Deploying with contract verification"
    forge script script/DeployArbitrum.s.sol \
        --rpc-url $ARBITRUM_MAINNET_RPC_URL \
        --broadcast \
        --verify \
        --etherscan-api-key $ARBISCAN_API_KEY \
        -vvvv
fi

if [ $? -ne 0 ]; then
    echo ""
    echo "❌ Deployment failed!"
    exit 1
fi

echo ""
echo "=================================================="
echo "✅ Arbitrum Mainnet Deployment Complete!"
echo "=================================================="
echo ""
echo "📝 Next Steps:"
echo "1. Copy the vault address from the output above"
echo "2. Update your .env file: VITE_VAULT_ADDRESS_ARBITRUM=0xYourVaultAddress"
echo "3. Get Arbitrum USDC from: https://bridge.arbitrum.io/"
echo "4. Start frontend: npm run dev"
echo "5. Test deposit flow in the UI"
echo ""
echo "🔍 View on Arbiscan:"
echo "https://arbiscan.io/address/YOUR_VAULT_ADDRESS"
echo ""
echo "⚠️  IMPORTANT: This is MAINNET deployment!"
echo "   - Use real funds carefully"
echo "   - Set proper treasury address"
echo "   - Set Avail Nexus address"
echo "   - Set Vincent automation address"
echo ""
