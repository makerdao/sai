pragma solidity ^0.4.8;

import "ds-test/test.sol";

import "ds-math/math.sol";

import 'ds-token/token.sol';
import 'ds-vault/vault.sol';
import 'ds-roles/roles.sol';
import 'ds-value/value.sol';

import './tub.sol';


contract TubTest is DSTest, DSMath {
    Tub tub;
    DSToken gem;
    DSToken sai;
    DSToken sin;
    DSToken skr;
    DSVault pot;
    DSValue tag;
    DSVault tmp;

    function ray(uint128 wad) returns (uint128) {
        return wad * 1 ether;
    }

    function assertEqWad(uint128 x, uint128 y) {
        assertEq(uint256(x), uint256(y));
    }

    function mark(uint128 price) {
        tag.poke(bytes32(price));
    }

    function setUp() {
        gem = new DSToken("collateral", "COL", 18);
        gem.mint(100 ether);

        sai = new DSToken("SAI", "SAI", 18);
        sin = new DSToken("SIN", "SIN", 18);
        skr = new DSToken("SKR", "SKR", 18);
        pot = new DSVault();

        tmp = new DSVault();  // somewhere to hide tokens for testing

        tag = new DSValue();
        tub = new Tub(gem, sai, sin, skr, pot, tag);

        var dad = new DSRoles(); // TODO

        var mom = DSAuthority(tub);

        sai.setOwner(mom);
        sin.setOwner(mom);
        skr.setOwner(mom);
        pot.setOwner(mom);

        gem.approve(tub, 100000 ether);
        skr.approve(tub, 100000 ether);
        skr.approve(pot, 100000 ether);
        sai.approve(tub, 100000 ether);

        sai.approve(tmp, 100000 ether);
        skr.approve(tmp, 100000 ether);

        tag.poke(bytes32(1 ether));

        tub.cork(20 ether);
    }
    function testBasic() {
        assertEq( tub.skr().balanceOf(pot), 0 ether );
        assertEq( tub.skr().balanceOf(this), 0 ether );
        assertEq( tub.gem().balanceOf(tub), 0 ether );

        // edge case
        assertEq( uint256(tub.per()), 1 ether );
        tub.join(10 ether);
        assertEq( uint256(tub.per()), 1 ether );

        assertEq( tub.skr().balanceOf(this), 10 ether );
        assertEq( tub.gem().balanceOf(tub), 10 ether );
        // price formula
        tub.join(10 ether);
        assertEq( uint256(tub.per()), 1 ether );
        assertEq( tub.skr().balanceOf(this), 20 ether );
        assertEq( tub.gem().balanceOf(tub), 20 ether );

        var cup = tub.open();

        assertEq( tub.skr().balanceOf(this), 20 ether );
        assertEq( tub.skr().balanceOf(pot), 0 ether );
        tub.lock(cup, 10 ether); // lock skr token
        assertEq( tub.skr().balanceOf(this), 10 ether );
        assertEq( tub.skr().balanceOf(pot), 10 ether );

        assertEq( tub.sai().balanceOf(this), 0 ether);
        tub.draw(cup, 5 ether);
        assertEq( tub.sai().balanceOf(this), 5 ether);


        assertEq( tub.sai().balanceOf(this), 5 ether);
        tub.wipe(cup, 2 ether);
        assertEq( tub.sai().balanceOf(this), 3 ether);

        assertEq( tub.sai().balanceOf(this), 3 ether);
        assertEq( tub.skr().balanceOf(this), 10 ether );
        tub.shut(cup);
        assertEq( tub.sai().balanceOf(this), 0 ether);
        assertEq( tub.skr().balanceOf(this), 20 ether );
    }
    function testMold() {
        var chop = bytes4(sha3('chop(uint128)'));
        var cork = bytes4(sha3('cork(uint128)'));
        var cuff = bytes4(sha3('cuff(uint128)'));

        assert(tub.call(cork, 0 ether));
        assert(tub.call(cork, 5 ether));

        assert(!tub.call(chop, ray(2 ether)));
        assert(tub.call(cuff, ray(2 ether)));
        assert(tub.call(chop, ray(2 ether)));
        assert(!tub.call(cuff, ray(1 ether)));
    }
    function testJoinExit() {
        assertEq(skr.balanceOf(this), 0 ether);
        assertEq(gem.balanceOf(this), 100 ether);
        tub.join(10 ether);
        assertEq(skr.balanceOf(this), 10 ether);
        assertEq(gem.balanceOf(this), 90 ether);
        assertEq(gem.balanceOf(tub),  10 ether);

        tub.exit(5 ether);
        assertEq(skr.balanceOf(this),  5 ether);
        assertEq(gem.balanceOf(this), 95 ether);
        assertEq(gem.balanceOf(tub),   5 ether);

        tub.join(2 ether);
        assertEq(skr.balanceOf(this),  7 ether);
        assertEq(gem.balanceOf(this), 93 ether);
        assertEq(gem.balanceOf(tub),   7 ether);

        tub.exit(1 ether);
        assertEq(skr.balanceOf(this),  6 ether);
        assertEq(gem.balanceOf(this), 94 ether);
        assertEq(gem.balanceOf(tub),   6 ether);
    }
    function testFailOverDraw() {
        tub.cuff(ray(1 ether));
        tub.join(10 ether);
        var cup = tub.open();
        tub.lock(cup, 10 ether);

        tub.draw(cup, 11 ether);
    }
    function testFailOverDrawExcess() {
        tub.cuff(ray(1 ether));
        tub.join(20 ether);
        var cup = tub.open();
        tub.lock(cup, 10 ether);

        tub.draw(cup, 11 ether);
    }
    function testUnsafe() {
        tub.join(10 ether);
        var cup = tub.open();
        tub.lock(cup, 10 ether);
        tub.draw(cup, 9 ether);

        assert(tub.safe(cup));
        tag.poke(bytes32(1 ether / 2));
        assert(!tub.safe(cup));
    }
    function testBiteUnderParity() {
        assertEq(uint(tub.axe()), uint(ray(1 ether)));  // 100% collateralisation limit
        tub.join(10 ether);
        var cup = tub.open();
        tub.lock(cup, 10 ether);
        tub.draw(cup, 5 ether);           // 200% collateralisation
        tag.poke(bytes32(1 ether / 4));   // 50% collateralisation

        assertEq(tub.fog(), uint(0));
        tub.bite(cup);
        assertEq(tub.fog(), uint(10 ether));
    }
    function testBiteOverParity() {
        tub.cuff(ray(2 ether));  // require 200% collateralisation
        tub.join(10 ether);
        var cup = tub.open();
        tub.lock(cup, 10 ether);

        tub.draw(cup, 4 ether);  // 250% collateralisation
        assert(tub.safe(cup));
        tag.poke(bytes32(1 ether / 2));   // 125% collateralisation
        assert(!tub.safe(cup));

        assertEq(tub.fog(), uint(0));
        tub.bite(cup);
        assertEq(tub.fog(), uint(8 ether));

        // cdp should now be safe with 0 sai debt and 2 skr remaining
        var skr_before = skr.balanceOf(this);
        tub.free(cup, 1 ether);
        assertEq(skr.balanceOf(this) - skr_before, 1 ether);
    }
    function testFree() {
        tub.cuff(ray(2 ether));  // require 200% collateralisation
        tub.join(10 ether);
        var cup = tub.open();
        tub.lock(cup, 10 ether);
        tub.draw(cup, 4 ether);  // 250% collateralisation

        var skr_before = skr.balanceOf(this);
        tub.free(cup, 2 ether);  // 225%
        assertEq(skr.balanceOf(this) - skr_before, 2 ether);
    }
    function testFailFreeToUnderCollat() {
        tub.cuff(ray(2 ether));  // require 200% collateralisation
        tub.join(10 ether);
        var cup = tub.open();
        tub.lock(cup, 10 ether);
        tub.draw(cup, 4 ether);  // 250% collateralisation

        tub.free(cup, 3 ether);  // 175% -- fails
    }
    function testFailDrawOverDebtCeiling() {
        tub.cork(4 ether);
        tub.join(10 ether);
        var cup = tub.open();
        tub.lock(cup, 10 ether);

        tub.draw(cup, 5 ether);
    }
    function testDebtCeiling() {
        tub.cork(5 ether);
        tub.cuff(ray(2 ether));  // require 200% collat
        tub.join(10 ether);
        var cup = tub.open();
        tub.lock(cup, 10 ether);

        tub.draw(cup, 5 ether);          // 200% collat, full debt ceiling
        tag.poke(bytes32(1 ether / 2));  // 100% collat

        assertEq(tub.air(), uint(10 ether));
        assertEq(tub.fog(), uint(0 ether));
        tub.bite(cup);
        assertEq(tub.air(), uint(0 ether));
        assertEq(tub.fog(), uint(10 ether));

        tub.join(10 ether);
        // skr hasn't been diluted yet so still 1:1 skr:gem
        assertEq(skr.balanceOf(this), 10 ether);
    }

    // ensure cage sets the settle prices right
    function cageSetup() returns (bytes32) {
        tub.cork(5 ether);            // 5 sai debt ceiling
        tag.poke(bytes32(1 ether));   // price 1:1 gem:ref
        tub.cuff(ray(2 ether));       // require 200% collat
        tub.join(10 ether);
        var cup = tub.open();
        tub.lock(cup, 10 ether);
        tub.draw(cup, 5 ether);       // 200% collateralisation

        return cup;
    }
    function testCageSafeOverCollat() {
        cageSetup();

        assertEqWad(tub.fix(), 0);
        assertEqWad(tub.fit(), 0);
        assertEqWad(tub.woe(), 0);         // no bad debt
        assertEqWad(tub.pie(), 10 ether);

        tub.join(20 ether);   // give us some more skr
        tub.cage(1 ether);

        assertEqWad(tub.woe(), 5 ether);       // all good debt now bad debt
        assertEqWad(tub.fix(), 1 ether);       // sai redeems 1:1 with gem
        assertEqWad(tub.fit(), 1 ether);       // skr redeems 1:1 with gem

        assertEq(skr.totalSupply(),  25 ether);
        assertEq(skr.balanceOf(pot),  5 ether);  // burn skr linked with backing gems

        assertEq(gem.balanceOf(pot),  5 ether);  // saved for sai
        assertEq(gem.balanceOf(tub), 25 ether);  // saved for skr
    }
    function testCageUnsafeOverCollat() {
        cageSetup();

        assertEqWad(tub.fix(), 0);
        assertEqWad(tub.fit(), 0);

        tub.join(20 ether);   // give us some more skr
        var price = wdiv(3 ether, 4 ether);
        tub.cage(price);        // 150% collat

        assertEqWad(tub.fix(), wdiv(1 ether, price));  // sai redeems 4:3 with gem
        assertEqWad(tub.fit(), 1 ether);               // skr redeems 1:1 with gem

        // gem needed for sai is 5 * 4 / 3
        // skr linked with these gems is burned
        var burned = wmul(5 ether, wdiv(4 ether, 3 ether));
        assertEq(skr.totalSupply(),   30 ether - burned);
        assertEq(skr.balanceOf(pot),  10 ether - burned);

        // as skr:gem is 1:1, burned is also equal to the gem reserved for sai
        var saved = wmul(1 ether, burned);
        assertEq(gem.balanceOf(pot),  saved);             // saved for sai
        assertEq(gem.balanceOf(tub),  30 ether - saved);  // saved for skr
    }
    function testCageAtCollat() {
        cageSetup();

        assertEqWad(tub.fix(), 0);
        assertEqWad(tub.fit(), 0);

        var price = wdiv(1 ether, 2 ether);  // 100% collat
        tub.cage(price);

        assertEqWad(tub.fix(), 2 ether);  // sai redeems 1:2 with gem, 1:1 with ref
        assertEqWad(tub.fit(), 0 ether);  // skr redeems 1:0 with gem
    }
    function testCageAtCollatFreeSkr() {
        cageSetup();

        assertEqWad(tub.fix(), 0);
        assertEqWad(tub.fit(), 0);

        tub.join(20 ether);   // give us some more skr
        var price = wdiv(1 ether, 2 ether);  // 100% collat
        tub.cage(price);

        assertEqWad(tub.fix(), 2 ether);  // sai redeems 1:2 with gem, 1:1 with ref
        assertEqWad(tub.fit(), 1 ether);  // skr redeems 1:1 with gem
    }
    function testCageUnderCollat() {
        cageSetup();

        assertEqWad(tub.fix(), 0);
        assertEqWad(tub.fit(), 0);

        var price = wdiv(1 ether, 4 ether);   // 50% collat
        tub.cage(price);

        assertEq(2 * sai.totalSupply(), gem.balanceOf(pot));
        assertEqWad(tub.fix(), 2 ether);  // sai redeems 1:2 with gem, 2:1 with ref
        assertEqWad(tub.fit(), 0 ether);  // skr redeems 1:0 with gem
    }
    function testCageUnderCollatFreeSkr() {
        cageSetup();

        assertEqWad(tub.fix(), 0);
        assertEqWad(tub.fit(), 0);

        tub.join(20 ether);   // give us some more skr
        var price = wdiv(1 ether, 4 ether);   // 50% collat
        tub.cage(price);

        assertEq(4 * sai.totalSupply(), gem.balanceOf(pot));
        assertEqWad(tub.fix(), 4 ether);                 // sai redeems 1:4 with gem, 1:1 with ref
        assertEqWad(tub.fit(), wdiv(1 ether, 2 ether));  // skr redeems 2:1 with gem
    }

    // ensure cash returns the expected amount
    function testCashSafeOverCollat() {
        var cup = cageSetup();
        tub.cage(1 ether);

        assertEq(sai.balanceOf(this),  5 ether);
        assertEq(skr.balanceOf(this),  0 ether);
        assertEq(gem.balanceOf(this), 90 ether);
        assertEq(gem.balanceOf(tub),   5 ether);
        assertEq(gem.balanceOf(pot),   5 ether);
        tub.cash();
        assertEq(sai.balanceOf(this),   0 ether);
        assertEq(skr.balanceOf(this),   0 ether);
        assertEq(gem.balanceOf(this),  95 ether);
        assertEq(gem.balanceOf(tub),    5 ether);

        assertEq(sai.totalSupply(), 0);
        assertEq(sin.totalSupply(), 0);

        tub.bail(cup);
        tub.cash();
        assertEq(gem.balanceOf(this), 100 ether);
        assertEq(gem.balanceOf(tub),    0 ether);

        assertEq(skr.totalSupply(), 0);
    }
    function testCashSafeOverCollatWithFreeSkr() {
        var cup = cageSetup();
        tub.join(20 ether);   // give us some more skr
        tub.cage(1 ether);

        assertEq(sai.balanceOf(this),  5 ether);
        assertEq(skr.balanceOf(this), 20 ether);
        assertEq(gem.balanceOf(this), 70 ether);
        tub.cash();
        assertEq(sai.balanceOf(this),   0 ether);
        assertEq(skr.balanceOf(this),   0 ether);

        assertEq(gem.balanceOf(this),  95 ether);
        assertEq(gem.balanceOf(tub),    5 ether);

        assertEq(sai.totalSupply(), 0);
        assertEq(sin.totalSupply(), 0);

        tub.bail(cup);
        tub.cash();
        assertEq(gem.balanceOf(this), 100 ether);
        assertEq(gem.balanceOf(tub),    0 ether);

        assertEq(skr.totalSupply(), 0);
    }
    function testCashUnsafeOverCollat() {
        var cup = cageSetup();
        tub.join(20 ether);   // give us some more skr
        var price = wdiv(3 ether, 4 ether);
        tub.cage(price);        // 150% collat

        assertEq(sai.balanceOf(this),  5 ether);
        assertEq(skr.balanceOf(this), 20 ether);
        assertEq(gem.balanceOf(this), 70 ether);
        tub.cash();
        assertEq(sai.balanceOf(this),   0 ether);
        assertEq(skr.balanceOf(this),   0 ether);

        var saved = wmul(5 ether, wdiv(4 ether, 3 ether));

        assertEq(gem.balanceOf(this),  90 ether + saved);
        assertEq(gem.balanceOf(tub),   10 ether - saved);

        assertEq(sai.totalSupply(), 0);
        assertEq(sin.totalSupply(), 0);

        // how much gem should be returned?
        // there were 10 gems initially, of which 5 were 100% collat
        // at the cage price, 5 * 4 / 3 are 100% collat,
        // leaving 10 - 5 * 4 / 3 as excess = 3.333
        // this should all be returned
        tub.bail(cup);
        tub.cash();
        assertEq(gem.balanceOf(this), 100 ether);
        assertEq(gem.balanceOf(tub),    0 ether);

        assertEq(skr.totalSupply(), 0);
    }
    function testCashAtCollat() {
        var cup = cageSetup();
        var price = wdiv(1 ether, 2 ether);  // 100% collat
        tub.cage(price);

        assertEq(sai.balanceOf(this),  5 ether);
        assertEq(skr.balanceOf(this),  0 ether);
        assertEq(gem.balanceOf(this), 90 ether);
        tub.cash();
        assertEq(sai.balanceOf(this),   0 ether);
        assertEq(skr.balanceOf(this),   0 ether);

        var saved = wdiv(5 ether, price);

        assertEq(gem.balanceOf(this),  90 ether + saved);
        assertEq(gem.balanceOf(tub),   10 ether - saved);

        assertEq(sai.totalSupply(), 0);
        assertEq(sin.totalSupply(), 0);

        // how much gem should be returned?
        // none :D
        assertEq(gem.balanceOf(this), 100 ether);
        assertEq(gem.balanceOf(tub),    0 ether);
        tub.bail(cup);
        tub.cash();
        assertEq(gem.balanceOf(this), 100 ether);
        assertEq(gem.balanceOf(tub),    0 ether);

        assertEq(skr.totalSupply(), 0);
    }
    function testCashAtCollatFreeSkr() {
        var cup = cageSetup();
        tub.join(20 ether);   // give us some more skr
        var price = wdiv(1 ether, 2 ether);  // 100% collat
        tub.cage(price);

        assertEq(sai.balanceOf(this),  5 ether);
        assertEq(skr.balanceOf(this), 20 ether);
        assertEq(gem.balanceOf(this), 70 ether);
        tub.cash();
        assertEq(sai.balanceOf(this),   0 ether);
        assertEq(skr.balanceOf(this),   0 ether);

        var saved = wdiv(5 ether, price);

        assertEq(gem.balanceOf(this),  90 ether + saved);
        assertEq(gem.balanceOf(tub),   10 ether - saved);

        assertEq(sai.totalSupply(), 0);
        assertEq(sin.totalSupply(), 0);

        // how much gem should be returned?
        // none :D
        assertEq(gem.balanceOf(this), 100 ether);
        assertEq(gem.balanceOf(tub),    0 ether);
        tub.bail(cup);
        tub.cash();
        assertEq(gem.balanceOf(this), 100 ether);
        assertEq(gem.balanceOf(tub),    0 ether);

        assertEq(skr.totalSupply(), 0);
    }
    function testCashUnderCollat() {
        var cup = cageSetup();
        var price = wdiv(1 ether, 4 ether);   // 50% collat
        tub.cage(price);

        assertEq(sai.balanceOf(this),  5 ether);
        assertEq(skr.balanceOf(this),  0 ether);
        assertEq(gem.balanceOf(this), 90 ether);
        tub.cash();
        assertEq(sai.balanceOf(this),   0 ether);
        assertEq(skr.balanceOf(this),   0 ether);

        // get back all 10 gems, which are now only worth 2.5 ref
        // so you've lost 50% on you sai
        assertEq(gem.balanceOf(this), 100 ether);
        assertEq(gem.balanceOf(tub),    0 ether);

        assertEq(sai.totalSupply(), 0);
        assertEq(sin.totalSupply(), 0);

        // how much gem should be returned?
        // none :D
        assertEq(gem.balanceOf(this), 100 ether);
        assertEq(gem.balanceOf(tub),    0 ether);
        tub.bail(cup);
        tub.cash();
        assertEq(gem.balanceOf(this), 100 ether);
        assertEq(gem.balanceOf(tub),    0 ether);

        assertEq(skr.totalSupply(), 0);
    }
    function testCashUnderCollatFreeSkr() {
        var cup = cageSetup();
        tub.join(20 ether);   // give us some more skr
        var price = wdiv(1 ether, 4 ether);   // 50% collat
        tub.cage(price);

        tmp.pull(skr, this);  // stash skr

        assertEq(sai.balanceOf(this),  5 ether);
        assertEq(gem.balanceOf(this), 70 ether);
        tub.cash();
        assertEq(sai.balanceOf(this),  0 ether);
        // returns 20 gems, taken from the free skr,
        // sai is made whole
        assertEq(gem.balanceOf(this), 90 ether);

        tmp.push(skr, this);  // unstash skr
        assertEq(skr.balanceOf(this),  20 ether);
        tub.cash();
        assertEq(skr.balanceOf(this),   0 ether);
        // the skr has taken a 50% loss - 10 gems returned from 20 put in
        assertEq(gem.balanceOf(this), 100 ether);

        assertEq(gem.balanceOf(tub),    0 ether);

        assertEq(sai.totalSupply(), 0);
        assertEq(sin.totalSupply(), 0);

        // how much gem should be returned?
        // none :D
        assertEq(gem.balanceOf(this), 100 ether);
        assertEq(gem.balanceOf(tub),    0 ether);
        tub.bail(cup);
        assertEq(gem.balanceOf(this), 100 ether);
        assertEq(gem.balanceOf(tub),    0 ether);

        assertEq(skr.totalSupply(), 0);
    }

    function liq(bytes32 cup) returns (uint128) {
        // compute the liquidation price of a cup
        var jam = wdiv(tub.ink(cup), tub.per());
        var min = rmul(tub.tab(cup), tub.mat());
        return wdiv(min, jam);
    }
    function testLiq() {
        tub.cork(100 ether);
        mark(2 ether);

        tub.join(10 ether);
        var cup = tub.open();
        tub.lock(cup, 10 ether);
        tub.draw(cup, 10 ether);        // 200% collateralisation

        tub.cuff(ray(1 ether));         // require 100% collateralisation
        assertEqWad(liq(cup), 1 ether);

        tub.cuff(ray(3 ether / 2));     // require 150% collateralisation
        assertEqWad(liq(cup), wdiv(3 ether, 2 ether));

        mark(6 ether);
        assertEqWad(liq(cup), wdiv(3 ether, 2 ether));

        tub.draw(cup, 30 ether);
        assertEqWad(liq(cup), 6 ether);

        tub.join(10 ether);
        assertEqWad(liq(cup), 6 ether);

        tub.lock(cup, 10 ether);  // now 40 drawn on 20 gem == 120 ref
        assertEqWad(liq(cup), 3 ether);
    }
    function collat(bytes32 cup) returns (uint128) {
        // compute the collateralised fraction of a cup
        var jam = wdiv(tub.ink(cup), tub.per());
        var pro = wmul(jam, tub.tag());
        var con = tub.tab(cup);
        return wdiv(pro, con);
    }
    function testCollat() {
        tub.cork(100 ether);
        mark(2 ether);

        tub.join(10 ether);
        var cup = tub.open();
        tub.lock(cup, 10 ether);
        tub.draw(cup, 10 ether);

        assertEqWad(collat(cup), 2 ether);  // 200%

        mark(4 ether);
        assertEqWad(collat(cup), 4 ether);  // 400%

        tub.draw(cup, 15 ether);
        assertEqWad(collat(cup), wdiv(8 ether, 5 ether));  // 160%

        mark(5 ether);
        tub.free(cup, 5 ether);
        assertEqWad(collat(cup), 1 ether);  // 100%

        mark(4 ether);
        assertEqWad(collat(cup), wdiv(4 ether, 5 ether));  // 80%

        tub.wipe(cup, 9 ether);
        assertEqWad(collat(cup), wdiv(5 ether, 4 ether));  // 125%
    }

    function testBust() {
        tub.cork(100 ether);
        tub.cuff(ray(wdiv(3 ether, 2 ether)));  // 150% liq limit
        mark(2 ether);

        tub.join(10 ether);
        var cup = tub.open();
        tub.lock(cup, 10 ether);

        mark(3 ether);
        tub.draw(cup, 16 ether);  // 125% collat
        mark(2 ether);

        assert(!tub.safe(cup));
        tub.bite(cup);
        // 20 ref of gem on 16 ref of sai
        // 125%
        // 100% = 16ref of gem == 8 gem
        assertEqWad(tub.fog(), 8 ether);

        // 8 skr for sale
        assertEqWad(tub.per(), 1 ether);

        // get 2 skr, pay 4 sai (25% of the debt)
        var sai_before = sai.balanceOf(this);
        var skr_before = skr.balanceOf(this);
        assertEq(sai_before, 16 ether);
        tub.bust(2 ether);
        var sai_after = sai.balanceOf(this);
        var skr_after = skr.balanceOf(this);
        assertEq(sai_before - sai_after, 4 ether);
        assertEq(skr_after - skr_before, 2 ether);

        // price drop. now remaining 6 skr cannot cover bad debt (12 sai)
        mark(1 ether);

        // get 6 skr, pay 6 sai
        tub.bust(6 ether);
        // no more skr remaining to sell
        assertEqWad(tub.fog(), 0);
        // but skr supply unchanged
        assertEq(skr.totalSupply(), 10 ether);

        // now skr will be minted
        tub.bust(2 ether);
        assertEq(skr.totalSupply(), 12 ether);
    }

    function testCascade() {
        // demonstrate liquidation cascade
        tub.cork(1000 ether);
        tub.cuff(ray(2 ether));                 // 200% liq limit
        tub.chop(ray(wdiv(5 ether, 4 ether)));  // 125% penalty
        mark(10 ether);

        tub.join(40 ether);
        var cup = tub.open();
        var mug = tub.open();
        var jar = tub.open();

        tub.lock(cup, 10 ether);
        tub.lock(mug, 10 ether);
        tub.lock(jar, 10 ether);

        tub.draw(cup, 50 ether);  // 200% collat
        tub.draw(mug, 40 ether);  // 250% collat
        tub.draw(jar, 19 ether);  // 421% collat

        mark(4 ether);  // cup 80%, mug 100%, jar 200%
        tub.bite(cup);

        // inflation happens when the confiscated skr can no longer
        // cover the debt. With axe == 1, this happens as soon as the
        // price falls. With axe == 1.25, the price has to fall by 20%.
        // Beyond this price fall, there is inflation.
        // This is an extra justification for axe (beyond penalising bad
        // cup holders).
        assertEqWad(tub.fog(), 10 ether);
        assertEqWad(tub.woe(), 50 ether);
        tub.bust(tub.fog());
        assertEqWad(tub.fog(), 0 ether);
        assertEqWad(tub.woe(), 10 ether);
        // price still 1
        assertEqWad(tub.per(), 1 ether);

        // now force some minting, which flips the jar to unsafe
        assert(tub.safe(jar));
        tub.bust(wdiv(5 ether, 2 ether));
        assert(!tub.safe(jar));

        assertEqWad(tub.woe(), 0);
        assertEqWad(tub.per(), wdiv(85 ether, 80 ether));  // 6.25% more skr/gem

        // mug is now under parity as well
        tub.bite(mug);
        tub.bust(tub.fog());
        tub.bust(wmul(tub.woe(), wdiv(tub.per(), tub.tag())));

        tub.bite(jar);

        // N.B from the initial price markdown the whole system was in deficit
    }
}
