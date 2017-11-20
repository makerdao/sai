/// vox.sol -- target price feed

// Copyright (C) 2016,2017  Nikolai Mushegian <nikolai@dapphub.com>
// Copyright (C) 2016,2017  Daniel Brockman <daniel@dapphub.com>
// Copyright (C) 2017  Rain <rainbreak@riseup.net>

pragma solidity ^0.4.15;

import "ds-thing/thing.sol";

contract SaiVox is DSThing {
    uint256  _par;
    uint256  _way;

    uint256  public  fix;
    uint256  public  how;
    uint256  public  tau;

    function SaiVox() public {
        _par = fix = RAY;
        _way = RAY;
        tau  = era();
    }

    function era() public view returns (uint) {
        return block.timestamp;
    }

    function mold(bytes32 param, uint val) public note auth {
        if (param == 'way') _way = val;
    }

    // Dai Target Price (ref per dai)
    function par() public returns (uint) {
        prod();
        return _par;
    }
    function way() public returns (uint) {
        prod();
        return _way;
    }

    function tell(uint256 ray) public note auth {
        fix = ray;
    }
    function tune(uint256 ray) public note auth {
        how = ray;
    }

    function prod() public note {
        var age = era() - tau;
        if (age == 0) return;  // optimised
        tau = era();

        if (_way != RAY) _par = rmul(_par, rpow(_way, age));  // optimised

        if (how == 0) return;  // optimised
        var wag = int128(how * age);
        _way = inj(prj(_way) + (fix < _par ? wag : -wag));
    }

    function inj(int128 x) internal pure returns (uint256) {
        return x >= 0 ? uint256(x) + RAY
            : rdiv(RAY, RAY + uint256(-x));
    }
    function prj(uint256 x) internal pure returns (int128) {
        return x >= RAY ? int128(x - RAY)
            : int128(RAY) - int128(rdiv(RAY, x));
    }
}
