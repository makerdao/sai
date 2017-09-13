/// jug.sol -- anti-corruption wrapper for your internet accounts

// Copyright (C) 2017  Nikolai Mushegian <nikolai@dapphub.com>
// Copyright (C) 2017  Daniel Brockman <daniel@dapphub.com>
// Copyright (C) 2017  Rain <rainbreak@riseup.net>

pragma solidity ^0.4.10;

import "ds-thing/thing.sol";
import "ds-token/token.sol";

contract SaiJug  is DSThing {
    DSToken  public  sai;
    DSToken  public  sin;

    function SaiJug (DSToken sai_, DSToken sin_) {
        sai = sai_;
        sin = sin_;
    }
    function lend(address src, address dst, uint wad) note auth {
        sin.mint(src, wad);
        sai.mint(dst, wad);
    }
    function mend(address src, address dst, uint wad) note auth {
        sai.burn(src, wad);
        sin.burn(dst, wad);
    }
    function heal(address guy) note auth {
        var joy = sai.balanceOf(guy);
        var woe = sin.balanceOf(guy);
        mend(guy, guy, min(joy, woe));
    }
}
