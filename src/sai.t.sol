pragma solidity ^0.4.8;

import "ds-test/test.sol";

import "ds-math/math.sol";

import 'ds-token/token.sol';
import 'ds-vault/vault.sol';
import 'ds-guard/guard.sol';
import 'ds-roles/roles.sol';
import 'ds-value/value.sol';

import './tub.sol';
import './top.sol';
import './tap.sol';

contract FakePerson {
    Top     public top;
    DSToken public sai;

    function FakePerson(Top _top) {
        top = _top;
        sai = top.sai();
    }

    function cash() {
        sai.approve(top.pit(), sai.balanceOf(this));
        top.cash();
    }
}

contract SaiTestBase is DSTest, DSMath {
    Tip      tip;
    Tub      tub;
    Top      top;
    Tap      tap;

    DSToken  gem;
    DSToken  sai;
    DSToken  sin;
    DSToken  skr;

    SaiJug   jug;

    DSVault  pot;
    DSVault  pit;
    SaiJar   jar;
    DSVault  tmp;

    DSValue  tag;
    DSRoles  mom;
    DSGuard  dad;

    function ray(uint128 wad) returns (uint128) {
        return wad * 10 ** 9;
    }

    function assertEqWad(uint128 x, uint128 y) {
        assertEq(uint256(x), uint256(y));
    }

    function mark(uint128 price) {
        tag.poke(bytes32(price));
    }

    function configureAuth() {
        // user facing, use ds-roles
        tip.setAuthority(mom);
        tub.setAuthority(mom);
        tap.setAuthority(mom);
        top.setAuthority(mom);
        jar.setAuthority(mom);

        // internal, use ds-guard
        pot.setAuthority(dad);
        pit.setAuthority(dad);
        jug.setAuthority(dad);

        sai.setAuthority(dad);
        sin.setAuthority(dad);
        skr.setAuthority(dad);


        mom.setUserRole(tub, 255, true);
        mom.setRoleCapability(255, jar, bytes4(sha3("join(address,uint128)")), true);
        mom.setRoleCapability(255, jar, bytes4(sha3("exit(address,uint128)")), true);
        mom.setRoleCapability(255, jar, bytes4(sha3("push(address,address,uint128)")), true);
        mom.setRoleCapability(255, jar, bytes4(sha3("pull(address,address,uint128)")), true);

        mom.setUserRole(top, 254, true);
        mom.setRoleCapability(254, jar, bytes4(sha3("push(address,address,uint128)")), true);
        mom.setRoleCapability(254, tub, bytes4(sha3("cage(uint128)")), true);


        dad.permit(tub, jug, bytes4(sha3('lend(address,uint128)')));
        dad.permit(tub, jug, bytes4(sha3('mend(address,uint128)')));
        dad.permit(tub, pot, bytes4(sha3('push(address,address,uint128)')));
        dad.permit(tub, pot, bytes4(sha3('pull(address,address,uint128)')));

        dad.permit(tap, jug, bytes4(sha3('heal(address)')));
        dad.permit(tap, pit, bytes4(sha3('mint(address,uint128)')));
        dad.permit(tap, pit, bytes4(sha3('burn(address,uint128)')));
        dad.permit(tap, pit, bytes4(sha3('push(address,address,uint128)')));
        dad.permit(tap, pit, bytes4(sha3('pull(address,address,uint128)')));

        dad.permit(top, jug, bytes4(sha3('heal(address)')));
        dad.permit(top, pit, bytes4(sha3('burn(address)')));
        dad.permit(top, pit, bytes4(sha3('push(address,address,uint128)')));
        dad.permit(top, pit, bytes4(sha3('pull(address,address,uint128)')));

        dad.permit(jar, skr, bytes4(sha3('mint(uint128)')));
        dad.permit(jar, skr, bytes4(sha3('burn(uint128)')));

        dad.permit(jug, pot, bytes4(sha3('mint(address,uint128)')));
        dad.permit(jug, pot, bytes4(sha3('burn(address,uint128)')));
        dad.permit(jug, pit, bytes4(sha3('burn(address,uint128)')));

        dad.permit(pot, sai, bytes4(sha3('mint(uint128)')));
        dad.permit(pot, sai, bytes4(sha3('burn(uint128)')));
        dad.permit(pot, sin, bytes4(sha3('mint(uint128)')));
        dad.permit(pot, sin, bytes4(sha3('burn(uint128)')));

        dad.permit(pit, sai, bytes4(sha3('burn(uint128)')));
        dad.permit(pit, sin, bytes4(sha3('burn(uint128)')));
        dad.permit(pit, skr, bytes4(sha3('mint(uint128)')));
        dad.permit(pit, skr, bytes4(sha3('burn(uint128)')));

        // convenience in tests
        dad.permit(this, sai, bytes4(sha3('mint(uint128)')));
        dad.permit(this, sai, bytes4(sha3('burn(uint128)')));
        dad.permit(this, sin, bytes4(sha3('mint(uint128)')));
        dad.permit(this, sin, bytes4(sha3('burn(uint128)')));
        dad.permit(this, skr, bytes4(sha3('mint(uint128)')));
        dad.permit(this, skr, bytes4(sha3('burn(uint128)')));

        tip.setOwner(0);
        tub.setOwner(0);
        tap.setOwner(0);
        top.setOwner(0);

        pot.setOwner(0);
        pit.setOwner(0);
        jar.setOwner(0);
        jug.setOwner(0);

        sai.setOwner(0);
        sin.setOwner(0);
        skr.setOwner(0);
    }
    function setUserRoles() {
        mom.setRoleCapability(1, tub, bytes4(sha3("join(uint128)")), true);
        mom.setRoleCapability(1, tub, bytes4(sha3("exit(uint128)")), true);
        mom.setRoleCapability(1, tub, bytes4(sha3("open()")), true);
        mom.setRoleCapability(1, tub, bytes4(sha3("shut(bytes32)")), true);
        mom.setRoleCapability(1, tub, bytes4(sha3("lock(bytes32,uint128)")), true);
        mom.setRoleCapability(1, tub, bytes4(sha3("free(bytes32,uint128)")), true);
        mom.setRoleCapability(1, tub, bytes4(sha3("draw(bytes32,uint128)")), true);
        mom.setRoleCapability(1, tub, bytes4(sha3("wipe(bytes32,uint128)")), true);
        mom.setRoleCapability(1, tub, bytes4(sha3("give(bytes32,address)")), true);
        mom.setRoleCapability(1, tub, bytes4(sha3("bite(bytes32)")), true);
        mom.setRoleCapability(1, tap, bytes4(sha3("boom(uint128)")), true);
        mom.setRoleCapability(1, tap, bytes4(sha3("bust(uint128)")), true);
        mom.setRoleCapability(1, top, bytes4(sha3("cash()")), true);
    }
    function setPublicRoles() {
        mom.setPublicCapability(tub, bytes4(sha3("join(uint128)")), true);
        mom.setPublicCapability(tub, bytes4(sha3("exit(uint128)")), true);
        mom.setPublicCapability(tub, bytes4(sha3("open()")), true);
        mom.setPublicCapability(tub, bytes4(sha3("shut(bytes32)")), true);
        mom.setPublicCapability(tub, bytes4(sha3("lock(bytes32,uint128)")), true);
        mom.setPublicCapability(tub, bytes4(sha3("free(bytes32,uint128)")), true);
        mom.setPublicCapability(tub, bytes4(sha3("draw(bytes32,uint128)")), true);
        mom.setPublicCapability(tub, bytes4(sha3("wipe(bytes32,uint128)")), true);
        mom.setPublicCapability(tub, bytes4(sha3("give(bytes32,address)")), true);
        mom.setPublicCapability(tub, bytes4(sha3("bite(bytes32)")), true);
        mom.setPublicCapability(tap, bytes4(sha3("boom(uint128)")), true);
        mom.setPublicCapability(tap, bytes4(sha3("bust(uint128)")), true);
        mom.setPublicCapability(top, bytes4(sha3("cash()")), true);
    }
    function setAdminRoles() {
        mom.setRoleCapability(2, tub, bytes4(sha3("chop(uint128)")), true);
        mom.setRoleCapability(2, tub, bytes4(sha3("cork(uint128)")), true);
        mom.setRoleCapability(2, tub, bytes4(sha3("cuff(uint128)")), true);
        mom.setRoleCapability(2, tub, bytes4(sha3("crop(uint128)")), true);
        mom.setRoleCapability(2, tip, bytes4(sha3("coax(uint128)")), true);

        mom.setRoleCapability(2, tub, bytes4(sha3("setCooldown(uint64)")), true);

        mom.setRoleCapability(2, tap, bytes4(sha3("jump(uint128)")), true);
        mom.setRoleCapability(2, jar, bytes4(sha3("jump(uint128)")), true);

        mom.setRoleCapability(2, top, bytes4(sha3("cage(uint128)")), true);
        mom.setRoleCapability(2, top, bytes4(sha3("cage()")), true);
    }

    function setUp() {
        gem = new DSToken("GEM");
        gem.mint(100 ether);

        sai = new DSToken("SAI");
        sin = new DSToken("SIN");
        jug = new SaiJug (sai, sin);

        skr = new DSToken("SKR");
        pot = new DSVault();
        pit = new DSVault();

        tmp = new DSVault();  // somewhere to hide tokens for testing

        tag = new DSValue();
        tip = new Tip();

        jar = new SaiJar(skr, gem, tag);

        tub = new Tub(jar, jug, pot, pit, tip);

        tap = new Tap(tub, pit);
        top = new Top(tub, tap);

        dad = new DSGuard();
        mom = new DSRoles();

        configureAuth();
        setUserRoles();
        setAdminRoles();

        mom.setUserRole(this, 1, true);  // user
        mom.setUserRole(this, 2, true);  // admin

        gem.approve(jar, 100000 ether);
        skr.approve(jar, 100000 ether);
        sai.approve(top, 100000 ether);

        sai.approve(pot, 100000 ether);
        skr.approve(jar, 100000 ether);

        sai.approve(pit, 100000 ether);
        skr.approve(pit, 100000 ether);

        sai.approve(tmp, 100000 ether);
        skr.approve(tmp, 100000 ether);

        tag.poke(bytes32(1 ether));

        tub.cork(20 ether);
    }
}

contract TubTest is SaiTestBase {
    function testBasic() {
        assertEq( skr.balanceOf(jar), 0 ether );
        assertEq( skr.balanceOf(this), 0 ether );
        assertEq( gem.balanceOf(jar), 0 ether );

        // edge case
        assertEq( uint256(tub.jar().per()), ray(1 ether) );
        tub.join(10 ether);
        assertEq( uint256(tub.jar().per()), ray(1 ether) );

        assertEq( skr.balanceOf(this), 10 ether );
        assertEq( gem.balanceOf(jar), 10 ether );
        // price formula
        tub.join(10 ether);
        assertEq( uint256(tub.jar().per()), ray(1 ether) );
        assertEq( skr.balanceOf(this), 20 ether );
        assertEq( gem.balanceOf(jar), 20 ether );

        var cup = tub.open();

        assertEq( skr.balanceOf(this), 20 ether );
        assertEq( skr.balanceOf(jar), 0 ether );
        tub.lock(cup, 10 ether); // lock skr token
        assertEq( skr.balanceOf(this), 10 ether );
        assertEq( skr.balanceOf(jar), 10 ether );

        assertEq( sai.balanceOf(this), 0 ether);
        tub.draw(cup, 5 ether);
        assertEq( sai.balanceOf(this), 5 ether);


        assertEq( sai.balanceOf(this), 5 ether);
        tub.wipe(cup, 2 ether);
        assertEq( sai.balanceOf(this), 3 ether);

        assertEq( sai.balanceOf(this), 3 ether);
        assertEq( skr.balanceOf(this), 10 ether );
        tub.shut(cup);
        assertEq( sai.balanceOf(this), 0 ether);
        assertEq( skr.balanceOf(this), 20 ether );
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
        assertEq(gem.balanceOf(jar),  10 ether);

        tub.exit(5 ether);
        assertEq(skr.balanceOf(this),  5 ether);
        assertEq(gem.balanceOf(this), 95 ether);
        assertEq(gem.balanceOf(jar),   5 ether);

        tub.join(2 ether);
        assertEq(skr.balanceOf(this),  7 ether);
        assertEq(gem.balanceOf(this), 93 ether);
        assertEq(gem.balanceOf(jar),   7 ether);

        tub.exit(1 ether);
        assertEq(skr.balanceOf(this),  6 ether);
        assertEq(gem.balanceOf(this), 94 ether);
        assertEq(gem.balanceOf(jar),   6 ether);
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

        assertEq(tap.fog(), uint(0));
        tub.bite(cup);
        assertEq(tap.fog(), uint(10 ether));
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

        assertEq(tap.fog(), uint(0));
        tub.bite(cup);
        assertEq(tap.fog(), uint(8 ether));

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
        assertEq(tap.fog(), uint(0 ether));
        tub.bite(cup);
        assertEq(tub.air(), uint(0 ether));
        assertEq(tap.fog(), uint(10 ether));

        tub.join(10 ether);
        // skr hasn't been diluted yet so still 1:1 skr:gem
        assertEq(skr.balanceOf(this), 10 ether);
    }
}

contract CageTest is SaiTestBase {
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

        assertEqWad(top.fix(), 0);
        assertEqWad(tub.fit(), 0);
        assertEqWad(tap.woe(), 0);         // no bad debt
        assertEqWad(tub.pie(), 10 ether);

        tub.join(20 ether);   // give us some more skr
        mark(1 ether);
        top.cage();

        var woe = cast(sin.balanceOf(pot));
        assertEqWad(woe, 5 ether);       // all good debt now bad debt
        assertEqWad(top.fix(), ray(1 ether));       // sai redeems 1:1 with gem
        assertEqWad(tub.fit(), 1 ether);       // skr redeems 1:1 with gem just before pushing gem to pot

        assertEq(gem.balanceOf(pit),  5 ether);  // saved for sai
        assertEq(gem.balanceOf(jar), 25 ether);  // saved for skr
    }
    function testCageUnsafeOverCollat() {
        cageSetup();

        assertEqWad(top.fix(), 0);
        assertEqWad(tub.fit(), 0);
        assertEqWad(tub.jar().per(), ray(1 ether));

        tub.join(20 ether);   // give us some more skr
        var price = wdiv(3 ether, 4 ether);
        mark(price);
        top.cage();        // 150% collat

        assertEqWad(top.fix(), rdiv(1 ether, price));  // sai redeems 4:3 with gem
        assertEqWad(tub.fit(), price);                 // skr redeems 1:1 with gem just before pushing gem to pot

        // gem needed for sai is 5 * 4 / 3
        var saved = rmul(5 ether, rdiv(WAD, price));
        assertEq(gem.balanceOf(pit),  saved);             // saved for sai
        assertEq(gem.balanceOf(jar),  30 ether - saved);  // saved for skr
    }
    function testCageAtCollat() {
        cageSetup();

        assertEqWad(top.fix(), 0);
        assertEqWad(tub.fit(), 0);
        assertEqWad(tub.jar().per(), ray(1 ether));

        var price = wdiv(1 ether, 2 ether);  // 100% collat
        mark(price);
        top.cage();

        assertEqWad(top.fix(), ray(2 ether));  // sai redeems 1:2 with gem, 1:1 with ref
        assertEqWad(tub.jar().per(), 0);       // skr redeems 1:0 with gem after cage
    }
    function testCageAtCollatFreeSkr() {
        cageSetup();

        assertEqWad(top.fix(), 0);
        assertEqWad(tub.fit(), 0);
        assertEqWad(tub.jar().per(), ray(1 ether));

        tub.join(20 ether);   // give us some more skr
        var price = wdiv(1 ether, 2 ether);  // 100% collat
        mark(price);
        top.cage();

        assertEqWad(top.fix(), ray(2 ether));  // sai redeems 1:2 with gem, 1:1 with ref
        assertEqWad(tub.fit(), price);       // skr redeems 1:1 with gem just before pushing gem to pot
    }
    function testCageUnderCollat() {
        cageSetup();

        assertEqWad(top.fix(), 0);
        assertEqWad(tub.fit(), 0);
        assertEqWad(tub.jar().per(), ray(1 ether));

        var price = wdiv(1 ether, 4 ether);   // 50% collat
        mark(price);
        top.cage();

        assertEq(2 * sai.totalSupply(), gem.balanceOf(pit));
        assertEqWad(top.fix(), ray(2 ether));  // sai redeems 1:2 with gem, 2:1 with ref
        assertEqWad(tub.jar().per(), 0);       // skr redeems 1:0 with gem after cage
    }
    function testCageUnderCollatFreeSkr() {
        cageSetup();

        assertEqWad(top.fix(), 0);
        assertEqWad(tub.fit(), 0);
        assertEqWad(tub.jar().per(), ray(1 ether));

        tub.join(20 ether);   // give us some more skr
        var price = wdiv(1 ether, 4 ether);   // 50% collat
        mark(price);
        top.cage();

        assertEq(4 * sai.totalSupply(), gem.balanceOf(pit));
        assertEqWad(top.fix(), ray(4 ether));                 // sai redeems 1:4 with gem, 1:1 with ref
    }

    // ensure cash returns the expected amount
    function testCashSafeOverCollat() {
        var cup = cageSetup();
        mark(1 ether);
        top.cage();

        assertEq(sai.balanceOf(this),  5 ether);
        assertEq(skr.balanceOf(this),  0 ether);
        assertEq(gem.balanceOf(this), 90 ether);
        assertEq(gem.balanceOf(jar),   5 ether);
        assertEq(gem.balanceOf(pit),   5 ether);

        top.cash();
        assertEq(sai.balanceOf(this),   0 ether);
        assertEq(skr.balanceOf(this),   0 ether);
        assertEq(gem.balanceOf(this),  95 ether);
        assertEq(gem.balanceOf(jar),    5 ether);

        assertEqWad(tub.ink(cup), 10 ether);
        tub.bite(cup);
        assertEqWad(tub.ink(cup), 5 ether);
        tub.free(cup, tub.ink(cup));
        assertEq(skr.balanceOf(this),   5 ether);
        top.vent();
        tub.exit(uint128(skr.balanceOf(this)));
        assertEq(gem.balanceOf(this), 100 ether);
        assertEq(gem.balanceOf(jar),    0 ether);

        assertEq(skr.totalSupply(), 0);
    }
    function testCashSafeOverCollatWithFreeSkr() {
        var cup = cageSetup();
        tub.join(20 ether);   // give us some more skr
        mark(1 ether);
        top.cage();

        assertEq(sai.balanceOf(this),  5 ether);
        assertEq(skr.balanceOf(this), 20 ether);
        assertEq(gem.balanceOf(this), 70 ether);
        assertEq(gem.balanceOf(jar),  25 ether);
        assertEq(gem.balanceOf(pit),   5 ether);

        tub.bite(cup);
        tub.free(cup, tub.ink(cup));
        top.vent();
        assertEq(skr.balanceOf(this), 25 ether);
        top.cash();
        tub.exit(uint128(skr.balanceOf(this)));
        assertEq(gem.balanceOf(this), 100 ether);
        assertEq(sai.balanceOf(this),   0 ether);
        assertEq(gem.balanceOf(jar),    0 ether);

        top.vent();
        assertEq(sai.totalSupply(), 0);
        assertEq(sin.totalSupply(), 0);

        assertEq(skr.totalSupply(), 0);
    }
    function testFailCashSafeOverCollatWithFreeSkrExitBeforeBail() {
        // fails because exit is before bail
        var cup = cageSetup();
        tub.join(20 ether);   // give us some more skr
        mark(1 ether);
        top.cage();

        top.cash();
        tub.exit(uint128(skr.balanceOf(this)));
        assertEq(skr.balanceOf(this), 0 ether);
        var gemBySAI = 5 ether; // Adding 5 gem from 5 sai
        var gemBySKR = wdiv(wmul(20 ether, 30 ether - gemBySAI), 30 ether);
        assertEq(gem.balanceOf(this), 70 ether + gemBySAI + gemBySKR);

        assertEq(sai.balanceOf(this), 0);
        assertEq(sai.totalSupply(), 0);
        assertEq(sin.totalSupply(), 0);

        tub.bite(cup);
        tub.free(cup, tub.ink(cup));
        top.vent();
        assertEq(skr.balanceOf(this), 5 ether); // skr retrieved by bail(cup)

        tub.exit(uint128(skr.balanceOf(this)));
        assertEq(gem.balanceOf(this), 100 ether);
        assertEq(sai.balanceOf(this),   0 ether);
        assertEq(gem.balanceOf(jar),    0 ether);
        assertEq(sai.totalSupply(), 0);
        assertEq(sin.totalSupply(), 0);

        assertEq(skr.totalSupply(), 0);
    }
    function testCashUnsafeOverCollat() {
        var cup = cageSetup();
        tub.join(20 ether);   // give us some more skr
        var price = wdiv(3 ether, 4 ether);
        mark(price);
        top.cage();        // 150% collat

        assertEq(sai.balanceOf(this),  5 ether);
        assertEq(skr.balanceOf(this), 20 ether);
        assertEq(gem.balanceOf(this), 70 ether);

        top.cash();
        assertEq(sai.balanceOf(this),   0 ether);
        assertEq(skr.balanceOf(this),  20 ether);

        var gemBySAI = wdiv(wmul(5 ether, 4 ether), 3 ether);
        var gemBySKR = 0;

        assertEq(gem.balanceOf(this), 70 ether + gemBySAI + gemBySKR);
        assertEq(gem.balanceOf(jar),  30 ether - gemBySAI - gemBySKR);

        // how much gem should be returned?
        // there were 10 gems initially, of which 5 were 100% collat
        // at the cage price, 5 * 4 / 3 are 100% collat,
        // leaving 10 - 5 * 4 / 3 as excess = 3.333
        // this should all be returned
        var ink = tub.ink(cup);
        var tab = tub.tab(cup);
        var skrToRecover = hsub(ink, wdiv(tab, price));
        tub.bite(cup);
        tub.free(cup, tub.ink(cup));

        assertEq(skr.balanceOf(this), 20 ether + skrToRecover);
        assertEq(skr.balanceOf(tub),  0 ether);

        top.vent();
        tub.exit(uint128(skr.balanceOf(this)));
        assertEq(gem.balanceOf(this), 100 ether);
        assertEq(gem.balanceOf(jar),    0 ether);

        top.vent();
        assertEq(skr.totalSupply(), 0);
        assertEq(sai.totalSupply(), 0);
        assertEq(sin.totalSupply(), 0);
    }
    function testCashAtCollat() {
        var cup = cageSetup();
        var price = wdiv(1 ether, 2 ether);  // 100% collat
        mark(price);
        top.cage();

        assertEq(sai.balanceOf(this),  5 ether);
        assertEq(skr.balanceOf(this),  0 ether);
        assertEq(gem.balanceOf(this), 90 ether);
        top.cash();
        assertEq(sai.balanceOf(this),   0 ether);
        assertEq(skr.balanceOf(this),   0 ether);

        var saved = rmul(5 ether, rdiv(WAD, price));

        assertEq(gem.balanceOf(this),  90 ether + saved);
        assertEq(gem.balanceOf(jar),   10 ether - saved);

        // how much gem should be returned?
        // none :D
        assertEq(gem.balanceOf(this), 100 ether);
        assertEq(gem.balanceOf(jar),    0 ether);
        tub.bite(cup);
        tub.free(cup, tub.ink(cup));
        assertEq(gem.balanceOf(this), 100 ether);
        assertEq(gem.balanceOf(jar),    0 ether);

        top.vent();
        assertEq(skr.totalSupply(), 0);
        assertEq(sai.totalSupply(), 0);
        assertEq(sin.totalSupply(), 0);
    }
    function testCashAtCollatFreeSkr() {
        var cup = cageSetup();
        tub.join(20 ether);   // give us some more skr
        var price = wdiv(1 ether, 2 ether);  // 100% collat
        mark(price);
        top.cage();

        assertEq(sai.balanceOf(this),   5 ether);
        assertEq(skr.balanceOf(this),  20 ether);
        assertEq(gem.balanceOf(this),  70 ether);

        top.cash();
        assertEq(sai.balanceOf(this),   0 ether);

        tub.bite(cup);
        tub.free(cup, tub.ink(cup));
        top.vent();
        tub.exit(uint128(skr.balanceOf(this)));
        assertEq(gem.balanceOf(this), 100 ether);
        assertEq(gem.balanceOf(jar),    0 ether);

        assertEq(skr.totalSupply(), 0);
    }
    function testFailCashAtCollatFreeSkrExitBeforeBail() {
        var cup = cageSetup();
        tub.join(20 ether);   // give us some more skr
        var price = wdiv(1 ether, 2 ether);  // 100% collat
        mark(price);
        top.cage();

        assertEq(sai.balanceOf(this),  5 ether);
        assertEq(skr.balanceOf(this), 20 ether);
        assertEq(gem.balanceOf(this), 70 ether);

        top.cash();
        assertEq(sai.balanceOf(this),   0 ether);
        tub.exit(uint128(skr.balanceOf(this)));
        assertEq(skr.balanceOf(this),   0 ether);


        var gemBySAI = wmul(5 ether, 2 ether);
        var gemBySKR = wdiv(wmul(20 ether, 30 ether - gemBySAI), 30 ether);

        assertEq(gem.balanceOf(this), 70 ether + gemBySAI + gemBySKR);
        assertEq(gem.balanceOf(jar),  30 ether - gemBySAI - gemBySKR);

        assertEq(sai.totalSupply(), 0);
        assertEq(sin.totalSupply(), 0);

        tub.bite(cup);
        tub.free(cup, tub.ink(cup));
        top.vent();
        tub.exit(uint128(skr.balanceOf(this)));

        // Cup did not have skr to free, then the ramaining gem in tub can not be shared as there is not more skr to exit
        assertEq(gem.balanceOf(this), 70 ether + gemBySAI + gemBySKR);
        assertEq(gem.balanceOf(jar),  30 ether - gemBySAI - gemBySKR);

        assertEq(skr.totalSupply(), 0);
    }
    function testCashUnderCollat() {
        var cup = cageSetup();
        var price = wdiv(1 ether, 4 ether);  // 50% collat
        mark(price);
        top.cage();

        assertEq(sai.balanceOf(this),  5 ether);
        assertEq(skr.balanceOf(this),  0 ether);
        assertEq(gem.balanceOf(this), 90 ether);
        top.cash();
        assertEq(sai.balanceOf(this),   0 ether);
        assertEq(skr.balanceOf(this),   0 ether);

        // get back all 10 gems, which are now only worth 2.5 ref
        // so you've lost 50% on you sai
        assertEq(gem.balanceOf(this), 100 ether);
        assertEq(gem.balanceOf(jar),    0 ether);

        // how much gem should be returned?
        // none :D
        assertEq(gem.balanceOf(this), 100 ether);
        assertEq(gem.balanceOf(jar),    0 ether);
        tub.bite(cup);
        tub.free(cup, tub.ink(cup));
        assertEq(gem.balanceOf(this), 100 ether);
        assertEq(gem.balanceOf(jar),    0 ether);

        top.vent();
        assertEq(skr.totalSupply(), 0);
        assertEq(sai.totalSupply(), 0);
        assertEq(sin.totalSupply(), 0);
    }
    function testCashUnderCollatFreeSkr() {
        var cup = cageSetup();
        tub.join(20 ether);   // give us some more skr
        var price = wdiv(1 ether, 4 ether);   // 50% collat
        mark(price);
        top.cage();

        tmp.pull(skr, this);  // stash skr

        assertEq(sai.balanceOf(this),  5 ether);
        assertEq(gem.balanceOf(this), 70 ether);
        top.cash();
        assertEq(sai.balanceOf(this),  0 ether);
        // returns 20 gems, taken from the free skr,
        // sai is made whole
        assertEq(gem.balanceOf(this), 90 ether);

        tmp.push(skr, this);  // unstash skr
        assertEq(skr.balanceOf(this),  20 ether);
        tub.bite(cup);
        tub.free(cup, tub.ink(cup));

        top.vent();
        tub.exit(uint128(skr.balanceOf(this)));
        assertEq(skr.balanceOf(this),   0 ether);
        // the skr has taken a 50% loss - 10 gems returned from 20 put in
        assertEq(gem.balanceOf(this), 100 ether);
        assertEq(gem.balanceOf(jar),    0 ether);

        assertEq(sai.totalSupply(), 0);
        assertEq(sin.totalSupply(), 0);

        assertEq(skr.totalSupply(), 0);
    }

    function testThreeCupsOverCollat() {
        var cup = cageSetup();
        tub.join(90 ether);   // give us some more skr
        var cup2 = tub.open(); // open a new cup
        tub.lock(cup2, 20 ether); // lock collateral but not draw DAI
        var cup3 = tub.open(); // open a new cup
        tub.lock(cup3, 20 ether); // lock collateral but not draw DAI

        assertEq(gem.balanceOf(pit), 0);
        assertEq(gem.balanceOf(jar), 100 ether);
        assertEq(gem.balanceOf(this), 0);
        assertEq(skr.balanceOf(this), 50 ether); // free skr
        assertEq(skr.balanceOf(jar), 50 ether); // locked skr

        var price = 1 ether;
        mark(price);
        top.cage();

        assertEq(gem.balanceOf(pit), 5 ether); // Needed to payout 5 sai
        assertEq(gem.balanceOf(jar), 95 ether);

        tub.bite(cup);
        tub.free(cup, tub.ink(cup)); // 5 skr recovered, and 5 skr burnt

        assertEq(skr.balanceOf(this), 55 ether); // free skr
        assertEq(skr.balanceOf(jar), 40 ether); // locked skr

        tub.bite(cup2);
        tub.free(cup2, tub.ink(cup2)); // 20 skr recovered

        assertEq(skr.balanceOf(this), 75 ether); // free skr
        assertEq(skr.balanceOf(jar), 20 ether); // locked skr

        tub.bite(cup3);
        tub.free(cup3, tub.ink(cup3)); // 20 skr recovered

        assertEq(skr.balanceOf(this), 95 ether); // free skr
        assertEq(skr.balanceOf(jar), 0); // locked skr

        top.cash();

        assertEq(sai.balanceOf(this), 0);
        assertEq(gem.balanceOf(this), 5 ether);

        top.vent();
        tub.exit(uint128(skr.balanceOf(this))); // exit 95 skr at price 95/95

        assertEq(gem.balanceOf(jar), 0);
        assertEq(gem.balanceOf(pit), 0);
        assertEq(gem.balanceOf(this), 100 ether);
        assertEq(skr.totalSupply(), 0);
    }
    function testThreeCupsAtCollat() {
        var cup = cageSetup();
        tub.join(90 ether);   // give us some more skr
        var cup2 = tub.open(); // open a new cup
        tub.lock(cup2, 20 ether); // lock collateral but not draw DAI
        var cup3 = tub.open(); // open a new cup
        tub.lock(cup3, 20 ether); // lock collateral but not draw DAI

        assertEq(gem.balanceOf(pit), 0);
        assertEq(gem.balanceOf(jar), 100 ether);
        assertEq(gem.balanceOf(this), 0);
        assertEq(skr.balanceOf(this), 50 ether); // free skr
        assertEq(skr.balanceOf(jar), 50 ether); // locked skr

        var price = wdiv(1 ether, 2 ether);
        mark(price);
        top.cage();

        assertEq(gem.balanceOf(pit), 10 ether); // Needed to payout 10 sai
        assertEq(gem.balanceOf(jar), 90 ether);

        tub.bite(cup);
        tub.free(cup, tub.ink(cup)); // 10 skr burnt

        assertEq(skr.balanceOf(this), 50 ether); // free skr
        assertEq(skr.balanceOf(jar), 40 ether); // locked skr

        tub.bite(cup2);
        tub.free(cup2, tub.ink(cup2)); // 20 skr recovered

        assertEq(skr.balanceOf(this), 70 ether); // free skr
        assertEq(skr.balanceOf(jar), 20 ether); // locked skr

        tub.bite(cup3);
        tub.free(cup3, tub.ink(cup3)); // 20 skr recovered

        assertEq(skr.balanceOf(this), 90 ether); // free skr
        assertEq(skr.balanceOf(jar), 0); // locked skr

        top.cash();

        assertEq(sai.balanceOf(this), 0);
        assertEq(gem.balanceOf(this), 10 ether);

        top.vent();
        tub.exit(uint128(skr.balanceOf(this))); // exit 90 skr at price 90/90

        assertEq(gem.balanceOf(jar), 0);
        assertEq(gem.balanceOf(pit), 0);
        assertEq(gem.balanceOf(this), 100 ether);
        assertEq(skr.totalSupply(), 0);
    }
    function testThreeCupsUnderCollat() {
        var cup = cageSetup();
        tub.join(90 ether);   // give us some more skr
        var cup2 = tub.open(); // open a new cup
        tub.lock(cup2, 20 ether); // lock collateral but not draw DAI
        var cup3 = tub.open(); // open a new cup
        tub.lock(cup3, 20 ether); // lock collateral but not draw DAI

        assertEq(gem.balanceOf(pit), 0);
        assertEq(gem.balanceOf(jar), 100 ether);
        assertEq(gem.balanceOf(this), 0);
        assertEq(skr.balanceOf(this), 50 ether); // free skr
        assertEq(skr.balanceOf(jar), 50 ether); // locked skr

        var price = wdiv(1 ether, 4 ether);
        mark(price);
        top.cage();

        assertEq(gem.balanceOf(pit), 20 ether); // Needed to payout 5 sai
        assertEq(gem.balanceOf(jar), 80 ether);

        tub.bite(cup);
        tub.free(cup, tub.ink(cup)); // No skr is retrieved as the cup doesn't even cover the debt. 10 locked skr in cup are burnt from pot

        assertEq(skr.balanceOf(this), 50 ether); // free skr
        assertEq(skr.balanceOf(jar), 40 ether); // locked skr

        tub.bite(cup2);
        tub.free(cup2, tub.ink(cup2)); // 20 skr recovered

        assertEq(skr.balanceOf(this), 70 ether); // free skr
        assertEq(skr.balanceOf(jar), 20 ether); // locked skr

        tub.bite(cup3);
        tub.free(cup3, tub.ink(cup3)); // 20 skr recovered

        assertEq(skr.balanceOf(this), 90 ether); // free skr
        assertEq(skr.balanceOf(jar), 0); // locked skr

        top.cash();

        assertEq(sai.balanceOf(this), 0);
        assertEq(gem.balanceOf(this), 20 ether);

        top.vent();
        tub.exit(uint128(skr.balanceOf(this))); // exit 90 skr at price 80/90

        assertEq(gem.balanceOf(jar), 0);
        assertEq(gem.balanceOf(pit), 0);
        assertEq(gem.balanceOf(this), 100 ether);
        assertEq(skr.totalSupply(), 0);
    }
    function testThreeCupsSKRZeroValue() {
        var cup = cageSetup();
        tub.join(90 ether);   // give us some more skr
        var cup2 = tub.open(); // open a new cup
        tub.lock(cup2, 20 ether); // lock collateral but not draw DAI
        var cup3 = tub.open(); // open a new cup
        tub.lock(cup3, 20 ether); // lock collateral but not draw DAI

        assertEq(gem.balanceOf(pit), 0);
        assertEq(gem.balanceOf(jar), 100 ether);
        assertEq(gem.balanceOf(this), 0);
        assertEq(skr.balanceOf(this), 50 ether); // free skr
        assertEq(skr.balanceOf(jar), 50 ether); // locked skr

        var price = wdiv(1 ether, 20 ether);
        mark(price);
        top.cage();

        assertEq(gem.balanceOf(pit), 100 ether); // Needed to payout 5 sai
        assertEq(gem.balanceOf(jar), 0 ether);

        tub.bite(cup);
        tub.free(cup, tub.ink(cup)); // No skr is retrieved as the cup doesn't even cover the debt. 10 locked skr in cup are burnt from pot

        assertEq(skr.balanceOf(this), 50 ether); // free skr
        assertEq(skr.balanceOf(jar), 40 ether); // locked skr

        tub.bite(cup2);
        tub.free(cup2, tub.ink(cup2)); // 20 skr recovered

        assertEq(skr.balanceOf(this), 70 ether); // free skr
        assertEq(skr.balanceOf(jar), 20 ether); // locked skr

        tub.bite(cup3);
        tub.free(cup3, tub.ink(cup3)); // 20 skr recovered

        assertEq(skr.balanceOf(this), 90 ether); // free skr
        assertEq(skr.balanceOf(jar), 0); // locked skr

        top.cash();

        assertEq(sai.balanceOf(this), 0);
        assertEq(gem.balanceOf(this), 100 ether);

        top.vent();
        tub.exit(uint128(skr.balanceOf(this))); // exit 90 skr at price 0/90

        assertEq(gem.balanceOf(jar), 0);
        assertEq(gem.balanceOf(pit), 0);
        assertEq(gem.balanceOf(this), 100 ether);
        assertEq(skr.totalSupply(), 0);
    }

    function testPeriodicFixValue() {
        cageSetup();

        assertEq(gem.balanceOf(pit), 0);
        assertEq(gem.balanceOf(jar), 10 ether);
        assertEq(gem.balanceOf(this), 90 ether);
        assertEq(skr.balanceOf(this), 0 ether); // free skr
        assertEq(skr.balanceOf(jar), 10 ether); // locked skr

        FakePerson person = new FakePerson(top);
        mom.setUserRole(person, 1, true);
        sai.transfer(person, 2.5 ether); // Transfer half of SAI balance to the other user

        var price = rdiv(9 ether, 8 ether);
        mark(price);
        top.cage();

        assertEq(gem.balanceOf(pit), rmul(5 ether, top.fix())); // Needed to payout 5 sai
        assertEq(gem.balanceOf(jar), hsub(10 ether, rmul(5 ether, top.fix())));

        top.cash();

        assertEq(sai.balanceOf(this),     0 ether);
        assertEq(sai.balanceOf(person), 2.5 ether);
        assertEq(gem.balanceOf(this), hadd(90 ether, rmul(2.5 ether, top.fix())));

        person.cash();
    }

    function testCageExitAfterPeriod() {
        var cup = cageSetup();
        tub.cuff(ray(1 ether));  // 100% collat limit
        tub.free(cup, 5 ether);  // 100% collat

        assertEq(uint(tub.caged()), 0);
        top.cage();
        assertEq(uint(tub.caged()), tip.era());

        // exit fails because ice != 0 && fog !=0 and not enough time passed
        assert(!tub.call(bytes4(sha3('exit(uint128)')), 5 ether));

        tub.setCooldown(1 days);
        tip.warp(1 days);
        assert(!tub.call(bytes4(sha3('exit(uint128)')), 5 ether));

        tip.warp(1 seconds);
        assertEq(skr.balanceOf(this), 5 ether);
        assertEq(gem.balanceOf(this), 90 ether);
        assert(tub.call(bytes4(sha3('exit(uint128)')), 4 ether));
        assertEq(skr.balanceOf(this), 1 ether);
        // n.b. we don't get back 4 as there is still skr in the cup
        assertEq(gem.balanceOf(this), 92 ether);

        // now we can cash in our sai
        assertEq(sai.balanceOf(this), 5 ether);
        top.cash();
        assertEq(sai.balanceOf(this), 0 ether);
        assertEq(gem.balanceOf(this), 97 ether);

        // the remaining gem can be claimed only if the cup skr is burned
        assertEqWad(tub.air(), 5 ether);
        assertEqWad(tap.fog(), 0 ether);
        assertEqWad(tub.ice(), 5 ether);
        assertEqWad(tap.woe(), 0 ether);
        tub.bite(cup);
        assertEqWad(tub.air(), 0 ether);
        assertEqWad(tap.fog(), 5 ether);
        assertEqWad(tub.ice(), 0 ether);
        assertEqWad(tap.woe(), 5 ether);

        top.vent();
        assertEqWad(tap.fog(), 0 ether);
        assertEqWad(tap.woe(), 0 ether);

        // now this remaining 1 skr will claim all the remaining 3 ether.
        // this is why exiting early is bad if you want to maximise returns.
        // if we had exited with all the skr earlier, there would be 2.5 gem
        // trapped in the jar.
        tub.exit(1 ether);
        assertEq(skr.balanceOf(this),   0 ether);
        assertEq(gem.balanceOf(this), 100 ether);
    }
}

contract LiquidationTest is SaiTestBase {
    function liq(bytes32 cup) returns (uint128) {
        // compute the liquidation price of a cup
        var jam = rmul(tub.ink(cup), tub.jar().per());  // this many eth
        var con = wmul(tub.tab(cup), tub.tip().par());  // this much ref debt
        var min = rmul(con, tub.mat());        // minimum ref debt
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
        var pro = wmul(tub.ink(cup), tub.jar().tag());
        var con = wmul(tub.tab(cup), tub.tip().par());
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

    function testBustMint() {
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
        assertEqWad(tap.fog(), 8 ether);

        // 8 skr for sale
        assertEqWad(tub.jar().per(), ray(1 ether));

        // get 2 skr, pay 4 sai (25% of the debt)
        var sai_before = sai.balanceOf(this);
        var skr_before = skr.balanceOf(this);
        assertEq(sai_before, 16 ether);
        tap.bust(2 ether);
        var sai_after = sai.balanceOf(this);
        var skr_after = skr.balanceOf(this);
        assertEq(sai_before - sai_after, 4 ether);
        assertEq(skr_after - skr_before, 2 ether);

        // price drop. now remaining 6 skr cannot cover bad debt (12 sai)
        mark(1 ether);

        // get 6 skr, pay 6 sai
        tap.bust(6 ether);
        // no more skr remaining to sell
        assertEqWad(tap.fog(), 0);
        // but skr supply unchanged
        assertEq(skr.totalSupply(), 10 ether);

        // now skr will be minted
        tap.bust(2 ether);
        assertEq(skr.totalSupply(), 12 ether);
    }
    function testBustNoMint() {
        tub.cork(1000 ether);
        tub.cuff(ray(2 ether));    // 200% liq limit
        tub.chop(ray(1.5 ether));  // 150% liq penalty
        mark(20 ether);

        tub.join(10 ether);
        var cup = tub.open();
        tub.lock(cup, 10 ether);
        tub.draw(cup, 100 ether);  // 200 % collat

        mark(15 ether);
        tub.bite(cup);

        // nothing remains in the cup
        assertEqWad(tub.tab(cup), 0);
        assertEqWad(tub.ink(cup), 0);

        // all collateral is now fog
        assertEqWad(tap.fog(), 10 ether);
        assertEqWad(tap.woe(), 100 ether);

        // the fog is worth 150 sai and the woe is worth 100 sai.
        // If all the fog is sold, there will be a sai surplus.

        // get some more sai to buy with
        tub.join(10 ether);
        var mug = tub.open();
        tub.lock(mug, 10 ether);
        tub.draw(mug, 50 ether);

        tap.bust(10 ether);
        assertEq(sai.balanceOf(this), 0 ether);
        assertEq(skr.balanceOf(this), 10 ether);
        assertEqWad(tap.fog(), 0 ether);
        assertEqWad(tap.woe(), 0 ether);
        assertEqWad(tap.joy(), 50 ether);

        // joy is available through boom
        assertEqWad(tap.bid(), 15 ether);
        tap.boom(2 ether);
        assertEq(sai.balanceOf(this), 30 ether);
        assertEq(skr.balanceOf(this),  8 ether);
        assertEqWad(tap.fog(), 0 ether);
        assertEqWad(tap.woe(), 0 ether);
        assertEqWad(tap.joy(), 20 ether);
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
        var tin = tub.open();

        tub.lock(cup, 10 ether);
        tub.lock(mug, 10 ether);
        tub.lock(tin, 10 ether);

        tub.draw(cup, 50 ether);  // 200% collat
        tub.draw(mug, 40 ether);  // 250% collat
        tub.draw(tin, 19 ether);  // 421% collat

        mark(4 ether);  // cup 80%, mug 100%, tin 200%
        tub.bite(cup);

        // inflation happens when the confiscated skr can no longer
        // cover the debt. With axe == 1, this happens as soon as the
        // price falls. With axe == 1.25, the price has to fall by 20%.
        // Beyond this price fall, there is inflation.
        // This is an extra justification for axe (beyond penalising bad
        // cup holders).
        assertEqWad(tap.fog(), 10 ether);
        assertEqWad(tap.woe(), 50 ether);
        tap.bust(tap.fog());
        assertEqWad(tap.fog(), 0 ether);
        assertEqWad(tap.woe(), 10 ether);
        // price still 1
        assertEqWad(tub.jar().per(), ray(1 ether));

        // now force some minting, which flips the tin to unsafe
        assert(tub.safe(tin));
        tap.bust(wdiv(5 ether, 2 ether));
        assert(!tub.safe(tin));

        assertEqWad(tap.woe(), 0);
        assertEqWad(tub.jar().per(), rdiv(80 ether * WAD, 85 ether * WAD));  // 5.88% less gem/skr

        // mug is now under parity as well
        tub.bite(mug);
        tap.bust(tap.fog());
        tap.bust(wdiv(tap.woe(), wmul(tub.jar().per(), jar.tag())));

        tub.bite(tin);

        // N.B from the initial price markdown the whole system was in deficit
    }
}

contract TaxTest is SaiTestBase {
    function testEraInit() {
        assertEq(uint(tip.era()), now);
    }
    function testEraWarp() {
        tip.warp(20);
        assertEq(uint(tip.era()), now + 20);
    }
    function taxSetup() returns (bytes32 cup) {
        mark(10 ether);
        gem.mint(1000 ether);

        tub.cork(1000 ether);
        tub.crop(1000000564701133626865910626);  // 5% / day
        cup = tub.open();
        tub.join(100 ether);
        tub.lock(cup, 100 ether);
        tub.draw(cup, 100 ether);
    }
    function testTaxEra() {
        var cup = taxSetup();
        assertEqWad(tub.tab(cup), 100 ether);
        tip.warp(1 days);
        assertEqWad(tub.tab(cup), 105 ether);
        tip.warp(1 days);
        assertEqWad(tub.tab(cup), 110.25 ether);
    }
    // Tax accumulates as sai surplus
    function testTaxJoy() {
        var cup = taxSetup();
        assertEqWad(tap.joy(),      0 ether);
        assertEqWad(tub.tab(cup), 100 ether);
        tip.warp(1 days);
        assertEqWad(tub.tab(cup), 105 ether);
        assertEqWad(tap.joy(),      5 ether);
    }
    function testTaxDraw() {
        var cup = taxSetup();
        tip.warp(1 days);
        assertEqWad(tub.tab(cup), 105 ether);
        tub.draw(cup, 100 ether);
        assertEqWad(tub.tab(cup), 205 ether);
        tip.warp(1 days);
        assertEqWad(tub.tab(cup), 215.25 ether);
    }
    function testTaxWipe() {
        var cup = taxSetup();
        tip.warp(1 days);
        assertEqWad(tub.tab(cup), 105 ether);
        tub.wipe(cup, 50 ether);
        assertEqWad(tub.tab(cup), 55 ether);
        tip.warp(1 days);
        assertEqWad(tub.tab(cup), 57.75 ether);
    }
    // collected fees are available through boom
    function testTaxBoom() {
        taxSetup();
        tip.warp(1 days);
        // should have 5 sai available == 0.5 skr
        tub.join(0.5 ether);  // get some unlocked skr

        assertEq(skr.totalSupply(),   100.5 ether);
        assertEq(sai.balanceOf(pit),    0 ether);
        assertEq(sin.balanceOf(pit),    0 ether);
        assertEq(sai.balanceOf(this), 100 ether);
        tub.drip();
        assertEq(sai.balanceOf(pit),    5 ether);
        tap.boom(0.5 ether);
        assertEq(skr.totalSupply(),   100 ether);
        assertEq(sai.balanceOf(pit),    0 ether);
        assertEq(sin.balanceOf(pit),    0 ether);
        assertEq(sai.balanceOf(this), 105 ether);
    }
    // Tax can flip a cup to unsafe
    function testTaxSafe() {
        var cup = taxSetup();
        mark(1 ether);
        assert(tub.safe(cup));
        tip.warp(1 days);
        assert(!tub.safe(cup));
    }
    function testTaxBite() {
        var cup = taxSetup();
        mark(1 ether);
        tip.warp(1 days);
        assertEqWad(tub.tab(cup), 105 ether);
        tub.bite(cup);
        assertEqWad(tub.tab(cup),   0 ether);
        assertEqWad(tap.woe(),    105 ether);
    }
    function testTaxBiteRounding() {
        var cup = taxSetup();
        mark(1 ether);
        tub.cuff(ray(1.5 ether));
        tub.chop(ray(1.4 ether));
        tub.crop(ray(1.000000001547126 ether));
        // log_named_uint('tab', tub.tab(cup));
        // log_named_uint('sin', sin.balanceOf(pot));
        for (var i=0; i<=50; i++) {
            tip.warp(10);
            // log_named_uint('tab', tub.tab(cup));
            // log_named_uint('sin', sin.balanceOf(pot));
        }
        uint128 debtAfterWarp = rmul(100 ether, rpow(tub.tax(), 510));
        assertEqWad(tub.tab(cup), debtAfterWarp);
        tub.bite(cup);
        assertEqWad(tub.tab(cup), 0 ether);
        assertEqWad(tap.woe(), rmul(100 ether, rpow(tub.tax(), 510)));
    }
    function testTaxBail() {
        var cup = taxSetup();
        tip.warp(1 days);
        tub.drip();
        mark(10 ether);
        top.cage();

        tip.warp(1 days);  // should have no effect
        tub.drip();

        assertEq(skr.balanceOf(this),  0 ether);
        assertEq(skr.balanceOf(jar), 100 ether);
        tub.bite(cup);
        tub.free(cup, tub.ink(cup));
        assertEq(skr.balanceOf(this), 89.5 ether);
        assertEq(skr.balanceOf(jar),     0 ether);

        assertEq(sai.balanceOf(this),  100 ether);
        assertEq(gem.balanceOf(this), 1000 ether);
        top.cash();
        assertEq(sai.balanceOf(this),    0 ether);
        assertEq(gem.balanceOf(this), 1010 ether);
    }
    function testTaxCage() {
        // after cage, un-distributed tax revenue remains as joy - sai
        // surplus in the pit. The remaining joy, plus all outstanding
        // sai, balances the sin debt in the pot, plus any debt (woe) in
        // the pit.

        // The effect of this is that joy remaining in tap is
        // effectively distributed to all skr holders.
        var cup = taxSetup();
        tip.warp(1 days);
        mark(10 ether);

        assertEqWad(tap.joy(), 0 ether);
        top.cage();                // should drip up to date
        assertEqWad(tap.joy(), 5 ether);
        tip.warp(1 days);  tub.drip();  // should have no effect
        assertEqWad(tap.joy(), 5 ether);

        var owe = tub.tab(cup);
        assertEqWad(owe, 105 ether);
        assertEqWad(tub.ice(), owe);
        assertEqWad(tap.woe(), 0);
        tub.bite(cup);
        assertEqWad(tub.ice(), 0);
        assertEqWad(tap.woe(), owe);

        assertEqWad(tap.joy(), 5 ether);
        top.vent();
        assertEqWad(tap.joy(),   0 ether);
        assertEqWad(tap.woe(), 100 ether);
    }
}

contract WayTest is SaiTestBase {
    function waySetup() returns (bytes32 cup) {
        mark(10 ether);
        gem.mint(1000 ether);

        tub.cork(1000 ether);

        cup = tub.open();
        tub.join(100 ether);
        tub.lock(cup, 100 ether);
        tub.draw(cup, 100 ether);
    }
    // what does way actually do?
    // it changes the value of sai relative to ref
    // way > 1 -> par increasing, more ref per sai
    // way < 1 -> par decreasing, less ref per sai

    // this changes the safety level of cups,
    // affecting `draw`, `wipe`, `free` and `bite`

    // if way < 1, par is decreasing and the con (in ref)
    // of a cup is decreasing, so cup holders need
    // less ref to wipe (but the same sai)
    // This makes cups *more* collateralised with time.
    function testTau() {
        assertEq(uint(tip.era()), now);
        assertEq(uint(tip.tau()), now);
    }
    function testWayPar() {
        tip.coax(999999406327787478619865402);  // -5% / day

        assertEqWad(tip.par(), 1.00 ether);
        tip.warp(1 days);
        assertEqWad(tip.par(), 0.95 ether);

        tip.coax(1000008022568992670911001251);  // 200% / day
        tip.warp(1 days);
        assertEqWad(tip.par(), 1.90 ether);
    }
    function testWayDecreasingPrincipal() {
        var cup = waySetup();
        mark(0.98 ether);
        assert(!tub.safe(cup));

        tip.coax(999999406327787478619865402);  // -5% / day
        tip.warp(1 days);
        assert(tub.safe(cup));
    }
    // `cage` is slightly affected: the cage price is
    // now in *sai per gem*, where before ref per gem
    // was equivalent.
    // `bail` is unaffected, as all values are in sai.
    function testWayCage() {
        waySetup();

        tip.coax(1000008022568992670911001251);  // 200% / day
        tip.warp(1 days);  // par now 2

        // we have 100 sai
        // gem is worth 10 ref
        // sai is worth 2 ref
        // we should get back 100 / (10 / 2) = 20 gem

        top.cage();

        assertEq(gem.balanceOf(this), 1000 ether);
        assertEq(sai.balanceOf(this),  100 ether);
        assertEq(sai.balanceOf(pit),     0 ether);
        top.cash();
        assertEq(gem.balanceOf(this), 1020 ether);
        assertEq(sai.balanceOf(this),   0 ether);
        assertEq(sai.balanceOf(pit),  100 ether);
    }

    // `boom` and `bust` as par is now needed to determine
    // the skr / sai price.
    function testWayBust() {
        var cup = waySetup();
        mark(0.5 ether);
        tub.bite(cup);

        assertEqWad(tap.joy(),   0 ether);
        assertEqWad(tap.woe(), 100 ether);
        assertEqWad(tap.fog(), 100 ether);
        assertEq(sai.balanceOf(this), 100 ether);

        tap.bust(50 ether);

        assertEqWad(tap.fog(),  50 ether);
        assertEqWad(tap.woe(),  75 ether);
        assertEq(sai.balanceOf(this), 75 ether);

        tip.coax(999991977495368425989823173);  // -50% / day
        tip.warp(1 days);
        assertEqWad(tip.par(), 0.5 ether);
        // sai now worth half as much, so we cover twice as much debt
        // for the same skr
        tap.bust(50 ether);

        assertEqWad(tap.fog(),   0 ether);
        assertEqWad(tap.woe(),  25 ether);
        assertEq(sai.balanceOf(this), 25 ether);
    }
    function testWayBoom() {
        var cup = waySetup();
        tub.join(100 ether);       // give us some spare skr
        sai.push(pit, 100 ether);  // force some joy into the tap
        assertEqWad(tap.joy(), 100 ether);

        mark(2 ether);
        tip.coax(1000008022568992670911001251);  // 200% / day
        tip.warp(1 days);
        assertEqWad(tip.par(), 2 ether);
        tap.boom(100 ether);
        assertEqWad(tap.joy(),   0 ether);
        assertEqWad(tub.jar().per(), ray(2 ether));

        tub.join(100 ether);
        tub.draw(cup, 100 ether);
        sai.push(pit, 100 ether);  // force some joy into the tap

        // n.b. per is now 2
        assertEqWad(tap.joy(), 100 ether);
        mark(2 ether);
        tip.coax(999991977495368425989823173);  // -50% / day
        tip.warp(2 days);
        assertEqWad(tip.par(), 0.5 ether);
        tap.boom(12.5 ether);
        assertEqWad(tap.joy(),   0 ether);
    }
}

contract GapTest is SaiTestBase {
    // boom and bust have a spread parameter
    function setUp() {
        super.setUp();

        gem.mint(500 ether);
        tub.join(500 ether);

        sai.mint(500 ether);
        sin.mint(500 ether);

        mark(2 ether);  // 2 ref per eth => 2 sai per skr
    }
    function testGapTapBid() {
        mark(1 ether);
        tap.jump(1.01 ether);  // 1% spread
        assertEqWad(tap.bid(), 0.99 ether);
        mark(2 ether);
        assertEqWad(tap.bid(), 1.98 ether);
    }
    function testGapTapAsk() {
        mark(1 ether);
        tap.jump(1.01 ether);  // 1% spread
        assertEqWad(tap.ask(), 1.01 ether);
        mark(2 ether);
        assertEqWad(tap.ask(), 2.02 ether);
    }
    function testGapBoom() {
        sai.push(pit, 198 ether);
        assertEqWad(tap.joy(), 198 ether);

        tap.jump(1.01 ether);  // 1% spread

        var sai_before = sai.balanceOf(this);
        var skr_before = skr.balanceOf(this);
        tap.boom(50 ether);
        var sai_after = sai.balanceOf(this);
        var skr_after = skr.balanceOf(this);
        assertEq(sai_after - sai_before, 99 ether);
        assertEq(skr_before - skr_after, 50 ether);
    }
    function testGapBust() {
        skr.push(pit, 100 ether);
        sin.push(pit, 200 ether);
        assertEqWad(tap.fog(), 100 ether);
        assertEqWad(tap.woe(), 200 ether);

        tap.jump(1.01 ether);

        var sai_before = sai.balanceOf(this);
        var skr_before = skr.balanceOf(this);
        tap.bust(50 ether);
        var sai_after = sai.balanceOf(this);
        var skr_after = skr.balanceOf(this);
        assertEq(skr_after - skr_before,  50 ether);
        assertEq(sai_before - sai_after, 101 ether);
    }
    function testGapLimits() {
        uint128 legal   = 1.04 ether;
        uint128 illegal = 1.06 ether;

        assert(tap.call(bytes4(sha3("jump(uint128)")), legal));
        assertEqWad(tap.gap(), legal);

        assert(!tap.call(bytes4(sha3("jump(uint128)")), illegal));
        assertEqWad(tap.gap(), legal);
    }

    // join and exit have a spread parameter
    function testGapJarBidAsk() {
        assertEqWad(jar.per(), ray(1 ether));
        assertEqWad(jar.bid(), ray(1 ether));
        assertEqWad(jar.ask(), ray(1 ether));

        jar.jump(1.01 ether);
        assertEqWad(jar.bid(), ray(0.99 ether));
        assertEqWad(jar.ask(), ray(1.01 ether));

        assertEq(skr.balanceOf(this), 500 ether);
        assertEq(skr.totalSupply(),   500 ether);
        skr.burn(250 ether);

        assertEqWad(jar.per(), ray(2    ether));
        assertEqWad(jar.bid(), ray(1.98 ether));
        assertEqWad(jar.ask(), ray(2.02 ether));
    }
    function testGapJoin() {
        gem.mint(100 ether);

        jar.jump(1.05 ether);
        var skr_before = skr.balanceOf(this);
        var gem_before = gem.balanceOf(this);
        tub.join(100 ether);
        var skr_after = skr.balanceOf(this);
        var gem_after = gem.balanceOf(this);

        var res = wdiv(100 ether, 1.05 ether);
        assertEq(skr_after - skr_before,  res);
        assertEq(gem_before - gem_after, 100 ether);
    }
    function testGapExit() {
        gem.mint(100 ether);
        tub.join(100 ether);

        jar.jump(1.05 ether);
        var skr_before = skr.balanceOf(this);
        var gem_before = gem.balanceOf(this);
        tub.exit(100 ether);
        var skr_after = skr.balanceOf(this);
        var gem_after = gem.balanceOf(this);

        assertEq(gem_after - gem_before,  95 ether);
        assertEq(skr_before - skr_after, 100 ether);
    }
}

contract GasTest is SaiTestBase {
    bytes32 cup;
    function setUp() {
        super.setUp();

        mark(1 ether);
        gem.mint(1000 ether);

        tub.cork(1000 ether);

        cup = tub.open();
        tub.join(1000 ether);
        tub.lock(cup, 500 ether);
        tub.draw(cup, 100 ether);
    }
    function doLock(uint128 wad) logs_gas {
        tub.lock(cup, wad);
    }
    function doDraw(uint128 wad) logs_gas {
        tub.draw(cup, wad);
    }
    function doDrip() logs_gas {
        tub.drip();
    }
    function doBoom(uint128 wad) logs_gas {
        tap.boom(wad);
    }
    function testGasLock() {
        doLock(100 ether);
    }
    function testGasDraw() {
        doDraw(100 ether);
    }
    function testGasDrip() {
        tip.warp(1);
        doDrip();
    }
    function testGasDripNoop() {
        tub.drip();
        doDrip();
    }
    function testGasBoom() {
        tub.join(10 ether);
        sai.mint(100 ether);
        sai.push(pit, 100 ether);
        skr.approve(pit, uint(-1));
        doBoom(1 ether);
    }
    function testGasBoomHeal() {
        tub.join(10 ether);
        sai.mint(100 ether);
        sin.mint(100 ether);
        sai.push(pit, 100 ether);
        sin.push(pit,  50 ether);
        skr.approve(pit, uint(-1));
        doBoom(1 ether);
    }
}
