pragma solidity ^0.4.8;

import "ds-auth/auth.sol";
import "ds-token/token.sol";

contract Tab is DSAuth {
    function Tab(DSToken col) { // constructor
        _col = col;
        _say = new DSToken("SAY", "SAY", 18);
        _yas = new DSToken("YAS", "YAS", 18);
    }
    DSToken _col; // Collateral: An "externally valuable" token (like ETH or gold)
    DSToken _say; // Your 'Say': Claims on the pool of COL
    DSToken _yas; // stablecoin: The stable-price loan token

    // return ERC20 instead of DSToken, because consumers generally are not authed
    function COL() constant returns (ERC20) { return _col; }
    function SAY() constant returns (ERC20) { return _say; } 
    function YAS() constant returns (ERC20) { return _yas; } 

    struct Cup {
        address lad; // owner
        uint128 pro; // locked 'say'
        uint128 rum; // cup debt (in debt unit)
    }

    // COL <-> SAY
    function join(uint128 amt) {
        uint128 price;
        // this avoids 0 edge case / rounding errors
        // TODO delegate edge case via fee built into conversion formula
        if( _col.balanceOf(this) < 1 ether ) {
            price = 1;
        } else {
            price = uint128(_col.balanceOf(this) / _say.totalSupply());
        }
        var prize = amt * price;
        assert( _col.pull(msg.sender, amt) );
        _say.mint(prize);
        _say.push(msg.sender, prize);
    }

    function exit(uint128 amt) {} // reverse join

    // CDP ops
    function open() returns (uint256 urn) {}
    function shut(uint256 urn) {}

    // lock/free SAY tokens
    function lock(uint256 urn, uint128 amt) {}
    function free(uint256 urn, uint128 amt) {}

    // draw/wipe YAS tokens
    function draw(uint256 urn, uint128 amt) {}
    function wipe(uint256 urn, uint128 amt) {}

    // keeper
    // REF:COL price
    function tell(uint256 wut) {}
    function bite(uint256 urn) {}

    // auto MM
    function boom(uint128 amt) {}
    function bust(uint128 amt) {}

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
