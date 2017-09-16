/// Dai feedback engine

// Copyright (C) 2016, 2017  Daniel Brockman <daniel@dapphub.com>
// Copyright (C) 2016, 2017  Nikolai Mushegian <nikolai@dapphub.com>

pragma solidity ^0.4.11;

import "ds-thing/thing.sol";
import "ds-warp/warp.sol";

contract DaiVox is DSThing, DSWarp {
    uint256  _par;
    uint256  _way;

    uint256  public  fix;
    uint256  public  how;
    uint64   public  tau;

    function DaiVox(uint256 par) {
        _par = fix = par;
        _way = how = RAY;
        tau  = era();
    }

    // Dai Target Price (ref per dai)
    function par() constant returns (uint) {
        prod();
        return _par;
    }
    function way() constant returns (uint) {
        prod();
        return _way;
    }

    function tell(uint256 ray) note auth {
        fix = ray;
    }
    function tune(uint256 ray) note auth {
        how = ray;
    }

    function prod() note {
        var age = era() - tau;
        if (age == 0) return;  // optimised
        tau = era();

        if (_way != RAY) _par = rmul(_par, rpow(_way, age));  // optimised

        if (how == 0) return;  // optimised
        var wag = int128(how * age);
        _way = inj(prj(_way) + (fix < _par ? wag : -wag));
    }

    function inj(int128 x) internal returns (uint256) {
        return x >= 0 ? uint256(x) + RAY
            : rdiv(RAY, RAY + uint256(-x));
    }
    function prj(uint256 x) internal returns (int128) {
        return x >= RAY ? int128(x - RAY)
            : int128(RAY) - int128(rdiv(RAY, x));
    }
}
