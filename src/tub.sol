/// tub.sol -- simplified CDP engine (baby brother of `vat')

// Copyright (C) 2017  Nikolai Mushegian <nikolai@dapphub.com>
// Copyright (C) 2017  Daniel Brockman <daniel@dapphub.com>
// Copyright (C) 2017  Rain <rainbreak@riseup.net>

pragma solidity ^0.4.10;

import "ds-thing/thing.sol";
import "ds-token/token.sol";
import "ds-vault/vault.sol";
import "ds-value/value.sol";
import "ds-warp/warp.sol";

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

contract Tub is DSThing, DSWarp, TubEvents {
    DSToken  public  sai;  // Stablecoin
    DSToken  public  sin;  // Debt (negative sai)
    DSVault  public  pot;  // Good debt vault
    DSToken  public  skr;  // Abstracted collateral
    ERC20    public  gem;  // Underlying collateral

    DSValue  public  tip;  // Gem price feed (in external reference unit)

    uint128  public  axe;  // Liquidation penalty
    uint128  public  hat;  // Debt ceiling
    uint128  public  mat;  // Liquidation ratio
    uint128  public  tax;  // Stability fee

    enum Stage { Usual, Caged, Empty }
    Stage    public  reg;  // 'register'

    uint128  public  fix;  // sai kill price (gem per sai)
    uint128  public  par;  // gem per skr (just before settlement)
    // TODO holder fee param
    // TODO spread?? `gap`
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

    function Tub(ERC20 gem_, DSToken sai_, DSToken sin_, DSToken skr_, DSVault pot_, DSValue tip_) {
        gem = gem_;
        sai = sai_;
        sin = sin_;
        skr = skr_;
        pot = pot_;

        axe = RAY;
        mat = RAY;
        tax = RAY;

        _chi = RAY;

        tip = tip_;
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

    function chi() internal returns (uint128) {
        drip();
        return _chi;
    }
    function drip() note {
        if (reg != Stage.Usual) return;  // noop if system caged

        var age = era() - rho;
        var chi = rmul(_chi, rpow(tax, age));
        var rum = rdiv(ice(), _chi);
        var dew = rmul(rum, rsub(chi, _chi));

        lend(dew);
        sin.push(pot, dew);

        _chi = chi;
        rho = era();
    }

    // Good debt
    function ice() constant returns (uint128) {
        return uint128(sin.balanceOf(pot));
    }
    // Bad debt
    function woe() constant returns (uint128) {
        return uint128(sin.balanceOf(this));
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
        return uint128(skr.balanceOf(this));
    }
    // surplus
    function joy() constant returns (uint128) {
        return uint128(sai.balanceOf(this));
    }

    // Price of gem in ref
    function tag() constant returns (uint128) {
        return uint128(tip.read());
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
        var jam = rmul(cups[cup].ink, per());
        var pro = wmul(jam, tag());
        var con = tab(cup);
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

        lend(wad);
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
        mend(wad);

        assert(safe(cup));
        assert(cast(sin.totalSupply()) <= hat);
    }

    function give(bytes32 cup, address lad) auth note {
        assert(msg.sender == cups[cup].lad);
        assert(lad != 0);
        cups[cup].lad = lad;
    }

    //------------------------------------------------------------------

    function lend(uint128 wad) internal {
        sai.mint(wad);
        sin.mint(wad);
    }
    function mend(uint128 wad) internal {
        sai.burn(wad);
        sin.burn(wad);
    }
    function mend() internal {
        var omm = hmin(joy(), woe());
        mend(omm);
    }

    //------------------------------------------------------------------

    function bite(bytes32 cup) auth note {
        assert(reg == Stage.Usual);
        assert(!safe(cup));

        // take on all of the debt
        var rue = tab(cup);
        pot.push(sin, this, rue);
        cups[cup].art = 0;

        // axe the collateral
        var owe = rmul(rue, axe);                    // amount owed inc. penalty
        var cab = wdiv(owe, rmul(tag(), per()));     // equivalent in skr
        var ink = cups[cup].ink;                     // available skr

        if (ink < cab) cab = ink;                    // take at most all the skr

        pot.push(skr, this, cab);
        cups[cup].ink = hsub(cups[cup].ink, cab);
    }
    // constant skr/sai mint/sell/buy/burn to process joy/woe
    function boom(uint128 wad) auth note {
        assert(reg == Stage.Usual);
        drip();
        mend();
        assert(wad <= joy());

        // price of wad in skr after burning `jam` `skr`
        var jam = wdiv(uint128(skr.totalSupply()), hadd(wdiv(wmul(tag(), pie()), wad), 1 ether));

        skr.pull(msg.sender, jam);
        skr.burn(jam);

        sai.push(msg.sender, wad);
    }
    function bust(uint128 wad) auth note {
        assert(reg == Stage.Usual);
        drip();
        mend();
        assert(wad <= woe());

        var jam = rdiv(wdiv(wad, tag()), per()); // Calculates 'jam' using actual 'per' (assuming there is not need to 'mint' 'skr')
        if (jam > fog()) {
            // If using actual 'per' there is not enough 'fog' to cover the operation, we need to calculate a new 'jam' taking into account the change on 'per'
            jam = wdiv(hsub(uint128(skr.totalSupply()), fog()), hsub(wdiv(wmul(tag(), pie()), wad), 1 ether));
            skr.mint(jam - fog());
        }

        skr.push(msg.sender, jam);
        sai.pull(msg.sender, wad);
        mend();
    }

    //------------------------------------------------------------------

    // force settlement of the system at a given price (ref per gem).
    // This is nearly the equivalent of biting all cups at once.
    // Important consideration: the gems associated with free skr can
    // be tapped to make sai whole.
    function cage(uint128 price) auth note {
        assert(reg == Stage.Usual);
        reg = Stage.Caged;

        price = price * (RAY / WAD);  // cast up to ray for precision

        drip();
        pot.push(sin, this);  // take on all the debt
        mend();               // absorb any pending fees
        skr.burn(fog());      // burn pending sale skr

        // save current gem per skr for collateral calc.
        // we need to know this to work out the skr value of a cups debt
        par = per();

        // most gems we can get per sai is the full balance
        fix = hmin(rdiv(RAY, price), rdiv(pie(), woe()));
        // gems needed to cover debt
        var bye = rmul(fix, woe());

        // put the gems backing sai in a safe place
        gem.transfer(pot, bye);
    }
    // exchange free sai for gems after kill
    function cash() auth note {
        assert(reg == Stage.Caged || reg == Stage.Empty);

        var hai = cast(sai.balanceOf(msg.sender));
        sai.pull(msg.sender, hai);
        mend(hai);

        pot.push(gem, msg.sender, rmul(hai, fix));
    }
    // retrieve skr from a cup
    function bail(bytes32 cup) auth note {
        assert(reg == Stage.Caged || reg == Stage.Empty);

        var pro = cups[cup].ink;
        // value of the debt in skr at settlement
        var con = rdiv(rmul(tab(cup), fix), par);

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
}
