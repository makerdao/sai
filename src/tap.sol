/// tap.sol -- liquidation engine (see also `vow`)

// Copyright (C) 2017  Nikolai Mushegian <nikolai@dapphub.com>
// Copyright (C) 2017  Daniel Brockman <daniel@dapphub.com>
// Copyright (C) 2017  Rain <rainbreak@riseup.net>

pragma solidity ^0.4.10;

import "./jar.sol";
import "./tip.sol";

contract SaiTap is DSThing {
    DSToken  public  sai;
    DSToken  public  sin;
    DSToken  public  skr;

    SaiJar   public  jar;
    SaiTip   public  tip;

    uint256  public  gap;  // Spread
    bool     public  off;  // Cage flag
    uint256  public  fix;  // Cage price

    function SaiTap(
        DSToken sai_,
        DSToken sin_,
        SaiJar  jar_,
        SaiTip  tip_

    ) {
        sai = sai_;
        sin = sin_;
        skr = jar_.skr();

        tip = tip_;
        jar = jar_;

        gap = WAD;
    }

    // surplus
    function joy() constant returns (uint) {
        return sai.balanceOf(this);
    }
    // Bad debt
    function woe() constant returns (uint) {
        return sin.balanceOf(this);
    }
    // Collateral pending liquidation
    function fog() constant returns (uint) {
        return skr.balanceOf(this);
    }

    // sai per skr
    function s2s() returns (uint) {
        var tag = jar.tag();    // ref per skr
        var par = tip.par();    // ref per sai
        return wdiv(tag, par);  // sai per skr
    }

    function calk(uint wad) note auth {
        gap = wad;
        require(gap <= 1.05 ether);
        require(gap >= 0.95 ether);
    }

    // price of skr in sai for boom
    function bid(uint wad) constant returns (uint) {
        return wmul(wad, wmul(s2s(), sub(2 * WAD, gap)));
    }
    // price of skr in sai for bust
    function ask(uint wad) constant returns (uint) {
        return wmul(wad, wmul(s2s(), gap));
    }

    function heal() note {
        var wad = min(joy(), woe());
        sai.burn(wad);
        sin.burn(wad);
    }

    // constant skr/sai mint/sell/buy/burn to process joy/woe
    function boom(uint wad) note {
        require(!off);
        heal();
        sai.push(msg.sender, bid(wad));
        skr.burn(msg.sender, wad);
    }
    function bust(uint wad) note {
        require(!off);
        heal();

        uint ash;
        if (wad > fog()) {
            skr.mint(wad - fog());
            ash = ask(wad);
            require(ash <= woe());
        } else {
            ash = ask(wad);
        }

        skr.push(msg.sender, wad);
        sai.pull(msg.sender, ash);
        heal();
    }

    //------------------------------------------------------------------

    function cage(uint fix_) note auth {
        off = true;
        fix = fix_;
    }
    function cash() note {
        require(off);
        var wad = sai.balanceOf(msg.sender);
        sai.pull(msg.sender, wad);
        jar.gem().transfer(msg.sender, rmul(wad, fix));
    }
    function vent() note {
        require(off);
        heal();
        skr.burn(fog());
    }
}
