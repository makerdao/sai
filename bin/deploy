#!/usr/bin/env bash
set -ex

export SOLC_FLAGS=${SOLC_FLAGS:-"--optimize"}
export ETH_GAS=${ETH_GAS:-"4500000"}
export ETH_FROM=${ETH_FROM:-$(seth rpc eth_coinbase)}

dapp --use solc:0.4.25 build --extract

# shellcheck disable=SC2153
{ test -z "$GEM_FAB"    || test -z "$VOX_FAB"     || test -z "$TUB_FAB" || \
  test -z "$TAP_FAB"    || test -z "$TOP_FAB"     || test -z "$MOM_FAB" || \
  test -z "$DAD_FAB"; } && \
  exit 1

test -z "$SAI_GEM" && SAI_GEM=$(dapp create DSToken "$(seth --to-bytes32 "$(seth --from-ascii 'ETH')")")
test -z "$SAI_GOV" && SAI_GOV=$(dapp create DSToken "$(seth --to-bytes32 "$(seth --from-ascii 'GOV')")")
test -z "$SAI_PIP" && SAI_PIP=$(dapp create DSValue)
test -z "$SAI_PEP" && SAI_PEP=$(dapp create DSValue)
test -z "$SAI_PIT" && SAI_PIT="0x0000000000000000000000000000000000000123"

DAI_FAB=$(dapp create DaiFab "$GEM_FAB" "$VOX_FAB" "$TUB_FAB" "$TAP_FAB" "$TOP_FAB" "$MOM_FAB" "$DAD_FAB")

if [ -z "$SAI_ADM" ]
then
    SAI_ADM=$(dapp create DSRoles)
    seth send "$SAI_ADM" 'setRootUser(address,bool)' "$ETH_FROM" true
fi

seth send "$DAI_FAB" 'makeTokens()'
seth send "$DAI_FAB" 'makeVoxTub(address,address,address,address,address)' "$SAI_GEM" "$SAI_GOV" "$SAI_PIP" "$SAI_PEP" "$SAI_PIT"
seth send "$DAI_FAB" 'makeTapTop()'
seth send "$DAI_FAB" 'configParams()'
seth send "$DAI_FAB" 'verifyParams()'
seth send "$DAI_FAB" 'configAuth(address)' "$SAI_ADM"

SAI_SAI=0x$(seth call "$DAI_FAB" 'sai()(address)')
SAI_SIN=0x$(seth call "$DAI_FAB" 'sin()(address)')
SAI_SKR=0x$(seth call "$DAI_FAB" 'skr()(address)')
SAI_DAD=0x$(seth call "$DAI_FAB" 'dad()(address)')
SAI_MOM=0x$(seth call "$DAI_FAB" 'mom()(address)')
SAI_VOX=0x$(seth call "$DAI_FAB" 'vox()(address)')
SAI_TUB=0x$(seth call "$DAI_FAB" 'tub()(address)')
SAI_TAP=0x$(seth call "$DAI_FAB" 'tap()(address)')
SAI_TOP=0x$(seth call "$DAI_FAB" 'top()(address)')

cat > "load-env-$(seth chain)" << EOF
#!/bin/bash

# sai deployment on $(seth chain) from $(git rev-parse HEAD)
# $(date)

export SAI_GEM=$SAI_GEM
export SAI_GOV=$SAI_GOV
export SAI_PIP=$SAI_PIP
export SAI_PEP=$SAI_PEP
export SAI_PIT=$SAI_PIT
export SAI_ADM=$SAI_ADM
export SAI_SAI=$SAI_SAI
export SAI_SIN=$SAI_SIN
export SAI_SKR=$SAI_SKR
export SAI_DAD=$SAI_DAD
export SAI_MOM=$SAI_MOM
export SAI_VOX=$SAI_VOX
export SAI_TUB=$SAI_TUB
export SAI_TAP=$SAI_TAP
export SAI_TOP=$SAI_TOP
EOF

cat > addresses.json << EOF
{
    "SAI_GEM": "$SAI_GEM",
    "SAI_GOV": "$SAI_GOV",
    "SAI_PIP": "$SAI_PIP",
    "SAI_PEP": "$SAI_PEP",
    "SAI_PIT": "$SAI_PIT",
    "SAI_ADM": "$SAI_ADM",
    "SAI_SAI": "$SAI_SAI",
    "SAI_SIN": "$SAI_SIN",
    "SAI_SKR": "$SAI_SKR",
    "SAI_DAD": "$SAI_DAD",
    "SAI_MOM": "$SAI_MOM",
    "SAI_VOX": "$SAI_VOX",
    "SAI_TUB": "$SAI_TUB",
    "SAI_TAP": "$SAI_TAP",
    "SAI_TOP": "$SAI_TOP"
}
EOF
