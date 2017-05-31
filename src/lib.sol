/// lib.sol -- utilities

// Copyright (C) 2016, 2017  Daniel Brockman <daniel@dapphub.com>
// Copyright (C) 2016, 2017  Mikael Brockman <mikael@dapphub.com>
// Copyright (C) 2016, 2017  Nikolai Mushegian <nikolai@dapphub.com>

pragma solidity ^0.4.10;

import "ds-math/math.sol";
import "ds-token/token.sol";

contract SaiSin is DSToken('sin', 'SIN', 18), DSMath {
    DSToken public sai;
    function SaiSin(DSToken sai_) {
        sai = sai_;
    }
    function lend(uint128 wad) auth {
        sai.mint(wad);
        mint(wad);

        sai.transfer(msg.sender, wad);
        this.transfer(msg.sender, wad);
    }
    function mend(uint128 wad) {
        // TODO: use push on sender? should sender always be a vault?
        sai.transferFrom(msg.sender, this, wad);
        this.transferFrom(msg.sender, this, wad);

        sai.burn(wad);
        burn(wad);
    }
    function heal() {
        var joy = cast(sai.balanceOf(msg.sender));
        var woe = cast(this.balanceOf(msg.sender));
        mend(hmin(joy, woe));
    }
}
