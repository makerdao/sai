/// tub.sol -- simplified CDP engine (baby brother of `vat')

// Copyright (C) 2017  Nikolai Mushegian <nikolai@dapphub.com>
// Copyright (C) 2017  Daniel Brockman <daniel@dapphub.com>
// Copyright (C) 2017  Rain <rainbreak@riseup.net>

pragma solidity ^0.4.15;

import "ds-thing/thing.sol";
import "ds-token/token.sol";
import "ds-value/value.sol";

import "./vox.sol";

contract SaiTubEvents {
    event LogNewCup(address indexed lad, bytes32 cup);
}

contract SaiTub is DSThing, DSWarp, SaiTubEvents {
    DSToken  public  sai;  // Stablecoin
    DSToken  public  sin;  // Debt (negative sai)

    DSToken  public  skr;  // Abstracted collateral
    ERC20    public  gem;  // Underlying collateral

    SaiVox   public  vox;  // Target price feed
    DSValue  public  pip;  // Reference price feed

    address  public  tap;  // Liquidator

    uint256  public  axe;  // Liquidation penalty
    uint256  public  hat;  // Debt ceiling
    uint256  public  mat;  // Liquidation ratio
    uint256  public  tax;  // Stability fee
    uint256  public  gap;  // Join-Exit Spread

    bool     public  off;  // Cage flag
    bool     public  out;  // Post cage exit

    uint256  public  fit;  // REF per SKR (just before settlement)

    uint64   public  rho;  // Time of last drip
    uint256         _chi;  // Price of internal debt unit

    uint256                   public  cupi;
    mapping (bytes32 => Cup)  public  cups;

    struct Cup {
        address  lad;      // CDP owner
        uint256  ink;      // Locked collateral (in SKR)
        uint256  art;      // Outstanding debt (in internal debt units)
    }

    function lad(bytes32 cup) constant returns (address) {
        return cups[cup].lad;
    }
    function ink(bytes32 cup) constant returns (uint) {
        return cups[cup].ink;
    }
    function tab(bytes32 cup) constant returns (uint) {
        return rmul(cups[cup].art, chi());
    }

    // Good debt
    function ice() constant returns (uint) {
        return sin.balanceOf(this);
    }
    // Backing collateral
    function air() constant returns (uint) {
        return skr.balanceOf(this);
    }
    // Raw collateral
    function pie() constant returns (uint) {
        return gem.balanceOf(this);
    }

    //------------------------------------------------------------------

    function SaiTub(
        DSToken  sai_,
        DSToken  sin_,
        DSToken  skr_,
        ERC20    gem_,
        DSValue  pip_,
        SaiVox   vox_,
        address  tap_
    ) {
        gem = gem_;
        skr = skr_;

        sai = sai_;
        sin = sin_;

        pip = pip_;
        vox = vox_;
        tap = tap_;

        axe = RAY;
        mat = RAY;
        tax = RAY;
        gap = WAD;

        _chi = RAY;

        rho = era();
    }

    //--Risk-parameter-config-------------------------------------------

    function mold(bytes32 param, uint val) note auth {
        if      (param == 'hat') hat = val;
        else if (param == 'mat') mat = val;
        else if (param == 'tax') { drip(); tax = val; }
        else if (param == 'axe') axe = val;
        else if (param == 'gap') gap = val;
        else return;
    }

    //--Collateral-wrapper----------------------------------------------

    // Wrapper ratio (gem per skr)
    function per() constant returns (uint ray) {
        return skr.totalSupply() == 0 ? RAY : rdiv(pie(), skr.totalSupply());
    }
    // Join price (gem per skr)
    function ask(uint wad) constant returns (uint) {
        return rmul(wad, wmul(per(), gap));
    }
    // Exit price (gem per skr)
    function bid(uint wad) constant returns (uint) {
        return rmul(wad, wmul(per(), sub(2 * WAD, gap)));
    }
    function join(uint wad) note {
        require(!off);
        gem.transferFrom(msg.sender, this, ask(wad));
        skr.mint(msg.sender, wad);
    }
    function exit(uint wad) note {
        require(!off || out);
        gem.transfer(msg.sender, bid(wad));
        skr.burn(msg.sender, wad);
    }

    //--Stability-fee-accumulation--------------------------------------

    // Internal debt price (sai per debt unit)
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

    //--CDP-risk-indicator----------------------------------------------

    // Abstracted collateral price (ref per skr)
    function tag() constant returns (uint wad) {
        return off ? fit : wmul(per(), uint(pip.read()));
    }
    // Returns true if cup is well-collateralized
    function safe(bytes32 cup) constant returns (bool) {
        var pro = rmul(tag(), ink(cup));
        var con = rmul(vox.par(), tab(cup));
        var min = rmul(con, mat);
        return pro >= min;
    }

    //--Anti-corruption-aliases-----------------------------------------

    function lend(address dst, uint wad) internal {
        sin.mint(wad);
        sai.mint(dst, wad);
    }
    function mend(address src, uint wad) internal {
        sai.burn(src, wad);
        sin.burn(wad);
    }

    //--CDP-operations--------------------------------------------------

    function open() note returns (bytes32 cup) {
        require(!off);
        cup = bytes32(++cupi);
        cups[cup].lad = msg.sender;
        LogNewCup(msg.sender, cup);
    }
    function give(bytes32 cup, address guy) note {
        require(msg.sender == cups[cup].lad);
        require(guy != 0);
        cups[cup].lad = guy;
    }

    function lock(bytes32 cup, uint wad) note {
        require(!off);
        require(msg.sender == cups[cup].lad);
        cups[cup].ink = add(cups[cup].ink, wad);
        skr.pull(msg.sender, wad);
    }
    function free(bytes32 cup, uint wad) note {
        require(msg.sender == cups[cup].lad);
        cups[cup].ink = sub(cups[cup].ink, wad);
        skr.push(msg.sender, wad);
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

    function shut(bytes32 cup) note {
        require(!off);
        wipe(cup, tab(cup));
        free(cup, cups[cup].ink);
        delete cups[cup];
    }

    function bite(bytes32 cup) note {
        require(!safe(cup) || off);

        // Take on all of the debt
        var rue = tab(cup);
        sin.push(tap, rue);
        cups[cup].art = 0;

        // Amount owed in SKR, including liquidation penalty
        var owe = rdiv(rmul(rmul(rue, axe), vox.par()), tag());

        if (owe > cups[cup].ink) {
            owe = cups[cup].ink;
        }

        skr.push(tap, owe);
        cups[cup].ink = sub(cups[cup].ink, owe);
    }

    //------------------------------------------------------------------

    function cage(uint fit_, uint jam) note auth {
        require(!off);
        off = true;
        fit = fit_;         // ref per skr
        gem.transfer(tap, jam);
    }
    function flow() note auth {
        require(off);
        out = true;
    }
}
