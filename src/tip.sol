/// tip.sol -- a source of information

// Copyright (C) 2017  Rain <rainbreak@riseup.net>

pragma solidity ^0.4.10;

import "ds-thing/thing.sol";
import "ds-value/value.sol";
import "ds-warp/warp.sol";

contract Tip is DSThing, DSWarp {
    uint128  public  way;  // holder fee / interest rate
    uint64   public  tau;  // time of last prod
    uint128         _par;  // ref per sai

    function Tip() {
        way  = RAY;
        _par = WAD;
        tau  = _era;
    }

    function coax(uint128 ray) note auth {
        way = ray;
    }

    // ref per sai
    function par() returns (uint128) {
        prod();
        return _par;
    }
    function prod() note {
        var age = era() - tau;
        _par = rmul(_par, rpow(way, age));
        tau = era();
    }
}
