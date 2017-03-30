/// tub.sol -- simplified CDP engine (baby brother of `vat')

// Copyright (C) 2017  Nikolai Mushegian <nikolai@dapphub.com>
// Copyright (C) 2017  Daniel Brockman <daniel@dapphub.com>
// Copyright (C) 2017  Rain <rainbreak@riseup.net>

pragma solidity ^0.4.8;

import "ds-auth/auth.sol";
import "ds-note/note.sol";
import "ds-math/math.sol";

import "ds-token/token.sol";
import "ds-vault/vault.sol";

// ref/gem is the only piece external data  (e.g. USD/ETH)
//    so there is a strong separation between "data feeds" and "policy"
// skr/gem is ratio of supply (outstanding skr to total locked gem)
// sai/ref decays ("holder fee")

// surplus also market makes for gem

// refprice(skr) := ethers per claim * tag
// risky := refprice(skr):refprice(debt) too high

contract Tub is DSAuth, DSNote, DSMath {
    DSToken  public  sai;  // Stablecoin
    DSToken  public  sin;  // Debt (negative sai)
    DSVault  public  ice;  // Good debt vault
    DSToken  public  skr;  // Abstracted collateral
    ERC20    public  gem;  // Underlying collateral

    uint128  public  tag;  // Gem price (in external reference unit)
    // TODO          zzz;  // Gem price expiration

    uint128  public  axe;  // Liquidation penalty
    uint128  public  hat;  // Debt ceiling
    uint128  public  mat;  // Liquidation ratio
    // uint64   public  lax;  // Grace period? --> No, only expiring feeds and killswitch
    // holder fee param
    // issuer fee param

    // surplus
    function joy() constant returns (uint128) {
        return uint128(sai.balanceOf(this));
    }
    // Bad debt
    function woe() constant returns (uint128) {
        return uint128(sin.balanceOf(this));
    }

    bool     public  off;  // Killswitch


    uint256                   public  cupi;
    mapping (bytes32 => Cup)  public  cups;

    struct Cup {
        address  lad;      // CDP owner

        uint128  art;      // Outstanding debt (in debt unit)
        uint128  ink;      // Locked collateral (in skr)
    }

    function Tub(ERC20 gem_, DSToken sai_, DSToken sin_, DSToken skr_, DSVault ice_) {
        gem = gem_;
        sai = sai_;
        sin = sin_;
        skr = skr_;
        ice = ice_;

        axe = RAY;
        mat = RAY;
    }

    function stop() note authorized("stop") {
        off = true;
    }

    function mark(uint128 wad) note authorized("mark") {
        tag = wad;
    }

    function chop(uint128 ray) note authorized("mold") {
        axe = ray;
    }
    function cork(uint128 wad) note authorized("mold") {
        hat = wad;
    }
    function cuff(uint128 ray) note authorized("mold") {
        mat = ray;
    }
    function calm(uint64 era) note authorized("mold") {
        //lax = era;
        throw;
    }

    function drip() note {
        // update `joy` (collect fees)
    }

    // skr per gem
    function per() constant returns (uint128) {
        // this avoids 0 edge case / rounding errors TODO delete me
        // TODO delegate edge case via fee built into conversion formula
        return skr.totalSupply() < 1 ether
            ? 1 ether
            : wdiv(uint128(gem.balanceOf(this)), uint128(skr.totalSupply()));
    }

    function join(uint128 jam) note {
        var ink = wmul(jam, per());
        gem.transferFrom(msg.sender, this, jam);
        skr.mint(ink);
        skr.push(msg.sender, ink);
    }
    function exit(uint128 ink) note {
        skr.pull(msg.sender, ink);
        skr.burn(ink);
        var jam = wdiv(ink, per());
        gem.transfer(msg.sender, jam);
    }

    function open() note returns (bytes32 cup) {
        cup = bytes32(++cupi);
        cups[cup].lad = msg.sender;
    }
    function shut(bytes32 cup) note {
        wipe(cup, cups[cup].art);
        free(cup, cups[cup].ink);
        delete cups[cup];
    }
    function give(bytes32 cup, address lad) note {
        aver(msg.sender == cups[cup].lad);
        cups[cup].lad = lad;
    }

    function lock(bytes32 cup, uint128 wad) note {
        aver(msg.sender == cups[cup].lad);
        // TODO
        cups[cup].ink = incr(cups[cup].ink, wad);
        skr.pull(msg.sender, wad);
        skr.push(ice, wad);
    }
    function free(bytes32 cup, uint128 wad) note {
        aver(msg.sender == cups[cup].lad);
        // TODO
        cups[cup].ink = decr(cups[cup].ink, wad);
        ice.push(skr, msg.sender, wad);
    }

    function safe(bytes32 cup) returns (bool) {
        // assert still overcollateralised
        var jam = wdiv(cups[cup].ink, per());
        var pro = wmul(jam, tag);
        var con = cups[cup].art;
        var min = rmul(con, mat);
        return (pro > min);
    }

    function draw(bytes32 cup, uint128 wad) note {
        // TODO poke
        aver(msg.sender == cups[cup].lad);
        cups[cup].art = incr(cups[cup].art, wad);

        aver(safe(cup));
        // TODO assert not over debt ceiling

        lend(wad);
        sin.push(ice, wad);
        sai.push(msg.sender, wad);
    }
    function wipe(bytes32 cup, uint128 wad) note {
        // TODO poke
        aver(msg.sender == cups[cup].lad);
        cups[cup].art = decr(cups[cup].art, wad);
        // TODO assert safe
        sai.pull(msg.sender, wad);
        ice.push(sin, this, wad);
        mend(wad);
    }

    function lend(uint128 wad) internal {
        sai.mint(wad);
        sin.mint(wad);
    }
    function mend(uint128 wad) internal {
        sai.burn(wad);
        sin.burn(wad);
    }
    function mend() internal {
        var omm = min(joy(), woe());
        mend(omm);
    }

    function bite(bytes32 cup) note {
        aver(!safe(cup));

        // take all of the debt
        var owe = cups[cup].art;
        ice.push(sin, this, owe);
        cups[cup].art = 0;

        // // axe the collateral
        var tab = rmul(owe, axe);
        var cab = rdiv(rmul(tab, per()), tag);
        var ink = cups[cup].ink;

        if (ink > cab) {
            cups[cup].ink = decr(cups[cup].ink, cab);
        } else {
            cups[cup].ink = 0;  // collateralisation under parity
            cab = ink;
        }

        ice.push(skr, this, cab);
    }

    // joy > 0 && woe > 0
    //    mend(min(joy,woe))
    // joy > 0
    //    boom
    // woe > 0
    //    bust

    // constant skr/sai mint/sell/buy/burn to process joy/woe
    // TODO one or both of these might work better with units inverted
    //     (ie arg is sai instead of skr)
    function boom(uint128 wad) note {
        mend();

        // price of wad in sai
        var ret = wdiv(wmul(wad, tag), per());
        aver(ret > joy());

        skr.pull(msg.sender, wad);
        skr.burn(wad);

        sai.push(msg.sender, ret);
    }
    function bust(uint128 wad) note {
        mend();

        var ret = wdiv(wmul(wad, tag), per());
        aver(ret > woe());

        if (skr.balanceOf(this) >= wad) {
            skr.push(msg.sender, wad);
        } else {
            var bal = uint128(skr.balanceOf(this));
            skr.push(msg.sender, bal);
            skr.mint(wad - bal);
            skr.push(msg.sender, wad - bal);
        }

        sai.pull(msg.sender, ret);
    }

    // TODO: could be here or on oracle object using same prism
    // function vote() {}
}
