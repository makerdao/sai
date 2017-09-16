/// tip.sol -- target price feed (see `vox`)

// Copyright (C) 2017  Nikolai Mushegian <nikolai@dapphub.com>
// Copyright (C) 2017  Daniel Brockman <daniel@dapphub.com>
// Copyright (C) 2017  Rain <rainbreak@riseup.net>

pragma solidity ^0.4.15;

import "ds-thing/thing.sol";
import "ds-value/value.sol";
import "ds-warp/warp.sol";

contract SaiTip is DSThing, DSWarp {
    uint256  public  way;  // holder fee / interest rate
    uint64   public  tau;  // time of last prod
    uint256         _par;  // ref per sai

    function SaiTip() {
        way  = RAY;
        _par = RAY;
        tau  = _era;
    }

    function coax(uint ray) note auth {
        way = ray;
        require(way < 10002 * 10 ** 23);  // ~200% per hour
        require(way >  9998 * 10 ** 23);
    }

    // Target Price (ref per sai)
    function par() returns (uint) {
        prod();
        return _par;
    }
    function prod() note {
        var age = sub(era(), tau);
        if (age == 0) return;    // optimised
        tau = era();
        if (way == RAY) return;  // optimised
        _par = rmul(_par, rpow(way, age));
    }
}
