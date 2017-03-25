pragma solidity ^0.4.8;

import "ds-auth/auth.sol";
import "ds-token/token.sol";

contract YAS is DSAuth {
    DSToken _yas; // stablecoin
    DSToken _say; // claims on collateral
    DSToken _col; // collateral e.g. ETH

    bytes32 _ref; // description of reference asset (e.g. "USD")
    uint256 _wut; // _col:ref price TODO use feedbase

    uint256 _mat; // liquidation ratio
    uint256 _fee; // fee/decay
    uint256 _chi; // debt unit converter
    struct CCP {
        address lad; // owner
        uint256 say; // claims
        uint256 rum; // debt unit
    }

    // COL <-> SAY
    function join(uint256 amt) {}
    function exit(uint256 amt) {}

    // CDP ops
    function open() returns (uint256 urn) {}
    function shut() returns (uint256 urn) {}
    function lock(uint256 urn, uint256 amt) {}
    function free(uint256 urn, uint256 amt) {}
    function draw(uint256 urn, uint256 amt) {}
    function wipe(uint256 urn, uint256 amt) {}

    // keeper
    function tell(uint256 wut) {}
    function bite(uint256 urn) {}

    // auto MM
    function boom(uint256 amt) {}
    function bust(uint256 amt) {}

    // settle backdoor
    function kill(uint256 wut) {}

    // admin, later prism of SAY
    function mold() {} // ... lots of params
    function vote() {} // this could be here, or on oracle object, using same prism

    // REF/COL is only external data  (e.g. USD/ETH)
    // SAY/COL is ratio of supply (outstanding SAY to locked COL)
    // YAS/REF decays ("holder fee")
    // SIN = -YAS
    // RUM/SIN decays ("issuer fee")
    // AWE updates on poke ("collect fees for CDP type")
    // DIN updates on bite ("take on bad debt")

    // constant SAY/YAS inflate/sell and buy/burn to process awe/din  (can print SAY)
    // surplus also market makes for COL

    // (ethers per claim) := 
    // refprice(say) := (ethers per claim) * (wut)
    // risky := refprice(say):refprice(debt) too high
}
