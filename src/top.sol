/// top.sol -- global settlement manager

// Copyright (C) 2017  Nikolai Mushegian <nikolai@dapphub.com>
// Copyright (C) 2017  Daniel Brockman <daniel@dapphub.com>
// Copyright (C) 2017  Rain <rainbreak@riseup.net>

pragma solidity ^0.4.10;

import "./tub.sol";
import "./tap.sol";

contract SaiTop is DSThing {
    SaiTip   public  tip;
    SaiTub   public  tub;
    SaiTap   public  tap;

    SaiJar   public  jar;

    DSToken  public  sai;
    DSToken  public  sin;
    DSToken  public  skr;
    ERC20    public  gem;

    uint256  public  fix;  // sai kill price (gem per sai)
    uint64   public  caged;
    uint64   public  cooldown = 6 hours;

    function SaiTop(SaiTub tub_, SaiTap tap_) {
        tub = tub_;
        tap = tap_;

        tip = tub.tip();
        jar = tub.jar();

        sai = tub.sai();
        sin = tub.sin();
        skr = tub.skr();
        gem = tub.gem();
    }

    // force settlement of the system at a given price (sai per gem).
    // This is nearly the equivalent of biting all cups at once.
    // Important consideration: the gems associated with free skr can
    // be tapped to make sai whole.
    function cage(uint256 price) note auth {
        assert(!tub.off());
        tub.drip();  // collect remaining fees

        var fit = rmul(wmul(price, tub.tip().par()), jar.per());  // ref per skr
        tub.cage(fit);

        // cast up to ray for precision
        price = price * (RAY / WAD);

        tap.heal();       // absorb any pending fees

        // most gems we can get per sai is the full balance
        var woe = sin.totalSupply();

        fix = min(rdiv(RAY, price), rdiv(tub.pie(), woe));
        tap.cage(fix);
        tap.vent();    // burn pending sale skr

        // put the gems backing sai in a safe place
        jar.cage(tap, rmul(fix, woe));

        caged = tip.era();
    }
    // cage by reading the last value from the feed for the price
    function cage() note auth {
        cage(wdiv(uint256(jar.pip().read()), tip.par()));
    }

    function flow() note {
        require(jar.off());
        var empty = tub.ice() == 0 && tap.fog() == 0;
        var ended = tip.era() > caged + cooldown;
        require(empty || ended);
        jar.flow(); 
    }

    function setCooldown(uint64 cooldown_) auth {
        cooldown = cooldown_;
    }
}
