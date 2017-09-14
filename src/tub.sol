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

contract SaiTub is DSThing, SaiTubEvents {
    SaiTip   public  tip;  // Target price source

    DSToken  public  sai;  // Stablecoin
    DSToken  public  sin;  // Debt (negative sai)

    DSToken  public  skr;  // Abstracted collateral
    ERC20    public  gem;  // Underlying collateral

    SaiJar   public  jar;  // Collateral vault
    DSVault  public  pot;  // Good debt vault
    address  public  pit;  // Liquidator vault

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
        uint256  art;      // Outstanding debt (in internal debt units)
        uint256  ink;      // Locked collateral (in SKR)
    }

    function tab(bytes32 cup) constant returns (uint256) {
        return rmul(cups[cup].art, chi());
    }
    function ink(bytes32 cup) constant returns (uint256) {
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
        DSVault  pot_,
        DSVault  pit_,
        SaiTip      tip_
    ) {
        jar = jar_;
        gem = jar.gem();
        skr = jar.skr();

        sai = sai_;
        sin = sin_;
        pot = pot_;
        pit = pit_;

        axe = RAY;
        mat = RAY;
        tax = RAY;

        _chi = RAY;

        tip = tip_;
        rho = tip.era();
    }

    function chop(uint256 ray) note auth {
        axe = ray;
        assert(axe >= RAY && axe <= mat);
    }
    function cork(uint256 wad) note auth {
        hat = wad;
    }
    function cuff(uint256 ray) note auth {
        mat = ray;
        assert(axe >= RAY && axe <= mat);
    }
    function crop(uint256 ray) note auth {
        drip();
        tax = ray;
        assert(RAY <= tax);
        assert(tax < 10002 * 10 ** 23);  // ~200% per hour
    }

    function chi() returns (uint256) {
        drip();
        return _chi;
    }
    function drip() note {
        if (off) return;

        var age = tip.era() - rho;
        var inc = rpow(tax, age);
        var dew = sub(rmul(ice(), inc), ice());

        lend(pot, pit, dew);

        _chi = rmul(_chi, inc);
        rho = tip.era();
    }

    // Good debt
    function ice() constant returns (uint256) {
        return uint256(sin.balanceOf(pot));
    }
    // Raw collateral
    function pie() constant returns (uint256) {
        return uint256(gem.balanceOf(jar));
    }
    // Backing collateral
    function air() constant returns (uint256) {
        return uint256(skr.balanceOf(jar));
    }

    // Returns true if cup is well-collateralized
    function safe(bytes32 cup) constant returns (bool) {
        var pro = wmul(jar.tag(), ink(cup));
        var con = wmul(tip.par(), tab(cup));
        var min = rmul(con, mat);
        return pro >= min;
    }

    //------------------------------------------------------------------

    function join(uint256 wad) note auth {
        assert(!off);
        jar.join(msg.sender, wad);
    }
    function exit(uint256 wad) note auth {
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

    function lock(bytes32 cup, uint256 wad) note auth {
        assert(!off);
        assert(msg.sender == cups[cup].lad);
        cups[cup].ink = add(cups[cup].ink, wad);
        jar.pull(skr, msg.sender, wad);
    }
    function free(bytes32 cup, uint256 wad) note auth {
        assert(msg.sender == cups[cup].lad);
        cups[cup].ink = sub(cups[cup].ink, wad);
        jar.push(skr, msg.sender, wad);
        assert(safe(cup));
    }

    function draw(bytes32 cup, uint256 wad) note auth {
        assert(!off);
        assert(msg.sender == cups[cup].lad);

        cups[cup].art = add(cups[cup].art, rdiv(wad, chi()));
        lend(pot, cups[cup].lad, wad);

        assert(safe(cup));
        assert(sin.totalSupply() <= hat);
    }
    function wipe(bytes32 cup, uint256 wad) note auth {
        assert(!off);
        assert(msg.sender == cups[cup].lad);

        cups[cup].art = sub(cups[cup].art, rdiv(wad, chi()));
        mend(cups[cup].lad, pot, wad);
    }

    function give(bytes32 cup, address guy) note auth {
        assert(msg.sender == cups[cup].lad);
        assert(guy != 0);
        cups[cup].lad = guy;
    }

    //------------------------------------------------------------------

    function tag() returns (uint256) {
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
        cups[cup].ink = sub(cups[cup].ink, owe);
    }

    //------------------------------------------------------------------

    uint64 public caged;
    uint64 public cooldown = 6 hours;

    function setCooldown(uint64 cooldown_) note auth {
        cooldown = cooldown_;
    }

    function cage(uint256 fit_) note auth {
        assert(!off);
        off = true;
        fit = fit_;         // ref per skr
        caged = tip.era();
    }

    //-- anti-corruption wrapper ---------------------------------------

    function lend(address src, address dst, uint wad) internal {
        sin.mint(src, wad);
        sai.mint(dst, wad);
    }
    function mend(address src, address dst, uint wad) internal {
        sai.burn(src, wad);
        sin.burn(dst, wad);
    }
    function heal(address guy) note {
        var joy = sai.balanceOf(guy);
        var woe = sin.balanceOf(guy);
        mend(guy, guy, min(joy, woe));
    }
}
