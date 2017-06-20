/// tap.sol -- liquidation engine (see also `vow`)

// Copyright (C) 2017  Rain <rainbreak@riseup.net>

pragma solidity ^0.4.10;

import "./tub.sol";

contract Tap is DSThing {
    Tub      public  tub;
    DSVault  public  pit;

    DSToken  public  sai;
    DSToken  public  sin;
    DSToken  public  skr;

    DSDevil  public  dev;

    function Tap(Tub tub_, DSVault pit_) {
        tub = tub_;
        pit = pit_;

        sai = tub.sai();
        sin = tub.sin();
        skr = tub.skr();

        dev = tub.dev();
    }

    // surplus
    function joy() constant returns (uint128) {
        return uint128(sai.balanceOf(pit));
    }
    // Bad debt
    function woe() constant returns (uint128) {
        return uint128(sin.balanceOf(pit));
    }
    // Collateral pending liquidation
    function fog() constant returns (uint128) {
        return uint128(skr.balanceOf(pit));
    }

    // skr per sai
    function s2s() returns (uint128) {
        var tag = tub.jar().tag();
        var per = tub.jar().per();
        var par = tub.tip().par();
        return wdiv(rmul(tag, per), par);
    }

    // constant skr/sai mint/sell/buy/burn to process joy/woe
    function boom(uint128 wad) auth note {
        assert(tub.reg() == Tub.Stage.Usual);
        tub.drip();
        dev.heal(pit);

        // price of wad in sai
        var ret = wmul(wad, s2s());
        assert(ret <= joy());

        pit.pull(skr, msg.sender, wad);
        pit.burn(skr, wad);

        pit.push(sai, msg.sender, ret);
    }
    function bust(uint128 wad) auth note {
        assert(tub.reg() == Tub.Stage.Usual);
        tub.drip();
        dev.heal(pit);

        if (wad > fog()) pit.mint(skr, wad - fog());

        var ret = wmul(wad, s2s());
        assert(ret <= woe());

        pit.push(skr, msg.sender, wad);
        pit.pull(sai, msg.sender, ret);
        dev.heal(pit);
    }

}
