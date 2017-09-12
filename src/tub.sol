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

contract SaiTubEvents {
    event LogNewCup(address indexed lad, bytes32 cup);
}

contract SaiTub is DSThing, SaiTubEvents {
    SaiTip   public  tip;  // Target price source

    DSToken  public  sai;  // Stablecoin
    DSToken  public  sin;  // Debt (negative sai)
    SaiJug   public  jug;  // Sai/sin accountant

    DSToken  public  skr;  // Abstracted collateral
    ERC20    public  gem;  // Underlying collateral

    SaiJar   public  jar;  // Collateral vault
    DSVault  public  pot;  // Good debt vault
    address  public  pit;  // Liquidator vault

    uint128  public  axe;  // Liquidation penalty
    uint128  public  hat;  // Debt ceiling
    uint128  public  mat;  // Liquidation ratio
    uint128  public  tax;  // Stability fee

    bool     public  off;  // Cage flag

    uint128  public  fit;  // Gem per SKR (just before settlement)

    uint64   public  rho;  // Time of last drip
    uint128         _chi;  // Price of internal debt unit

    uint256                   public  cupi;
    mapping (bytes32 => Cup)  public  cups;

    struct Cup {
        address  lad;      // CDP owner
        uint128  art;      // Outstanding debt (in internal debt units)
        uint128  ink;      // Locked collateral (in SKR)
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

    function SaiTub(
        SaiJar   jar_,
        SaiJug   jug_,
        DSVault  pot_,
        DSVault  pit_,
        SaiTip      tip_
    ) {
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
        assert(axe >= RAY && axe <= mat);
    }
    function cork(uint128 wad) note auth {
        hat = wad;
    }
    function cuff(uint128 ray) note auth {
        mat = ray;
        assert(axe >= RAY && axe <= mat);
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
        if (off) return;

        var age = tip.era() - rho;
        var inc = rpow(tax, age);
        var dew = wsub(rmul(ice(), inc), ice());

        jug.lend(pot, dew);
        pot.push(sai, pit, dew);

        _chi = rmul(_chi, inc);
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

    // Returns true if cup is well-collateralized
    function safe(bytes32 cup) constant returns (bool) {
        var pro = wmul(jar.tag(), ink(cup));
        var con = wmul(tip.par(), tab(cup));
        var min = rmul(con, mat);
        return pro >= min;
    }

    //------------------------------------------------------------------

    function join(uint128 wad) note auth {
        assert(!off);
        jar.join(msg.sender, wad);
    }
    function exit(uint128 wad) note auth {
        var empty = ice() == 0 && skr.balanceOf(pit) == 0;
        var ended = tip.era() > caged + cooldown;
        assert(!off || empty || ended);
        jar.exit(msg.sender, wad);
    }

    //------------------------------------------------------------------

    function open() note auth returns (bytes32 cup) {
        assert(!off);
        cup = bytes32(++cupi);
        cups[cup].lad = msg.sender;
        LogNewCup(msg.sender, cup);
    }
    function shut(bytes32 cup) note auth {
        assert(!off);
        wipe(cup, tab(cup));
        free(cup, cups[cup].ink);
        delete cups[cup];
    }

    function lock(bytes32 cup, uint128 wad) note auth {
        assert(!off);
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
        assert(!off);
        assert(msg.sender == cups[cup].lad);

        cups[cup].art = wadd(cups[cup].art, rdiv(wad, chi()));

        jug.lend(pot, wad);
        pot.push(sai, msg.sender, wad);

        assert(safe(cup));
        assert(cast(sin.totalSupply()) <= hat);
    }
    function wipe(bytes32 cup, uint128 wad) note auth {
        assert(!off);
        assert(msg.sender == cups[cup].lad);

        cups[cup].art = wsub(cups[cup].art, rdiv(wad, chi()));

        pot.pull(sai, msg.sender, wad);
        jug.mend(pot, wad);
    }

    function give(bytes32 cup, address guy) note auth {
        assert(msg.sender == cups[cup].lad);
        assert(guy != 0);
        cups[cup].lad = guy;
    }

    //------------------------------------------------------------------

    function tag() returns (uint128) {
        return off ? fit : jar.tag();
    }

    function bite(bytes32 cup) note auth {
        assert(!safe(cup) || off);

        // Take on all of the debt
        var rue = tab(cup);
        pot.push(sin, pit, rue);
        cups[cup].art = 0;

        // Amount owed in SKR, including liquidation penalty
        var owe = wdiv(wmul(rmul(rue, axe), tip.par()), tag());

        if (owe > cups[cup].ink) {
            owe = cups[cup].ink;
        }

        jar.push(skr, pit, owe);
        cups[cup].ink = hsub(cups[cup].ink, owe);
    }

    //------------------------------------------------------------------

    uint64 public caged;
    uint64 public cooldown = 6 hours;

    function setCooldown(uint64 cooldown_) note auth {
        cooldown = cooldown_;
    }

    function cage(uint128 fit_) note auth {
        assert(!off);
        off = true;
        fit = fit_;         // ref per skr
        caged = tip.era();
    }
}
