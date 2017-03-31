/// lib.sol -- utilities

// Copyright (C) 2016, 2017  Daniel Brockman <daniel@dapphub.com>
// Copyright (C) 2016, 2017  Mikael Brockman <mikael@dapphub.com>
// Copyright (C) 2016, 2017  Nikolai Mushegian <nikolai@dapphub.com>

pragma solidity ^0.4.8;

import "ds-auth/auth.sol";
import "ds-note/note.sol";
import "ds-aver/aver.sol";
import "ds-math/math.sol";

contract MakerWarp is DSNote, DSAver {
    uint64  _era;

    function MakerWarp() {
        _era = uint64(now);
    }

    function era() constant returns (uint64) {
        return _era == 0 ? uint64(now) : _era;
    }

    function warp(uint64 age) note {
        aver(_era != 0);
        _era = age == 0 ? 0 : _era + age;
    }
}

contract MakerMath is DSMath { }

contract SaiSin is DSToken('sin', 'SIN', 18) {
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
        sai.transferFrom(msg.sender, wad);
        this.transferFrom(msg.sender, wad);

        sai.burn(wad);
        burn(wad);
    }
    function heal() {
        var joy = sai.balanceOf(msg.sender);
        var wor = this.balanceOf(msg.sender);
        var omm = min(joy(), woe());
        mend(omm);
    }
}
