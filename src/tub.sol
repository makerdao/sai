/// tub.sol -- simplified CDP engine (baby brother of `vat')

// Copyright (C) 2017  Nikolai Mushegian <nikolai@dapphub.com>
// Copyright (C) 2017  Daniel Brockman <daniel@dapphub.com>
// Copyright (C) 2017  Rain <rainbreak@riseup.net>

pragma solidity ^0.4.8;

import "ds-thing/thing.sol";
import "ds-token/token.sol";
import "ds-vault/vault.sol";
import "ds-value/value.sol";

// ref/gem is the only piece external data  (e.g. USD/ETH)
//    so there is a strong separation between "data feeds" and "policy"
// skr/gem is ratio of supply (outstanding skr to total locked gem)
// sai/ref decays ("holder fee")

// surplus also market makes for gem

// refprice(skr) := ethers per claim * tag
// risky := refprice(skr):refprice(debt) too high

contract Tub is DSThing {
    DSToken  public  sai;  // Stablecoin
    DSToken  public  sin;  // Debt (negative sai)
    DSVault  public  pot;  // Good debt vault
    DSToken  public  skr;  // Abstracted collateral
    ERC20    public  gem;  // Underlying collateral

    // TODO name
    DSValue  public  _tag;  // Gem price feed (in external reference unit)

    uint128  public  axe;  // Liquidation penalty
    uint128  public  hat;  // Debt ceiling
    uint128  public  mat;  // Liquidation ratio

    uint128  public  fix;  // sai kill price (sai per gem)
    uint128  public  fit;  // skr kill price (gem per skr)
    uint128  public  par;  // ratio of gem to skr on kill
    // TODO holder fee param
    // TODO issuer fee param
    // TODO spread??

    // Price of gem in ref
    function tag() constant returns (uint128) {
        return uint128(_tag.read());
    }
    // Good debt
    function ice() constant returns (uint128) {
        return uint128(sin.balanceOf(pot));
    }
    // Backing collateral
    function air() constant returns (uint128) {
        return uint128(skr.balanceOf(pot));
    }
    // surplus
    function joy() constant returns (uint128) {
        return uint128(sai.balanceOf(this));
    }
    // Bad debt
    function woe() constant returns (uint128) {
        return uint128(sin.balanceOf(this));
    }
    // Collateral pending liquidation
    function fog() constant returns (uint128) {
        return uint128(skr.balanceOf(this));
    }
    // Raw collateral
    function pie() constant returns (uint128) {
        return uint128(gem.balanceOf(this));
    }

    bool     public  off;  // Killswitch

    uint256                   public  cupi;
    mapping (bytes32 => Cup)  public  cups;

    struct Cup {
        address  lad;      // CDP owner

        uint128  art;      // Outstanding debt (in debt unit)
        uint128  ink;      // Locked collateral (in skr)
    }

    function Tub(ERC20 gem_, DSToken sai_, DSToken sin_, DSToken skr_, DSVault pot_, DSValue tag_) {
        gem = gem_;
        sai = sai_;
        sin = sin_;
        skr = skr_;
        pot = pot_;

        axe = RAY;
        mat = RAY;
        _tag = tag_;
    }

    // force settlement of the system at a given price (ref per gem).
    // This is nearly the equivalent of biting all cups at once.
    // Important consideration: the gems associated with free skr can
    // be tapped to make sai whole.
    function kill(uint128 price) note auth {
        off = true;
        // take on the debt
        pot.push(sin, this);
        // absorb any pending fees
        mend();
        // burn pending sale skr
        skr.burn(cast(skr.balanceOf(this)));

        // save current gem per skr for collateral calc.
        // we need to know this to work out the gem value of a cups pro
        par = per();

        // most gems we can get per sai is the full balance
        fix = max(price, wdiv(woe(), pie()));
        // gems needed to cover debt, or at most all of the gems we have
        var bye = min(pie(), wdiv(woe(), price));
        // skr associated with gems, or at most all the backing skr
        var xxx = min(air(), wdiv(bye, per()));
        // There can be free skr as well, and gems associated with this
        // are used to make sai whole.

        // put the gems backing sai in a safe place and burn the
        // associated skr.
        pot.push(skr, this, xxx);
        skr.burn(xxx);
        gem.transfer(pot, bye);

        // the remaining pie gets shared out among remaining skr
        fit = (pie() == 0) ? 0 : per();
    }
    // exchange free sai / skr for gems after kill
    function save() note {
        aver(off);

        var hai = cast(sai.balanceOf(msg.sender));
        sai.pull(msg.sender, hai);
        mend(hai);
        pot.push(gem, msg.sender, wdiv(hai, fix));

        var ink = cast(skr.balanceOf(msg.sender));
        var jam = wmul(ink, fit);
        skr.pull(msg.sender, ink);
        skr.burn(ink);
        gem.transfer(msg.sender, jam);
    }
    function save(bytes32 cup) note {
        aver(off);
        aver(msg.sender == cups[cup].lad);

        var pro = wmul(cups[cup].ink, par);
        var con = wdiv(cups[cup].art, fix);

        // at least 100% collat?
        if (pro > con) {
            gem.transfer(msg.sender, decr(pro, con));
        }

        delete cups[cup];
    }

    function chop(uint128 ray) note auth) {
        axe = ray;
    }
    function cork(uint128 wad) note auth {
        hat = wad;
    }
    function cuff(uint128 ray) note auth {
        mat = ray;
    }

    function drip() note {
        // update `joy` (collect fees)
        // TODO implement fees
    }

    // skr per gem
    function per() constant returns (uint128) {
        // this avoids 0 edge case / rounding errors TODO delete me
        // TODO delegate edge case via fee built into conversion formula
        // TODO could also initialize with 1 gem and 1 skr, send skr to 0x0
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
        var jam = wdiv(ink, per());
        skr.pull(msg.sender, ink);
        skr.burn(ink);
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
        cups[cup].ink = incr(cups[cup].ink, wad);
        pot.pull(skr, msg.sender, wad);
    }
    function free(bytes32 cup, uint128 wad) note {
        aver(msg.sender == cups[cup].lad);
        cups[cup].ink = decr(cups[cup].ink, wad);
        aver(safe(cup));
        pot.push(skr, msg.sender, wad);
    }

    // returns true if cup overcollateralized
    function safe(bytes32 cup) constant returns (bool) {
        var jam = wdiv(cups[cup].ink, per());
        var pro = wmul(jam, tag());
        var con = cups[cup].art;
        var min = rmul(con, mat);
        return (pro >= min);
    }
    // returns true if system overcollateralized
    function safe() constant returns (bool) {
        var pro = wmul(air(), tag());
        var con = cast(sin.totalSupply());
        var min = rmul(con, mat);
        return (pro >= min);
    }
    // returns true if system in deficit
    function eek() constant returns (bool) {
        var pro = wmul(air(), tag());
        var con = cast(sin.totalSupply());
        return (pro < con);
    }

    function draw(bytes32 cup, uint128 wad) note {
        // TODO poke
        aver(msg.sender == cups[cup].lad);
        cups[cup].art = incr(cups[cup].art, wad);
        aver(safe(cup));

        lend(wad);
        sin.push(pot, wad);
        sai.push(msg.sender, wad);

        aver(ice() <= hat);  // ensure under debt ceiling
    }
    function wipe(bytes32 cup, uint128 wad) note {
        // TODO poke
        aver(msg.sender == cups[cup].lad);
        cups[cup].art = decr(cups[cup].art, wad);

        sai.pull(msg.sender, wad);
        pot.push(sin, this, wad);
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
        pot.push(sin, this, owe);
        cups[cup].art = 0;

        // axe the collateral
        var tab = rmul(owe, axe);
        var cab = rdiv(rmul(tab, per()), tag());
        var ink = cups[cup].ink;

        if (ink > cab) {
            cups[cup].ink = decr(cups[cup].ink, cab);
        } else {
            cups[cup].ink = 0;  // collateralisation under parity
            cab = ink;
        }

        pot.push(skr, this, cab);
    }

    // constant skr/sai mint/sell/buy/burn to process joy/woe
    function boom(uint128 wad) note {
        mend();

        // price of wad in sai
        var ret = wdiv(wmul(wad, tag()), per());
        aver(ret <= joy());

        skr.pull(msg.sender, wad);
        skr.burn(wad);

        sai.push(msg.sender, ret);
    }
    function bust(uint128 wad) note {
        mend();

        var ret = wdiv(wmul(wad, tag()), per());
        aver(ret <= woe());

        if (wad <= fog()) {
            skr.push(msg.sender, wad);
        } else {
            var bal = fog();
            skr.push(msg.sender, bal);
            skr.mint(wad - bal);
            skr.push(msg.sender, wad - bal);
        }

        sai.pull(msg.sender, ret);
    }
}
