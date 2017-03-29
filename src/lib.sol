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
