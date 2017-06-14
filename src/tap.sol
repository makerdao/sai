/// tap.sol -- liquidation engine (see also `vow`)

// Copyright (C) 2017  Rain <rainbreak@riseup.net>

pragma solidity ^0.4.10;

import "./tub.sol";

contract Tap is DSThing, DSVault {
    Tub      public  tub;

    DSToken  public  sai;
    DSToken  public  sin;
    DSToken  public  skr;

    DSDevil  public  dev;

    function Tap(Tub tub_) {
        tub = tub_;

        sai = tub.sai();
        sin = tub.sin();
        skr = tub.skr();

        dev = tub.dev();
    }

    // surplus
    function joy() constant returns (uint128) {
        return uint128(sai.balanceOf(this));
    }
    // Bad debt
    function woe() constant returns (uint128) {
        return uint128(sin.balanceOf(this));
    }
    // Collateral pending liquidation
    function fog() constant returns (uint128) {
        return uint128(skr.balanceOf(this));
    }

    // skr per sai
    function s2s() returns (uint128) {
        return wdiv(rmul(tub.tag(), tub.per()), tub.tip().par());
    }

    // constant skr/sai mint/sell/buy/burn to process joy/woe
    function boom(uint128 wad) auth note {
        assert(tub.reg() == Tub.Stage.Usual);
        tub.drip();
        dev.heal();

        // price of wad in sai
        var ret = wmul(wad, s2s());
        assert(ret <= joy());

        skr.pull(msg.sender, wad);
        skr.burn(wad);

        sai.push(msg.sender, ret);
    }
    function bust(uint128 wad) auth note {
        assert(tub.reg() == Tub.Stage.Usual);
        tub.drip();
        dev.heal();

        if (wad > fog()) skr.mint(wad - fog());

        var ret = wmul(wad, s2s());
        assert(ret <= woe());

        skr.push(msg.sender, wad);
        sai.pull(msg.sender, ret);
        dev.heal();
    }

}
