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

    // Good debt
    function tag() constant returns (uint128) {
        return uint128(_tag.read());
    }
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

    uint128  public  ooh;  // sai kill price
    uint128  public  ahh;  // skr kill price

    function kill(uint128 price) note authorized("kill") {
        off = true;
        // price - sai per gem

        pot.push(sin, this);       // take on the debt
        var bye = woe() / price;   // gems needed to cover debt

        if (bye < pie()) {
            ooh = bye / woe();                             // share bye between all sai
            ahh = (bye - pie()) / cast(skr.totalSupply()); // skr gets the remainder
            // TODO ^ no. need to only share with skr backing over collat cups.
            //            under collat cups get nothing.
            //     ---> but actually this is right, you do the cut per cup at `save`
        } else {
            ooh = pie() / woe();                           // share pie between all sai
            ahh = 0;                                       // skr gets nothing (skr / gem)
        }
    }
    function save() note {
        // assert killed
        // take your sai, give you back gem
        //    extinguishes bad debt
        // take your skr, give you back gem
        // chop your collateral at ratio, give you back gem
        aver(off);

        var hai = sai.balanceOf(msg.sender);
        sai.pull(msg.sender, cast(hai));
        gem.transfer(msg.sender, hai / ooh);

        var kek = skr.balanceOf(msg.sender);
        skr.pull(msg.sender, cast(kek));
        gem.transfer(msg.sender, kek / ahh);

        mend();
    }
    function save(bytes32 cup) note {
        save();
        // TODO this penalises all cup holders the same, whether under
        // or over collat
        gem.transfer(msg.sender, cups[cup].ink / ahh);
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
        cups[cup].ink = incr(cups[cup].ink, wad);
        pot.pull(skr, msg.sender, wad);
    }
    function free(bytes32 cup, uint128 wad) note {
        aver(msg.sender == cups[cup].lad);
        cups[cup].ink = decr(cups[cup].ink, wad);
        aver(safe(cup));
        pot.push(skr, msg.sender, wad);
    }

    // returns true if overcollateralized
    function safe(bytes32 cup) constant returns (bool) {
        var jam = wdiv(cups[cup].ink, per());
        var pro = wmul(jam, tag());
        var con = cups[cup].art;
        var min = rmul(con, mat);
        return (pro >= min);
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
