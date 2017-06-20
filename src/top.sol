/// top.sol -- global settlement manager

// Copyright (C) 2017  Rain <rainbreak@riseup.net>

pragma solidity ^0.4.10;

import './tub.sol';
import './tap.sol';

contract Top is DSThing {
    uint128  public  fix;
    uint128  public  fit;

    Tub      public  tub;
    Tap      public  tap;

    DSVault  public  jar;
    DSVault  public  pot;
    DSVault  public  pit;

    DSDevil  public  dev;

    DSToken  public  sai;
    DSToken  public  sin;
    DSToken  public  skr;
    ERC20    public  gem;

    enum Stage { Usual, Caged, Empty }

    function Top(Tub tub_, Tap tap_) {
        tub = tub_;
        tap = tap_;

        jar = tub.jar();
        pot = tub.pot();
        pit = tap.pit();

        dev = tub.dev();

        sai = tub.sai();
        sin = tub.sin();
        skr = tub.skr();
        gem = tub.gem();
    }

    // force settlement of the system at a given price (sai per gem).
    // This is nearly the equivalent of biting all cups at once.
    // Important consideration: the gems associated with free skr can
    // be tapped to make sai whole.
    function cage() auth note {
        assert(tub.reg() == Tub.Stage.Usual);
        tub.drip();  // collect remaining fees
        tub.cage();

        // cast up to ray for precision
        var tag = tub.jar().tag() * (RAY / WAD);
        var par = tub.tip().par() * (RAY / WAD);
        var price = rdiv(tag, par);

        // move all good debt, bad debt and surplus to the pot
        dev.heal(pit);       // absorb any pending fees
        pit.burn(skr);       // burn pending sale skr

        // save current gem per skr for collateral calc.
        // we need to know this to work out the skr value of a cups debt

        // most gems we can get per sai is the full balance
        var woe = cast(sin.totalSupply());
        fix = hmin(rdiv(RAY, price), rdiv(tub.pie(), woe));
        // gems needed to cover debt
        var bye = rmul(fix, woe);

        // put the gems backing sai in a safe place
        jar.push(gem, pit, bye);
    }
    // exchange free sai for gems after kill
    function cash() auth note {
        assert(tub.reg() == Tub.Stage.Caged || tub.reg() == Tub.Stage.Empty);

        var hai = cast(sai.balanceOf(msg.sender));
        pit.pull(sai, msg.sender, hai);
        pit.push(gem, msg.sender, rmul(hai, fix));
    }

    function heal() note {
        dev.heal(pit);
    }
    function burn() note {
        assert(tub.ice() == 0);  // otherwise cab is calculated wrong

        // cab = (tab * par) / (tag * per)
        // per is `fit` - the per at cage
        // if we burn before all bite then per will increase
        // however, if we cache the value of fit then this is ok and we
        // can burn continuously
        // this cached per also has to be used in safe calc
        // par can change as well :/ does this need to be fixed yes
        // also tag
        // this is implicit in fix
        // fix = par / tag
        // fix upper bound is pie / sin.total

        // free checks if safe after


        // bite all cups
        // -> all back at safe
        // then lad does free
        // then lad does exit


        // tub could be made completely unaware of cage and top could
        // just make auth changes
        // top could also intervene in tag and per calc

        pit.burn(skr);
    }
    function vent() note {
        heal();
        burn();
    }
}
