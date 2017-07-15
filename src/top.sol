/// top.sol -- global settlement manager

// Copyright (C) 2017  Rain <rainbreak@riseup.net>

pragma solidity ^0.4.10;

import './tub.sol';
import './tap.sol';

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
        assert(tub.reg() == Tub.Stage.Usual);
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
        // gems needed to cover debt
        var bye = rmul(fix, woe);

        // put the gems backing sai in a safe place
        jar.push(gem, pit, bye);
    }
    // cage by reading the last value from the feed for the price
    function cage() note auth {
        var pip = uint128(tub.jar().pip().read()); // ref per gem
        var par = tub.tip().par();                 // ref per sai
        var price = wdiv(pip, par);                // sai per gem
        cage(price);
    }
    // exchange free sai for gems after kill
    function cash() note auth {
        assert(tub.reg() == Tub.Stage.Caged);
        var hai = cast(sai.balanceOf(msg.sender));
        pit.pull(sai, msg.sender, hai);
        pit.push(gem, msg.sender, rmul(hai, fix));
    }

    function vent() note {
        assert(tub.reg() == Tub.Stage.Caged);
        jug.heal(pit);
        pit.burn(skr);
    }
}
