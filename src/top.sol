/// top.sol -- global settlement manager

// Copyright (C) 2017  Rain <rainbreak@riseup.net>

pragma solidity ^0.4.10;

import "./tub.sol";
import "./tap.sol";

contract Top is DSThing {
    uint128  public  fix;  // sai kill price (gem per sai)

    Tub      public  tub;
    Tap      public  tap;

    SaiJar   public  jar;
    DSVault  public  pot;
    DSVault  public  pit;

    SaiJug   public  jug;

    DSToken  public  sai;
    DSToken  public  sin;
    DSToken  public  skr;
    ERC20    public  gem;

    function Top(Tub tub_, Tap tap_) {
        tub = tub_;
        tap = tap_;

        jar = tub.jar();
        pot = tub.pot();
        pit = tap.pit();

        jug = tub.jug();

        sai = tub.sai();
        sin = tub.sin();
        skr = tub.skr();
        gem = tub.gem();
    }

    // force settlement of the system at a given price (sai per gem).
    // This is nearly the equivalent of biting all cups at once.
    // Important consideration: the gems associated with free skr can
    // be tapped to make sai whole.
    function cage(uint128 price) note auth {
        assert(!tub.off());
        tub.drip();  // collect remaining fees

        var fit = rmul(wmul(price, tub.tip().par()), jar.per());  // ref per skr
        tub.cage(fit);

        // cast up to ray for precision
        price = price * (RAY / WAD);

        jug.heal(pit);       // absorb any pending fees
        pit.burn(skr);       // burn pending sale skr

        // most gems we can get per sai is the full balance
        var woe = cast(sin.totalSupply());

        fix = hmin(rdiv(RAY, price), rdiv(tub.pie(), woe));

        // put the gems backing sai in a safe place
        jar.push(gem, pit, rmul(fix, woe));
    }
    // cage by reading the last value from the feed for the price
    function cage() note auth {
        cage(wdiv(uint128(tub.jar().pip().read()), tub.tip().par()));
    }
    // exchange free sai for gems after kill
    function cash() note auth {
        assert(tub.off());
        var wad = cast(sai.balanceOf(msg.sender));
        pit.pull(sai, msg.sender, wad);
        pit.push(gem, msg.sender, rmul(wad, fix));
    }

    function vent() note {
        assert(tub.off());
        jug.heal(pit);
        pit.burn(skr);
    }
}
