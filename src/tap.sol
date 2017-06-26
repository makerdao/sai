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

    uint128  public  gap;  // spread

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
        var par = tub.tip().par();
        return wdiv(tag, par);
    }

    function jump(uint128 wad) auth note {
        gap = wad;
    }

    // price of skr in sai for boom
    function bid() constant returns (uint128) {
        return wmul(s2s(), wsub(WAD, gap));
    }
    // price of skr in sai for bust
    function ask() constant returns (uint128) {
        return wmul(s2s(), wadd(WAD, gap));
    }

    // constant skr/sai mint/sell/buy/burn to process joy/woe
    function boom(uint128 wad) auth note {
        assert(tub.reg() == Tub.Stage.Usual);
        tub.drip();
        dev.heal(pit);

        // price of wad in sai
        var ret = wmul(bid(), wad);
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

        var ash = wmul(ask(), wad);
        assert(ash <= woe());

        pit.push(skr, msg.sender, wad);
        pit.pull(sai, msg.sender, ash);
        dev.heal(pit);
    }
}
