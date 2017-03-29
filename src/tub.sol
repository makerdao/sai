/// tub.sol -- simplified CDP engine (baby brother of `vat')

// Copyright (C) 2017  Nikolai Mushegian <nikolai@dapphub.com>
// Copyright (C) 2017  Daniel Brockman <daniel@dapphub.com>

pragma solidity ^0.4.8;

import "./lib.sol";

// ref/gem is only external data  (e.g. USD/ETH)
// skr/gem is ratio of supply (outstanding skr to total locked gem)
// sai/ref decays ("holder fee")

// surplus also market makes for gem

// refprice(skr) := ethers per claim * tag
// risky := refprice(skr):refprice(debt) too high

contract Tub is MakerMath, DSNote, DSAuth {
    DSToken  public  sai;  // Stablecoin
    DSToken  public  sin;  // Debt (negative sai)
    DSToken  public  skr;  // Abstracted collateral
    ERC20    public  gem;  // Underlying collateral

    uint128  public  tag;  // Gem price (in external reference unit)
    // TODO          zzz;  // Gem price expiration

    uint128  public  axe;  // Liquidation penalty
    uint128  public  hat;  // Debt ceiling
    uint128  public  mat;  // Liquidation ratio

    uint128  public  joy;  // Unprocessed fees
    uint128  public  woe;  // Bad debt
    
    bool     public  off;  // Killswitch

    // uint64   public  lax;  // Grace period? --> No, only expiring feeds and killswitch

    uint256                   public  cupi;
    mapping (bytes32 => Cup)  public  cups;

    struct Cup {
        address  lad;      // CDP owner
        
        uint128  art;      // Outstanding debt (in debt unit)
        uint128  ink;      // Locked collateral (in skr)
    }

    function Tub(ERC20 gem_) {
        gem = gem_;

        sai = new DSToken("SAI", "SAI", 18);
        sin = new DSToken("SIN", "SIN", 18);
        skr = new DSToken("SKR", "SKR", 18);

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

    // TODO: joy updates on drip ("collect fees")
    function drip() note {
    }

    function per() constant returns (uint128) {
        // this avoids 0 edge case / rounding errors TODO delete me
        // TODO delegate edge case via fee built into conversion formula
        return skr.totalSupply() < 1 ether
            ? 1 ether
            : wdiv(uint128(gem.balanceOf(this)), uint128(skr.totalSupply()));
    }

    function join(uint128 jam) note {
        gem.transferFrom(msg.sender, this, jam);
        var ink = wmul(jam, per());
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

    function lock(bytes32 cup, uint128 wad) {
        aver(msg.sender == cups[cup].lad);
        // TODO
        cups[cup].ink = incr(cups[cup].ink, wad);
        skr.pull(msg.sender, wad);
    }
    function free(bytes32 cup, uint128 wad) {
        aver(msg.sender == cups[cup].lad);
        // TODO
        cups[cup].ink = decr(cups[cup].ink, wad);
        skr.push(msg.sender, wad);
    }

    // TODO: art/sin decays ("issuer fee")
    function draw(bytes32 cup, uint128 wad) {
        aver(msg.sender == cups[cup].lad);
        cups[cup].art = incr(cups[cup].art, wad);
        lend(wad);
        sai.push(msg.sender, wad);
    }
    function wipe(bytes32 cup, uint128 wad) {
        aver(msg.sender == cups[cup].lad);
        cups[cup].art = decr(cups[cup].art, wad);
        sai.pull(msg.sender, wad);
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

    // TODO: woe updates on bite ("take on bad debt")
    function bite(bytes32 cup) {
        var tab = rmul(cups[cup].art, axe);

        cups[cup].art = 0;
        cups[cup].ink = 0; // TODO: leftover collateral
    }

    // constant skr/sai mint/sell/buy/burn to process joy/woe
    // auto MM
    function boom(uint128 wad) {
        // TODO
    }
    function bust(uint128 wad) {
        // TODO
    }

    // TODO: could be here or on oracle object using same prism
    // function vote() {}
}
