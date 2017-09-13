/// tap.sol -- liquidation engine (see also `vow`)

// Copyright (C) 2017  Nikolai Mushegian <nikolai@dapphub.com>
// Copyright (C) 2017  Daniel Brockman <daniel@dapphub.com>
// Copyright (C) 2017  Rain <rainbreak@riseup.net>

pragma solidity ^0.4.10;

import "./tub.sol";

contract SaiTap is DSThing {
    SaiTub   public  tub;
    DSVault  public  pit;

    DSToken  public  sai;
    DSToken  public  sin;
    DSToken  public  skr;

    SaiJug   public  jug;

    uint256  public  gap;  // spread

    function SaiTap(SaiTub tub_, DSVault pit_) {
        tub = tub_;
        pit = pit_;

        sai = tub.sai();
        sin = tub.sin();
        skr = tub.skr();

        jug = tub.jug();

        gap = WAD;
    }

    // surplus
    function joy() constant returns (uint256) {
        return uint256(sai.balanceOf(pit));
    }
    // Bad debt
    function woe() constant returns (uint256) {
        return uint256(sin.balanceOf(pit));
    }
    // Collateral pending liquidation
    function fog() constant returns (uint256) {
        return uint256(skr.balanceOf(pit));
    }

    // sai per skr
    function s2s() returns (uint256) {
        var tag = tub.jar().tag();  // ref per skr
        var par = tub.tip().par();  // ref per sai
        return wdiv(tag, par);      // sai per skr
    }

    function jump(uint256 wad) note auth {
        gap = wad;
        assert(gap <= 1.05 ether);
        assert(gap >= 0.95 ether);
    }

    // price of skr in sai for boom
    function bid() constant returns (uint256) {
        return wmul(s2s(), sub(2 * WAD, gap));
    }
    // price of skr in sai for bust
    function ask() constant returns (uint256) {
        return wmul(s2s(), gap);
    }

    // constant skr/sai mint/sell/buy/burn to process joy/woe
    function boom(uint256 wad) note auth {
        assert(!tub.off());
        tub.drip();
        jug.heal(pit);

        // price of wad in sai
        var ret = wmul(bid(), wad);
        assert(ret <= joy());

        pit.burn(skr, msg.sender, wad);
        pit.push(sai, msg.sender, ret);
    }
    function bust(uint256 wad) note auth {
        assert(!tub.off());
        tub.drip();
        jug.heal(pit);

        uint256 ash;
        if (wad > fog()) {
            pit.mint(skr, wad - fog());
            ash = wmul(ask(), wad);
            assert(ash <= woe());
        } else {
            ash = wmul(ask(), wad);
        }

        pit.push(skr, msg.sender, wad);
        pit.pull(sai, msg.sender, ash);
        jug.heal(pit);
    }
}
