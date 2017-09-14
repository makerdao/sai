/// tub.sol -- simplified CDP engine (baby brother of `vat')

// Copyright (C) 2017  Nikolai Mushegian <nikolai@dapphub.com>
// Copyright (C) 2017  Daniel Brockman <daniel@dapphub.com>
// Copyright (C) 2017  Rain <rainbreak@riseup.net>

pragma solidity ^0.4.10;

import "ds-thing/thing.sol";
import "ds-token/token.sol";
import "ds-vault/vault.sol";

import "./tip.sol";
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

contract SaiTub is DSThing, DSWarp, SaiTubEvents {
    SaiTip   public  tip;  // Target price source

    DSToken  public  sai;  // Stablecoin
    DSToken  public  sin;  // Debt (negative sai)

    DSToken  public  skr;  // Abstracted collateral
    ERC20    public  gem;  // Underlying collateral

    SaiJar   public  jar;  // Collateral vault
    address  public  tap;  // Liquidator

    uint256  public  axe;  // Liquidation penalty
    uint256  public  hat;  // Debt ceiling
    uint256  public  mat;  // Liquidation ratio
    uint256  public  tax;  // Stability fee

    bool     public  off;  // Cage flag

    uint256  public  fit;  // Gem per SKR (just before settlement)

    uint64   public  rho;  // Time of last drip
    uint256         _chi;  // Price of internal debt unit

    uint256                   public  cupi;
    mapping (bytes32 => Cup)  public  cups;

    struct Cup {
        address  lad;      // CDP owner
        uint  art;      // Outstanding debt (in internal debt units)
        uint  ink;      // Locked collateral (in SKR)
    }

    function tab(bytes32 cup) constant returns (uint) {
        return rmul(cups[cup].art, chi());
    }
    function ink(bytes32 cup) constant returns (uint) {
        return cups[cup].ink;
    }
    function lad(bytes32 cup) constant returns (address) {
        return cups[cup].lad;
    }

    //------------------------------------------------------------------

    function SaiTub(
        DSToken  sai_,
        DSToken  sin_,
        SaiJar   jar_,
        SaiTip   tip_,
        address  tap_
    ) {
        jar = jar_;
        gem = jar.gem();
        skr = jar.skr();

        sai = sai_;
        sin = sin_;
        tap = tap_;

        axe = RAY;
        mat = RAY;
        tax = RAY;

        _chi = RAY;

        tip = tip_;
        rho = era();
    }

    function chop(uint ray) note auth {
        axe = ray;
        require(axe >= RAY && axe <= mat);
    }
    function cork(uint wad) note auth {
        hat = wad;
    }
    function cuff(uint ray) note auth {
        mat = ray;
        require(axe >= RAY && axe <= mat);
    }
    function crop(uint ray) note auth {
        drip();
        tax = ray;
        require(RAY <= tax);
        require(tax < 10002 * 10 ** 23);  // ~200% per hour
    }

    function chi() returns (uint) {
        drip();
        return _chi;
    }
    function drip() note {
        if (off) return;

        var rho_ = era();
        var age = rho_ - rho;
        if (age == 0) return;    // optimised
        rho = rho_;

        if (tax == RAY) return;  // optimised
        var inc = rpow(tax, age);

        if (inc == RAY) return;  // optimised
        var dew = sub(rmul(ice(), inc), ice());
        lend(tap, dew);
        _chi = rmul(_chi, inc);
    }

    // Good debt
    function ice() constant returns (uint) {
        return sin.balanceOf(this);
    }
    // Raw collateral
    function pie() constant returns (uint) {
        return gem.balanceOf(jar);
    }
    // Backing collateral
    function air() constant returns (uint) {
        return skr.balanceOf(jar);
    }

    // Returns true if cup is well-collateralized
    function safe(bytes32 cup) constant returns (bool) {
        var pro = wmul(jar.tag(), ink(cup));
        var con = wmul(tip.par(), tab(cup));
        var min = rmul(con, mat);
        return pro >= min;
    }

    //------------------------------------------------------------------

    function open() note returns (bytes32 cup) {
        require(!off);
        cup = bytes32(++cupi);
        cups[cup].lad = msg.sender;
        LogNewCup(msg.sender, cup);
    }
    function shut(bytes32 cup) note {
        require(!off);
        wipe(cup, tab(cup));
        free(cup, cups[cup].ink);
        delete cups[cup];
    }

    function lock(bytes32 cup, uint wad) note {
        require(!off);
        require(msg.sender == cups[cup].lad);
        cups[cup].ink = add(cups[cup].ink, wad);
        jar.pull(skr, msg.sender, wad);
    }
    function free(bytes32 cup, uint wad) note {
        require(msg.sender == cups[cup].lad);
        cups[cup].ink = sub(cups[cup].ink, wad);
        jar.push(skr, msg.sender, wad);
        require(safe(cup));
    }

    function draw(bytes32 cup, uint wad) note {
        require(!off);
        require(msg.sender == cups[cup].lad);

        cups[cup].art = add(cups[cup].art, rdiv(wad, chi()));
        lend(cups[cup].lad, wad);

        require(safe(cup));
        require(sin.totalSupply() <= hat);
    }
    function wipe(bytes32 cup, uint wad) note {
        require(!off);
        require(msg.sender == cups[cup].lad);

        cups[cup].art = sub(cups[cup].art, rdiv(wad, chi()));
        mend(cups[cup].lad, wad);
    }

    function give(bytes32 cup, address guy) note {
        require(msg.sender == cups[cup].lad);
        require(guy != 0);
        cups[cup].lad = guy;
    }

    //------------------------------------------------------------------

    function tag() returns (uint) {
        return off ? fit : jar.tag();
    }

    function bite(bytes32 cup) note {
        require(!safe(cup) || off);

        // Take on all of the debt
        var rue = tab(cup);
        sin.push(tap, rue);
        cups[cup].art = 0;

        // Amount owed in SKR, including liquidation penalty
        var owe = wdiv(wmul(rmul(rue, axe), tip.par()), tag());

        if (owe > cups[cup].ink) {
            owe = cups[cup].ink;
        }

        jar.push(skr, tap, owe);
        cups[cup].ink = sub(cups[cup].ink, owe);
    }

    //-- anti-corruption wrapper ---------------------------------------

    function lend(address dst, uint wad) internal {
        sin.mint(wad);
        sai.mint(dst, wad);
    }
    function mend(address src, uint wad) internal {
        sai.burn(src, wad);
        sin.burn(wad);
    }

    //------------------------------------------------------------------

    function cage(uint fit_) note auth {
        require(!off);
        off = true;
        fit = fit_;         // ref per skr
    }
}
