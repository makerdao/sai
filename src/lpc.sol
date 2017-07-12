/// lpc.sol -- really dumb liquidity pool

pragma solidity ^0.4.11;

import "ds-thing/thing.sol";
import "ds-token/token.sol";
import "ds-value/value.sol";
import "./tip.sol";


contract SaiLPC is DSThing {
    // This is a simple two token liquidity pool that uses an external
    // price feed.

    // Makers
    // - `pool` their gems and receive LPS tokens, which are a claim
    //    on the pool.
    // - `exit` and trade their LPS tokens for a share of the gems in
    //    the pool

    // Takers
    // - `take` and exchange one gem for another, whilst paying a
    //   fee (the `gap`). The collected fee goes into the pool.

    // To avoid `pool`, `exit` being used to circumvent the taker fee,
    // makers must pay the same fee on `exit`.

    // provide liquidity for this gem pair
    ERC20    public  ref;
    ERC20    public  alt;

    DSValue  public  pip;  // price feed, giving refs per alt
    uint128  public  gap;  // spread, charged on `take`
    DSToken  public  lps;  // 'liquidity provider shares', earns spread
    Tip      public  tip;

    function SaiLPC(ERC20 ref_, ERC20 alt_, DSValue pip_, DSToken lps_, Tip tip_) {
        ref = ref_;
        alt = alt_;
        pip = pip_;

        lps = lps_;
        tip = tip_;
        gap = WAD;
    }

    function jump(uint128 wad) auth note {
        assert(wad != 0);
        gap = wad;
    }

    // ref per alt
    function tag() constant returns (uint128) {
        return uint128(pip.read());
    }

    // total pool value
    function pie() constant returns (uint128) {
        return wadd(uint128(ref.balanceOf(this)),
                    wdiv(wmul(uint128(alt.balanceOf(this)), tag()), tip.par()));
    }

    // lps per ref
    function per() constant returns (uint128) {
        return lps.totalSupply() == 0
             ? RAY
             : rdiv(uint128(lps.totalSupply()), pie());
    }

    // {ref,alt} -> lps
    function pool(ERC20 gem, uint128 wad) auth note {
        require(gem == alt || gem == ref);

        var jam = (gem == ref) ? wad : wdiv(wmul(wad, tag()), tip.par());
        var ink = rmul(jam, per());
        lps.mint(ink);
        lps.push(msg.sender, ink);

        gem.transferFrom(msg.sender, this, wad);
    }

    // lps -> {ref,alt}
    function exit(ERC20 gem, uint128 wad) auth note {
        require(gem == alt || gem == ref);

        var jam = (gem == ref) ? wad : wdiv(wmul(wad, tag()), tip.par());
        var ink = rmul(jam, per());
        // pay fee to exit, unless you're the last out
        ink = (jam == pie())? ink : wmul(gap, ink);
        lps.pull(msg.sender, ink);
        lps.burn(ink);

        gem.transfer(msg.sender, wad);
    }

    // ref <-> alt
    // TODO: meme 'swap'?
    // TODO: mem 'yen' means to desire. pair with 'pay'? or 'ney'
    function take(ERC20 gem, uint128 wad) auth note {
        require(gem == alt || gem == ref);

        var jam = (gem == ref) ? wmul(wdiv(wad, tag()), tip.par()) : wdiv(wmul(wad, tag()), tip.par());
        jam = wmul(gap, jam);

        var pay = (gem == ref) ? alt : ref;
        pay.transferFrom(msg.sender, this, jam);
        gem.transfer(msg.sender, wad);
    }
}
