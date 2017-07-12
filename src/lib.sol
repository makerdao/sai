/// sin.sol -- anti-corruption wrapper for your internet accounts

// Copyright (C) 2017  Rain <rainbreak@riseup.net>

pragma solidity ^0.4.10;

import "ds-thing/thing.sol";
import "ds-vault/vault.sol";

contract SaiJug  is DSThing {
    DSToken  public  sai;
    DSToken  public  sin;

    function SaiJug (DSToken sai_, DSToken sin_) {
        sai = sai_;
        sin = sin_;
    }
    function lend(DSVault guy, uint128 wad) note auth {
        guy.mint(sai, wad);
        guy.mint(sin, wad);
    }
    function mend(DSVault guy, uint128 wad) note auth {
        guy.burn(sai, wad);
        guy.burn(sin, wad);
    }
    function heal(DSVault guy) note auth {
        var joy = cast(sai.balanceOf(guy));
        var woe = cast(sin.balanceOf(guy));
        mend(guy, hmin(joy, woe));
    }
}
