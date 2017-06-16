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
    function lend(DSVault guy, uint128 wad) note auth {
        guy.mint(gem, wad);
        guy.mint(sin, wad);
    }
    function mend(DSVault guy, uint128 wad) note {
        guy.burn(gem, wad);
        guy.burn(sin, wad);
    }
    function heal(DSVault guy) note {
        var joy = cast(gem.balanceOf(guy));
        var woe = cast(sin.balanceOf(guy));
        mend(guy, hmin(joy, woe));
    }
}
