#!/usr/bin/env bash
set -ex

export SOLC_FLAGS=${SOLC_FLAGS:-"--optimize"}
export ETH_GAS=${ETH_GAS:-"3500000"}
export ETH_FROM=${ETH_FROM:-$(seth rpc eth_coinbase)}

dapp --use solc:0.4.25 build --extract

export SETH_ASYNC=yes

ETH_NONCE=$(seth nonce "$ETH_FROM")
GEM_FABtx=$(ETH_NONCE=$ETH_NONCE dapp create GemFab)
VOX_FABtx=$(ETH_NONCE=$((ETH_NONCE + 1)) dapp create VoxFab)
TUB_FABtx=$(ETH_NONCE=$((ETH_NONCE + 2)) dapp create TubFab)
TAP_FABtx=$(ETH_NONCE=$((ETH_NONCE + 3)) dapp create TapFab)
TOP_FABtx=$(ETH_NONCE=$((ETH_NONCE + 4)) dapp create TopFab)
MOM_FABtx=$(ETH_NONCE=$((ETH_NONCE + 5)) dapp create MomFab)
DAD_FABtx=$(ETH_NONCE=$((ETH_NONCE + 6)) dapp create DadFab)

export SETH_ASYNC=no

GEM_FAB=$(seth receipt "$GEM_FABtx" contractAddress)
VOX_FAB=$(seth receipt "$VOX_FABtx" contractAddress)
TUB_FAB=$(seth receipt "$TUB_FABtx" contractAddress)
TAP_FAB=$(seth receipt "$TAP_FABtx" contractAddress)
TOP_FAB=$(seth receipt "$TOP_FABtx" contractAddress)
MOM_FAB=$(seth receipt "$MOM_FABtx" contractAddress)
DAD_FAB=$(seth receipt "$DAD_FABtx" contractAddress)

cat > "load-fab-$(seth chain)" << EOF
#!/bin/bash

# fab deployment on $(seth chain) from $(git rev-parse HEAD)
# $(date)

export GEM_FAB=$GEM_FAB
export VOX_FAB=$VOX_FAB
export TAP_FAB=$TAP_FAB
export TUB_FAB=$TUB_FAB
export TOP_FAB=$TOP_FAB
export MOM_FAB=$MOM_FAB
export DAD_FAB=$DAD_FAB
EOF
