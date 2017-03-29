/// lib.sol -- utilities

// Copyright (C) 2016, 2017  Daniel Brockman <daniel@dapphub.com>
// Copyright (C) 2016, 2017  Mikael Brockman <mikael@dapphub.com>
// Copyright (C) 2016, 2017  Nikolai Mushegian <nikolai@dapphub.com>

pragma solidity ^0.4.8;

import "ds-auth/auth.sol";
import "ds-note/note.sol";
import "ds-vault/vault.sol";
import "ds-aver/aver.sol";

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

contract MakerMath is DSAver {
    function incr(uint128 x, uint128 y) constant returns (uint128 z) {
        aver((z = x + y) >= x);
    }

    function decr(uint128 x, uint128 y) constant returns (uint128 z) {
        aver((z = x - y) <= x);
    }

    function cast(uint256 x) constant returns (uint128 z) {
        aver((z = uint128(x)) == x);
    }

    uint128 constant WAD = 10 ** 18;

    function wmul(uint128 x, uint128 y) constant returns (uint128 z) {
        z = cast((uint256(x) * y + WAD / 2) / WAD);
    }

    function wdiv(uint128 x, uint128 y) constant returns (uint128 z) {
        z = cast((uint256(x) * WAD + y / 2) / y);
    }

    uint128 constant RAY = 10 ** 36;

    function rmul(uint128 x, uint128 y) constant returns (uint128 z) {
        z = cast((uint256(x) * y + RAY / 2) / RAY);
    }

    function rdiv(uint128 x, uint128 y) constant returns (uint128 z) {
        z = cast((uint256(x) * RAY + y / 2) / y);
    }

    function rpow(uint128 x, uint64 n) constant returns (uint128 z) {
        z = n % 2 != 0 ? x : RAY;

        for (n /= 2; n != 0; n /= 2) {
            x = rmul(x, x);

            if (n % 2 != 0) {
                z = rmul(z, x);
            }
        }
    }
}
