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

    function lock(uint256 amt) {
        _col.transferFrom(msg.sender, this, amt);
    }
    // (ethers per claim) := 
    // refprice(say) := (ethers per claim) * (wut)
    // risky := refprice(say):refprice(debt) too high
}
