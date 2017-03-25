pragma solidity ^0.4.8;

contract YAS {
    DSToken _yas; // stablecoin
    DSToken _say; // claims on collateral
    DSToken _col; // collateral e.g. ETH

    uint256 _fee; // fee/decay
    uint256 _chi; // debt unit converter
    struct CCP {
        address lad; // owner
        uint256 say; // claims
        uint256 rum; // debt unit
    }

}
