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
import "./jar.sol";

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

    DSToken  public  sai;  // Stablecoin
    DSToken  public  sin;  // Debt (negative sai)
    SaiJug   public  jug;  // jug-like sin tracker

    DSToken  public  skr;  // Abstracted collateral
    ERC20    public  gem;  // Underlying collateral

    SaiJar   public  jar;  // collateral vault
    DSVault  public  pot;  // Good debt vault
    address  public  pit;  // liquidator vault

    uint128  public  axe;  // Liquidation penalty
    uint128  public  hat;  // Debt ceiling
    uint128  public  mat;  // Liquidation ratio
    uint128  public  tax;  // Stability fee

    enum Stage { Usual, Caged }
    Stage    public  reg;  // 'register'

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

    function Tub(SaiJar jar_, SaiJug  jug_, DSVault pot_, DSVault pit_, Tip tip_) {
        jar = jar_;
        gem = jar.gem();
        skr = jar.skr();

        jug = jug_;
        sai = jug.sai();
        sin = jug.sin();
        pot = pot_;
        pit = pit_;

        axe = RAY;
        mat = RAY;
        tax = RAY;

        _chi = RAY;

        tip = tip_;

        rho = tip.era();
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
        assert(tax < 10002 * 10 ** 23);  // ~200% per hour
    }

    function chi() returns (uint128) {
        drip();
        return _chi;
    }
    function drip() note {
        if (reg != Stage.Usual) return;  // noop
        if (tax == 1) return;  // FIXME: tax=1 release optimisation

        var age = tip.era() - rho;
        var chi = rmul(_chi, rpow(tax, age));
        var rum = rdiv(ice(), _chi);
        var dew = wsub(rmul(rum, chi), ice());

        jug.lend(pot, dew);
        pot.push(sai, pit, dew);

        _chi = chi;
        rho = tip.era();
    }

    // Good debt
    function ice() constant returns (uint128) {
        return uint128(sin.balanceOf(pot));
    }
    // Raw collateral
    function pie() constant returns (uint128) {
        return uint128(gem.balanceOf(jar));
    }
    // Backing collateral
    function air() constant returns (uint128) {
        return uint128(skr.balanceOf(jar));
    }

    // returns true if cup overcollateralized
    function safe(bytes32 cup) constant returns (bool) {
        var pro = wmul(jar.tag(), ink(cup));
        var con = wmul(tip.par(), tab(cup));
        var min = rmul(con, mat);
        return (pro >= min);
    }

    //------------------------------------------------------------------

    function join(uint128 jam) note auth {
        assert(reg == Stage.Usual);
        jar.join(msg.sender, jam);
    }
    function exit(uint128 ink) note auth {
        var empty = ice() == 0 && skr.balanceOf(pit) == 0;
        var ended = tip.era() > caged + 6 hours;
        assert(reg == Stage.Usual || reg == Stage.Caged && (empty || ended));
        jar.exit(msg.sender, ink);
    }

    //------------------------------------------------------------------

    function open() note auth returns (bytes32 cup) {
        assert(reg == Stage.Usual);
        cup = bytes32(++cupi);
        cups[cup].lad = msg.sender;
        // TODO replace this event with another solution
        LogNewCup(msg.sender, cup);
    }
    function shut(bytes32 cup) note auth {
        assert(reg == Stage.Usual);
        wipe(cup, tab(cup));
        free(cup, cups[cup].ink);
        delete cups[cup];
    }

    function lock(bytes32 cup, uint128 wad) note auth {
        assert(reg == Stage.Usual);
        assert(msg.sender == cups[cup].lad);
        cups[cup].ink = hadd(cups[cup].ink, wad);
        jar.pull(skr, msg.sender, wad);
    }
    function free(bytes32 cup, uint128 wad) note auth {
        assert(msg.sender == cups[cup].lad);
        cups[cup].ink = hsub(cups[cup].ink, wad);
        jar.push(skr, msg.sender, wad);
        assert(safe(cup));
    }

    function draw(bytes32 cup, uint128 wad) note auth {
        assert(reg == Stage.Usual);
        assert(msg.sender == cups[cup].lad);

        var pen = rdiv(wad, chi());
        cups[cup].art = wadd(cups[cup].art, pen);

        jug.lend(pot, wad);
        pot.push(sai, msg.sender, wad);

        assert(safe(cup));
        assert(cast(sin.totalSupply()) <= hat);
    }
    function wipe(bytes32 cup, uint128 wad) note auth {
        assert(reg == Stage.Usual);
        assert(msg.sender == cups[cup].lad);

        var pen = rdiv(wad, chi());
        cups[cup].art = wsub(cups[cup].art, pen);

        pot.pull(sai, msg.sender, wad);
        jug.mend(pot, wad);
    }

    function give(bytes32 cup, address lad) note auth {
        assert(msg.sender == cups[cup].lad);
        assert(lad != 0);
        cups[cup].lad = lad;
    }

    //------------------------------------------------------------------

    function tag() returns (uint128) {
        return reg == Stage.Usual ? jar.tag() : fit;
    }

    function bite(bytes32 cup) note auth {
        assert(!safe(cup) || reg == Stage.Caged);

        // take on all of the debt
        var rue = tab(cup);
        pot.push(sin, pit, rue);
        cups[cup].art = 0;

        // axe the collateral
        var owe = rmul(rue, axe);                    // amount owed inc. penalty
        var cab = wdiv(wmul(owe, tip.par()), tag());     // equivalent in skr
        var ink = cups[cup].ink;                     // available skr

        if (ink < cab) cab = ink;                    // take at most all the skr

        jar.push(skr, pit, cab);
        cups[cup].ink = hsub(cups[cup].ink, cab);
    }

    //------------------------------------------------------------------

    uint64 public caged;

    function cage() note auth {
        assert(reg == Stage.Usual);
        reg = Stage.Caged;
        fit = jar.tag();
        caged = tip.era();
    }
}
