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

    uint128  public  fix;  // sai kill price (gems per sai)
    uint128  public  fit;  // skr kill price (gems per skr)

    uint128 public fux;
    uint128 public par;

    function kill(uint128 price) note authorized("kill") {
        off = true;
        // price - sai per gem
        fux = price;

        // jam = air / per
        // pro = jam * tag
        // con = woe
        // collat = pro / con = air * tag / (per * woe)
        // xxx = air / collat = woe * per / tag = bye * per

        pot.push(sin, this);            // take on the debt
        var bye = wdiv(woe(), price);   // gems needed to cover debt

        skr.burn(cast(skr.balanceOf(this)));

        par = wdiv(decr(pie(), 0), cast(skr.totalSupply()));

        if (bye < pie()) {
            // share bye between all sai
            fix = wdiv(bye, woe());
            // skr gets the remainder
            // fit = wdiv(decr(pie(), bye), air());
            // var rem = decr(pie(), bye);

            // send the bye off to a separate vault so it doesn't
            // interfere with per
            var xxx = wmul(bye, per());          // burn the skr needed to cover the debt
            gem.transfer(pot, bye);

            pot.push(skr, this, xxx);
            skr.burn(xxx);

            fit = wdiv(pie(), cast(skr.totalSupply()));

            // TODO ^ no. need to only share with skr backing over collat cups.
            //            under collat cups get nothing.
            //     ---> but actually this is right, you do the cut per cup at `save`
            // also, what about free skr?

            // ok, so this is an average price over all skr, free locked whatever
            // we need a multiplier for each subclass

            // another way to think of it..
            // gems are partitioned off for sai holders (bye)
            // the remainder is for skr holders
            // *but* some of those skr holders are locked in
            // cups, the debt of which has been met
            // skr that is 100% backing the debt is in air, along with
            // the overcollat skr

            // so what does price mean?
            // we have the price of sai / gem
            // we also have the amount of gems remaining
            // and the debt that was backed by the skr
            // so we can work out the proportion by which to slash skr

            // fit should actually be calculated with the debt taken
            // into account, i.e. its the gem price of the skr *after*
            // the skr 100% backing the debt is taken away

            // air - xxx

            // how do we work out xxx?
            // outstanding debt = ice (careful, maybe all woe??)
            // settlement price = price (sai per gem)
            // debt in gems = ice / price
            // remaining gems = pie - bye
            // proportion = (ice / price) / (pie - bye) = p

            // (woe / price) / (pie - bye) = 1 / (pie / bye - 1)

            // xxx = air * p
            // fit = (pie - bye) / air (1 - p)

            // this is kind of it but doesn't tell the whole story.
            // there is also free skr.

            // burn xxx skr

            // limits:
            // system collat
            // 100%         xxx == air
            // 200%         xxx < air           xxx == air / 2 ??
            //  50%         xxx > air           xxx == air * 2 ??

            // how to determine system collat?
            // we have sai / gem
            // we have debt in sai
            // we have debt in gems

            // jam = air / per
            // pro = jam * tag
            // con = woe
            // collat = pro / con = air * tag / (per * woe)
            // xxx = air / collat = woe * per / tag

            // woah crazy, air drops out of it
            // ok so now burn xxx
            // now the remaining skr can be paid
            // per can be calculated with the remaining gems and skr
            // if free:
            //   payout at per
            // if overcollat:
            //   slash by ratio
            //   payout at per
            // if undercollat:
            //   nothing
        } else {
            fix = wdiv(pie(), woe());                  // share pie between all sai
            fit = 0;                                   // skr gets nothing (skr / gem)
            pot.push(skr, this, air());
            skr.burn(air());
        }
    }
    function save() note {
        // assert killed
        // take your sai, give you back gem
        //    extinguishes bad debt
        // take your skr, give you back gem
        // chop your collateral at ratio, give you back gem
        aver(off);

        var hai = cast(sai.balanceOf(msg.sender));
        sai.pull(msg.sender, hai);
        // gem.transfer(msg.sender, wmul(fix, hai));
        pot.push(gem, msg.sender, wmul(fix, hai));

        var ink = cast(skr.balanceOf(msg.sender));
        // var jam = wdiv(ink, per());
        var jam = wmul(ink, fit);
        skr.pull(msg.sender, ink);
        skr.burn(ink);
        gem.transfer(msg.sender, jam);

        mend();
    }
    event Log(string what, uint128 wad);
    function save(bytes32 cup) note {
        aver(msg.sender == cups[cup].lad);
        // undercollat
        if (!safe(cup)) {
            delete cups[cup];
            return;
        }
        // how much should we give back an overcollat cup holder?
        // they should get back everything!
        // but we have to bear in mind that we've already given them
        // some sai, so need to subtract that.

        var pro = cups[cup].ink;

        var con = cups[cup].art;

        // fix is gems per sai
        // fit is gems per skr
        var ret = decr(wmul(par, pro), wmul(fix, con));
        // var ret = wmul(fit, pro);
        Log('par', par);
        Log('fit', fit);
        Log('fux', fux);
        Log('fit * pro', wmul(fit, pro));
        Log('par * pro', wmul(par, pro));
        Log('fux * con', wmul(fux, con));
        Log('ret', ret);

        gem.transfer(msg.sender, ret)

        delete cups[cup];
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
