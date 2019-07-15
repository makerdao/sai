#!/usr/bin/env bash
set -ex

export SOLC_FLAGS=${SOLC_FLAGS:-"--optimize"}
export ETH_GAS=${ETH_GAS:-"3500000"}
export ETH_FROM=${ETH_FROM:-$(seth rpc eth_coinbase)}

dapp --use solc:0.4.25 build --extract

# ETHUSD feed
export SAI_PIP='0x729D19f657BD0614b4985Cf1D82531c67569197B'

# MKRUSD feed
export SAI_PEP='0x99041F808D598B782D5a3e498681C2452A31da08'

# WETH9
export SAI_GEM='0xc02aaa39b223fe8d0a0e5c4f27ead9083c756cc2'

# Token burner
SAI_PIT=$(dapp create GemPit)
export SAI_PIT

# MKR address
export SAI_GOV='0x9f8F72aA9304c8B593d555F12eF6589cC3A579A2'

# Chief
## Voting IOU
SAI_IOU=$(dapp create DSToken "$(seth --to-bytes32 "$(seth --from-ascii 'IOU')")")
SAI_ADM=$(dapp create DSChief "$SAI_GOV" "$SAI_IOU" 5)
export SAI_IOU
export SAI_ADM
seth send "$SAI_IOU" 'setOwner(address)' "$SAI_ADM"

cat > "load-pre-$(seth chain)" << EOF
test -z $SAI_GEM && GEMtx=$(dapp create DSToken "$(seth --to-bytes32 "$(seth --from-ascii 'ETH')")")
#!/bin/bash

# pre-sai deployment on $(seth chain) from $(git rev-parse HEAD)
# $(date)

export SAI_GEM=$SAI_GEM
export SAI_GOV=$SAI_GOV
export SAI_PIP=$SAI_PIP
export SAI_PEP=$SAI_PEP
export SAI_PIT=$SAI_PIT
export SAI_ADM=$SAI_ADM
export SAI_IOU=$SAI_IOU
EOF
