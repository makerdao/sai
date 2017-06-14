/// tub.sol -- simplified CDP engine (baby brother of `vat')

// Copyright (C) 2017  Nikolai Mushegian <nikolai@dapphub.com>
// Copyright (C) 2017  Daniel Brockman <daniel@dapphub.com>
// Copyright (C) 2017  Rain <rainbreak@riseup.net>

pragma solidity ^0.4.10;

import "ds-thing/thing.sol";
import "ds-token/token.sol";
import "ds-vault/vault.sol";

import "./tip.sol";
import "./lib.sol";

// ref/gem is the only piece external data  (e.g. USD/ETH)
//    so there is a strong separation between "data feeds" and "policy"
// skr/gem is ratio of supply (outstanding skr to total locked gem)
// sai/ref decays ("holder fee")

// surplus also market makes for gem

// refprice(skr) := ethers per claim * tag
// risky := refprice(skr):refprice(debt) too high

contract TubEvents {
    event LogNewCup(address indexed lad, bytes32 cup);
}

contract Tub is DSThing, TubEvents {
    Tip      public  tip;  // target price
    DSValue  public  pip;  // price feed
    address  public  tap;  // liquidator

    DSToken  public  sai;  // Stablecoin
    DSToken  public  sin;  // Debt (negative sai)
    DSDevil  public  dev;  // jug-like sin tracker

    DSVault  public  pot;  // Good debt vault
    DSToken  public  skr;  // Abstracted collateral
    ERC20    public  gem;  // Underlying collateral

    uint128  public  axe;  // Liquidation penalty
    uint128  public  hat;  // Debt ceiling
    uint128  public  mat;  // Liquidation ratio
    uint128  public  tax;  // Stability fee
    // TODO spread?? `gap`

    enum Stage { Usual, Caged, Empty }
    Stage    public  reg;  // 'register'

    uint128  public  fix;  // sai kill price (gem per sai)
    uint128  public  fit;  // gem per skr (just before settlement)

    uint64   public  rho;  // time of last drip
    uint128         _chi;  // internal debt price

    uint256                   public  cupi;
    mapping (bytes32 => Cup)  public  cups;

    struct Cup {
        address  lad;      // CDP owner

        uint128  art;      // Outstanding debt (in debt unit)
        uint128  ink;      // Locked collateral (in skr)
    }

    function push(ERC20 gem, address dst, uint128 wad) note auth {
        gem.transfer(dst, uint(wad));
    }

    function tab(bytes32 cup) constant returns (uint128) {
        return rmul(cups[cup].art, chi());
    }
    function ink(bytes32 cup) constant returns (uint128) {
        return cups[cup].ink;
    }
    function lad(bytes32 cup) constant returns (address) {
        return cups[cup].lad;
    }

    //------------------------------------------------------------------

    function Tub(ERC20 gem_, DSDevil dev_, DSToken sai_, DSToken sin_, DSToken skr_, DSVault pot_, Tip tip_, DSValue pip_) {
        gem = gem_;

        dev = dev_;
        sai = sai_;
        sin = sin_;
        skr = skr_;
        pot = pot_;

        axe = RAY;
        mat = RAY;
        tax = RAY;

        _chi = RAY;

        tip = tip_;
        pip = pip_;

        rho = tip.era();
    }

    function tag() returns (uint128) {
        return uint128(pip.read());
    }

    function chop(uint128 ray) note auth {
        axe = ray;
        assert((RAY <= axe) && (axe <= mat));
    }
    function cork(uint128 wad) note auth {
        hat = wad;
    }
    function cuff(uint128 ray) note auth {
        mat = ray;
        assert((RAY <= axe) && (axe <= mat));
    }
    function crop(uint128 ray) note auth {
        drip();
        tax = ray;
        assert(RAY <= tax);
    }
    function turn(address tap_) note auth {
        tap = tap_;
    }

    function chi() returns (uint128) {
        drip();
        return _chi;
    }
    function drip() note {
        if (reg != Stage.Usual) return;  // noop if system caged

        var age = tip.era() - rho;
        var chi = rmul(_chi, rpow(tax, age));
        var rum = rdiv(ice(), _chi);
        var dew = wsub(rmul(rum, chi), ice());

        dev.lend(dew);
        sin.push(pot, dew);
        sai.push(tap, dew);

        _chi = chi;
        rho = tip.era();
    }

    // Good debt
    function ice() constant returns (uint128) {
        return uint128(sin.balanceOf(pot));
    }
    // Bad debt
    function woe() constant returns (uint128) {
        return uint128(sin.balanceOf(tap));
    }
    // Raw collateral
    function pie() constant returns (uint128) {
        return uint128(gem.balanceOf(this));
    }
    // Backing collateral
    function air() constant returns (uint128) {
        return uint128(skr.balanceOf(pot));
    }
    // Collateral pending liquidation
    function fog() constant returns (uint128) {
        return uint128(skr.balanceOf(tap));
    }
    // surplus
    function joy() constant returns (uint128) {
        return uint128(sai.balanceOf(tap));
    }

    // gem per skr
    function per() constant returns (uint128) {
        // this avoids 0 edge case / rounding errors TODO delete me
        // TODO delegate edge case via fee built into conversion formula
        // TODO could also initialize with 1 gem and 1 skr, send skr to 0x0

        // TODO can we prove that skr.sum() == 0 --> pie() == 0 ?
        return skr.totalSupply() == 0
            ? RAY
            : rdiv(pie(), uint128(skr.totalSupply()));
    }

    // returns true if cup overcollateralized
    function safe(bytes32 cup) constant returns (bool) {
        var jam = rmul(per(), cups[cup].ink);
        var pro = wmul(tag(), jam);
        var con = wmul(tip.par(), tab(cup));
        var min = rmul(con, mat);
        return (pro >= min);
    }

    //------------------------------------------------------------------

    function join(uint128 jam) auth note {
        assert(reg == Stage.Usual);
        var ink = rdiv(jam, per());
        gem.transferFrom(msg.sender, this, jam);
        skr.mint(ink);
        skr.push(msg.sender, ink);
    }
    function exit(uint128 ink) auth note {
        assert(reg == Stage.Usual || reg == Stage.Empty );
        var jam = rmul(ink, per());
        skr.pull(msg.sender, ink);
        skr.burn(ink);
        gem.transfer(msg.sender, jam);
    }

    function open() auth note returns (bytes32 cup) {
        assert(reg == Stage.Usual);
        cup = bytes32(++cupi);
        cups[cup].lad = msg.sender;
        // TODO replace this event with another solution
        LogNewCup(msg.sender, cup);
    }
    function shut(bytes32 cup) auth note {
        assert(reg == Stage.Usual);
        wipe(cup, tab(cup));
        free(cup, cups[cup].ink);
        delete cups[cup];
    }

    function lock(bytes32 cup, uint128 wad) auth note {
        assert(reg == Stage.Usual);
        assert(msg.sender == cups[cup].lad);
        cups[cup].ink = hadd(cups[cup].ink, wad);
        skr.pull(msg.sender, wad);
        skr.push(pot, wad);
    }
    function free(bytes32 cup, uint128 wad) auth note {
        assert(reg == Stage.Usual);
        assert(msg.sender == cups[cup].lad);
        cups[cup].ink = hsub(cups[cup].ink, wad);
        assert(safe(cup));
        pot.push(skr, msg.sender, wad);
    }

    function draw(bytes32 cup, uint128 wad) auth note {
        assert(reg == Stage.Usual);
        assert(msg.sender == cups[cup].lad);

        var pen = rdiv(wad, chi());
        cups[cup].art = wadd(cups[cup].art, pen);

        dev.lend(wad);
        sin.push(pot, wad);
        sai.push(msg.sender, wad);

        assert(safe(cup));
        assert(cast(sin.totalSupply()) <= hat);
    }
    function wipe(bytes32 cup, uint128 wad) auth note {
        assert(reg == Stage.Usual);
        assert(msg.sender == cups[cup].lad);

        var pen = rdiv(wad, chi());
        cups[cup].art = wsub(cups[cup].art, pen);

        sai.pull(msg.sender, wad);
        pot.push(sin, this, wad);
        dev.mend(wad);

        assert(safe(cup));
        assert(cast(sin.totalSupply()) <= hat);
    }

    function give(bytes32 cup, address lad) auth note {
        assert(msg.sender == cups[cup].lad);
        assert(lad != 0);
        cups[cup].lad = lad;
    }

    //------------------------------------------------------------------

    function bite(bytes32 cup) auth note {
        assert(reg == Stage.Usual);
        assert(!safe(cup));

        // take on all of the debt
        var rue = tab(cup);
        pot.push(sin, tap, rue);
        cups[cup].art = 0;

        // axe the collateral
        var owe = rmul(rue, axe);                    // amount owed inc. penalty
        var cab = wdiv(wmul(owe, tip.par()), rmul(tag(), per()));     // equivalent in skr
        var ink = cups[cup].ink;                     // available skr

        if (ink < cab) cab = ink;                    // take at most all the skr

        pot.push(skr, tap, cab);
        cups[cup].ink = hsub(cups[cup].ink, cab);
    }
    //------------------------------------------------------------------

    function cage(uint128 fit_, uint128 fix_) auth note {
        assert(reg == Stage.Usual);
        reg = Stage.Caged;

        fit = fit_;
        fix = fix_;
    }

    // retrieve skr from a cup
    function bail(bytes32 cup) auth note {
        assert(reg == Stage.Caged || reg == Stage.Empty);

        var pro = cups[cup].ink;
        // value of the debt in skr at settlement
        var con = rdiv(rmul(tab(cup), fix), fit);

        var ash = hmin(pro, con);  // skr taken to cover the debt
        pot.push(skr, cups[cup].lad, hsub(pro, ash));
        pot.push(skr, this, ash);
        skr.burn(ash);

        delete cups[cup];
    }
    function vent() auth note {
        assert(reg == Stage.Caged);
        reg = Stage.Empty;
    }
    function heal() note auth {
        dev.heal();
    }
    function mend(uint128 wad) note auth {
        dev.mend(wad);
    }
    function burn(DSToken gem, uint128 wad) {
        gem.burn(wad);
    }
}
