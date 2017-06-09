/// sin.sol -- anti-corruption wrapper for your internet accounts

// Copyright (C) 2017  Rain <rainbreak@riseup.net>

pragma solidity ^0.4.10;

import "ds-thing/thing.sol";
import "ds-vault/vault.sol";

contract DSDevil is DSThing {
    DSToken  public  gem;
    DSToken  public  sin;

    function DSDevil(DSToken gem_, DSToken sin_) {
        gem = gem_;
        sin = sin_;
    }
    function lend(uint128 wad) note auth {
        gem.mint(wad);
        sin.mint(wad);

        gem.push(msg.sender, wad);
        sin.push(msg.sender, wad);
    }
    function mend(uint128 wad) note {
        DSVault(msg.sender).push(gem, this, wad);
        DSVault(msg.sender).push(sin, this, wad);

        gem.burn(wad);
        sin.burn(wad);
    }
    function heal() note {
        var joy = cast(gem.balanceOf(msg.sender));
        var woe = cast(sin.balanceOf(msg.sender));
        mend(hmin(joy, woe));
    }
}
