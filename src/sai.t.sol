pragma solidity ^0.4.15;

import "ds-test/test.sol";

import "ds-math/math.sol";

import 'ds-token/token.sol';
import 'ds-guard/guard.sol';
import 'ds-value/value.sol';

import './tub.sol';
import './top.sol';
import './tap.sol';

contract SaiAdmin is DSThing {
    SaiTub  public  tub;
    SaiTap  public  tap;
    SaiVox  public  vox;

    function SaiAdmin(SaiTub tub_, SaiTap tap_, SaiVox vox_) {
        tub = tub_;
        tap = tap_;
        vox = vox_;
    }
    function mold(bytes32 param, uint val) note auth {
        tub.mold(param, val);
    }
    // Debt ceiling
    function setHat(uint wad) note auth {
        tub.mold('hat', wad);
    }
    // Liquidation ratio
    function setMat(uint ray) note auth {
        tub.mold('mat', ray);
        var axe = tub.axe();
        var mat = tub.mat();
        require(axe >= RAY && axe <= mat);
    }
    // Stability fee
    function setTax(uint ray) note auth {
        tub.mold('tax', ray);
        var tax = tub.tax();
        require(RAY <= tax);
        require(tax < 10002 * 10 ** 23);  // ~200% per hour
    }
    // Liquidation fee
    function setAxe(uint ray) note auth {
        tub.mold('axe', ray);
        var axe = tub.axe();
        var mat = tub.mat();
        require(axe >= RAY && axe <= mat);
    }
    // Join/Exit Spread
    function setTubGap(uint wad) note auth {
        tub.mold('gap', wad);
    }
    // Boom/Bust Spread
    function setTapGap(uint wad) note auth {
        tap.mold('gap', wad);
        var gap = tap.gap();
        require(gap <= 1.05 ether);
        require(gap >= 0.95 ether);
    }
    // Rate of change of target price (per second)
    function setWay(uint ray) note auth {
        require(ray < 10002 * 10 ** 23);  // ~200% per hour
        require(ray >  9998 * 10 ** 23);
        vox.mold('way', ray);
    }
}

contract FakePerson {
    SaiTap  public tap;
    DSToken public sai;

    function FakePerson(SaiTap _tap) {
        tap = _tap;
        sai = tap.sai();
        sai.trust(tap, true);
    }

    function cash() {
        tap.cash();
    }
}

contract SaiTestBase is DSTest, DSMath {
    SaiVox   vox;
    SaiTub   tub;
    SaiTop   top;
    SaiTap   tap;

    SaiAdmin admin;

    DSToken  gem;
    DSToken  sai;
    DSToken  sin;
    DSToken  skr;

    DSValue  tag;
    DSGuard  dad;

    function ray(uint256 wad) returns (uint256) {
        return wad * 10 ** 9;
    }
    function wad(uint256 ray_) returns (uint256) {
        return wdiv(ray_, RAY);
    }

    function mark(uint256 price) {
        tag.poke(bytes32(price));
    }
    function warp(uint64 age) {
        vox.warp(age);
        tub.warp(age);
        top.warp(age);
    }

    function configureAuth() {
        vox.setAuthority(dad);
        tub.setAuthority(dad);
        tap.setAuthority(dad);
        top.setAuthority(dad);

        sai.setAuthority(dad);
        sin.setAuthority(dad);
        skr.setAuthority(dad);

        vox.setOwner(0);
        tub.setOwner(0);
        tap.setOwner(0);
        top.setOwner(0);

        sai.setOwner(0);
        sin.setOwner(0);
        skr.setOwner(0);

        dad.permit(top, tub, bytes4(sha3("cage(uint256,uint256)")));
        dad.permit(top, tub, bytes4(sha3("flow()")));
        dad.permit(top, tap, bytes4(sha3("cage(uint256)")));

        dad.permit(tub, skr, bytes4(sha3('mint(address,uint256)')));
        dad.permit(tub, skr, bytes4(sha3('burn(address,uint256)')));

        dad.permit(tub, sai, bytes4(sha3('mint(address,uint256)')));
        dad.permit(tub, sai, bytes4(sha3('burn(address,uint256)')));

        dad.permit(tub, sin, bytes4(sha3('mint(uint256)')));
        dad.permit(tub, sin, bytes4(sha3('burn(uint256)')));

        dad.permit(tap, sai, bytes4(sha3('burn(uint256)')));
        dad.permit(tap, sin, bytes4(sha3('burn(uint256)')));

        dad.permit(tap, skr, bytes4(sha3('mint(uint256)')));
        dad.permit(tap, skr, bytes4(sha3('burn(uint256)')));
        dad.permit(tap, skr, bytes4(sha3('burn(address,uint256)')));

        // admin controls
        dad.permit(admin, vox, bytes4(sha3("mold(bytes32,uint256)")));
        dad.permit(admin, tub, bytes4(sha3("mold(bytes32,uint256)")));
        dad.permit(admin, tap, bytes4(sha3("mold(bytes32,uint256)")));

        dad.permit(this, top, bytes4(sha3("cage(uint256)")));
        dad.permit(this, top, bytes4(sha3("cage()")));
        dad.permit(this, top, bytes4(sha3("setCooldown(uint64)")));

        // convenience in tests
        dad.permit(this, sai, bytes4(sha3('mint(uint256)')));
        dad.permit(this, sai, bytes4(sha3('burn(uint256)')));
        dad.permit(this, sai, bytes4(sha3('mint(address,uint256)')));
        dad.permit(this, sai, bytes4(sha3('burn(address,uint256)')));
        dad.permit(this, sin, bytes4(sha3('mint(uint256)')));
        dad.permit(this, sin, bytes4(sha3('burn(uint256)')));
        dad.permit(this, sin, bytes4(sha3('mint(address,uint256)')));
        dad.permit(this, sin, bytes4(sha3('burn(address,uint256)')));
        dad.permit(this, skr, bytes4(sha3('mint(uint256)')));
        dad.permit(this, skr, bytes4(sha3('burn(uint256)')));
        dad.permit(this, skr, bytes4(sha3('mint(address,uint256)')));
        dad.permit(this, skr, bytes4(sha3('burn(address,uint256)')));

        dad.setOwner(0);
    }

    function setUp() {
        gem = new DSToken("GEM");
        gem.mint(100 ether);

        sai = new DSToken("SAI");
        sin = new DSToken("SIN");

        skr = new DSToken("SKR");

        tag = new DSValue();
        vox = new SaiVox();

        tap = new SaiTap();
        tub = new SaiTub(sai, sin, skr, gem, tag, vox, tap);
        top = new SaiTop(tub, tap);
        tap.turn(tub);

        dad = new DSGuard();

        admin = new SaiAdmin(tub, tap, vox);

        configureAuth();

        sai.trust(tub, true);
        skr.trust(tub, true);
        gem.trust(tub, true);

        sai.trust(tap, true);
        skr.trust(tap, true);

        tag.poke(bytes32(1 ether));

        admin.setHat(20 ether);
    }
}

contract SaiTubTest is SaiTestBase {
    function testBasic() {
        assertEq( skr.balanceOf(tub), 0 ether );
        assertEq( skr.balanceOf(this), 0 ether );
        assertEq( gem.balanceOf(tub), 0 ether );

        // edge case
        assertEq( uint256(tub.per()), ray(1 ether) );
        tub.join(10 ether);
        assertEq( uint256(tub.per()), ray(1 ether) );

        assertEq( skr.balanceOf(this), 10 ether );
        assertEq( gem.balanceOf(tub), 10 ether );
        // price formula
        tub.join(10 ether);
        assertEq( uint256(tub.per()), ray(1 ether) );
        assertEq( skr.balanceOf(this), 20 ether );
        assertEq( gem.balanceOf(tub), 20 ether );

        var cup = tub.open();

        assertEq( skr.balanceOf(this), 20 ether );
        assertEq( skr.balanceOf(tub), 0 ether );
        tub.lock(cup, 10 ether); // lock skr token
        assertEq( skr.balanceOf(this), 10 ether );
        assertEq( skr.balanceOf(tub), 10 ether );

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
        var setAxe = bytes4(sha3('setAxe(uint256)'));
        var setHat = bytes4(sha3('setHat(uint256)'));
        var setMat = bytes4(sha3('setMat(uint256)'));

        assertTrue(admin.call(setHat, 0 ether));
        assertTrue(admin.call(setHat, 5 ether));

        assertTrue(!admin.call(setAxe, ray(2 ether)));
        assertTrue( admin.call(setMat, ray(2 ether)));
        assertTrue( admin.call(setAxe, ray(2 ether)));
        assertTrue(!admin.call(setMat, ray(1 ether)));
    }
    function testJoinInitial() {
        assertEq(skr.totalSupply(),     0 ether);
        assertEq(skr.balanceOf(this),   0 ether);
        assertEq(gem.balanceOf(this), 100 ether);
        tub.join(10 ether);
        assertEq(skr.balanceOf(this), 10 ether);
        assertEq(gem.balanceOf(this), 90 ether);
        assertEq(gem.balanceOf(tub),  10 ether);
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
        admin.setMat(ray(1 ether));
        tub.join(10 ether);
        var cup = tub.open();
        tub.lock(cup, 10 ether);

        tub.draw(cup, 11 ether);
    }
    function testFailOverDrawExcess() {
        admin.setMat(ray(1 ether));
        tub.join(20 ether);
        var cup = tub.open();
        tub.lock(cup, 10 ether);

        tub.draw(cup, 11 ether);
    }
    function testDraw() {
        admin.setMat(ray(1 ether));
        tub.join(10 ether);
        var cup = tub.open();
        tub.lock(cup, 10 ether);

        assertEq(sai.balanceOf(this),  0 ether);
        assertEq(sin.balanceOf(tub),   0 ether);
        tub.draw(cup, 10 ether);
        assertEq(sai.balanceOf(this), 10 ether);
        assertEq(sin.balanceOf(tub),  10 ether);
    }
    function testWipe() {
        admin.setMat(ray(1 ether));
        tub.join(10 ether);
        var cup = tub.open();
        tub.lock(cup, 10 ether);
        tub.draw(cup, 10 ether);

        assertEq(sai.balanceOf(this), 10 ether);
        assertEq(sin.balanceOf(tub),  10 ether);
        tub.wipe(cup, 5 ether);
        assertEq(sai.balanceOf(this),  5 ether);
        assertEq(sin.balanceOf(tub),   5 ether);
    }
    function testUnsafe() {
        tub.join(10 ether);
        var cup = tub.open();
        tub.lock(cup, 10 ether);
        tub.draw(cup, 9 ether);

        assertTrue(tub.safe(cup));
        tag.poke(bytes32(1 ether / 2));
        assertTrue(!tub.safe(cup));
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
        admin.setMat(ray(2 ether));  // require 200% collateralisation
        tub.join(10 ether);
        var cup = tub.open();
        tub.lock(cup, 10 ether);

        tub.draw(cup, 4 ether);  // 250% collateralisation
        assertTrue(tub.safe(cup));
        tag.poke(bytes32(1 ether / 2));   // 125% collateralisation
        assertTrue(!tub.safe(cup));

        assertEq(tap.fog(), uint(0));
        tub.bite(cup);
        assertEq(tap.fog(), uint(8 ether));

        // cdp should now be safe with 0 sai debt and 2 skr remaining
        var skr_before = skr.balanceOf(this);
        tub.free(cup, 1 ether);
        assertEq(skr.balanceOf(this) - skr_before, 1 ether);
    }
    function testLock() {
        tub.join(10 ether);
        var cup = tub.open();

        assertEq(skr.balanceOf(tub),  0 ether);
        tub.lock(cup, 10 ether);
        assertEq(skr.balanceOf(tub), 10 ether);
    }
    function testFree() {
        admin.setMat(ray(2 ether));  // require 200% collateralisation
        tub.join(10 ether);
        var cup = tub.open();
        tub.lock(cup, 10 ether);
        tub.draw(cup, 4 ether);  // 250% collateralisation

        var skr_before = skr.balanceOf(this);
        tub.free(cup, 2 ether);  // 225%
        assertEq(skr.balanceOf(this) - skr_before, 2 ether);
    }
    function testFailFreeToUnderCollat() {
        admin.setMat(ray(2 ether));  // require 200% collateralisation
        tub.join(10 ether);
        var cup = tub.open();
        tub.lock(cup, 10 ether);
        tub.draw(cup, 4 ether);  // 250% collateralisation

        tub.free(cup, 3 ether);  // 175% -- fails
    }
    function testFailDrawOverDebtCeiling() {
        admin.setHat(4 ether);
        tub.join(10 ether);
        var cup = tub.open();
        tub.lock(cup, 10 ether);

        tub.draw(cup, 5 ether);
    }
    function testDebtCeiling() {
        admin.setHat(5 ether);
        admin.setMat(ray(2 ether));  // require 200% collat
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
        admin.setHat(5 ether);            // 5 sai debt ceiling
        tag.poke(bytes32(1 ether));   // price 1:1 gem:ref
        admin.setMat(ray(2 ether));       // require 200% collat
        tub.join(10 ether);
        var cup = tub.open();
        tub.lock(cup, 10 ether);
        tub.draw(cup, 5 ether);       // 200% collateralisation

        return cup;
    }
    function testCageSafeOverCollat() {
        cageSetup();

        assertEq(top.fix(), 0);
        assertEq(tub.fit(), 0);
        assertEq(tap.woe(), 0);         // no bad debt
        assertEq(tub.pie(), 10 ether);

        tub.join(20 ether);   // give us some more skr
        mark(1 ether);
        top.cage();

        var woe = sin.balanceOf(tub);
        assertEq(woe, 5 ether);             // all good debt now bad debt
        assertEq(wad(top.fix()), 1 ether);  // sai redeems 1:1 with gem
        assertEq(wad(tub.fit()), 1 ether);  // skr redeems 1:1 with gem just before pushing gem to tub

        assertEq(gem.balanceOf(tap),  5 ether);  // saved for sai
        assertEq(gem.balanceOf(tub), 25 ether);  // saved for skr
    }
    function testCageUnsafeOverCollat() {
        cageSetup();

        assertEq(top.fix(), 0);
        assertEq(tub.fit(), 0);
        assertEq(tub.per(), ray(1 ether));

        tub.join(20 ether);   // give us some more skr
        var price = wdiv(3 ether, 4 ether);
        mark(price);
        top.cage();        // 150% collat

        assertEq(top.fix(), rdiv(1 ether, price));  // sai redeems 4:3 with gem
        assertEq(tub.fit(), ray(price));                 // skr redeems 1:1 with gem just before pushing gem to tub

        // gem needed for sai is 5 * 4 / 3
        var saved = rmul(5 ether, rdiv(WAD, price));
        assertEq(gem.balanceOf(tap),  saved);             // saved for sai
        assertEq(gem.balanceOf(tub),  30 ether - saved);  // saved for skr
    }
    function testCageAtCollat() {
        cageSetup();

        assertEq(top.fix(), 0);
        assertEq(tub.fit(), 0);
        assertEq(tub.per(), ray(1 ether));

        var price = wdiv(1 ether, 2 ether);  // 100% collat
        mark(price);
        top.cage();

        assertEq(top.fix(), ray(2 ether));  // sai redeems 1:2 with gem, 1:1 with ref
        assertEq(tub.per(), 0);       // skr redeems 1:0 with gem after cage
    }
    function testCageAtCollatFreeSkr() {
        cageSetup();

        assertEq(top.fix(), 0);
        assertEq(tub.fit(), 0);
        assertEq(tub.per(), ray(1 ether));

        tub.join(20 ether);   // give us some more skr
        var price = wdiv(1 ether, 2 ether);  // 100% collat
        mark(price);
        top.cage();

        assertEq(top.fix(), ray(2 ether));  // sai redeems 1:2 with gem, 1:1 with ref
        assertEq(tub.fit(), ray(price));       // skr redeems 1:1 with gem just before pushing gem to tub
    }
    function testCageUnderCollat() {
        cageSetup();

        assertEq(top.fix(), 0);
        assertEq(tub.fit(), 0);
        assertEq(tub.per(), ray(1 ether));

        var price = wdiv(1 ether, 4 ether);   // 50% collat
        mark(price);
        top.cage();

        assertEq(2 * sai.totalSupply(), gem.balanceOf(tap));
        assertEq(top.fix(), ray(2 ether));  // sai redeems 1:2 with gem, 2:1 with ref
        assertEq(tub.per(), 0);       // skr redeems 1:0 with gem after cage
    }
    function testCageUnderCollatFreeSkr() {
        cageSetup();

        assertEq(top.fix(), 0);
        assertEq(tub.fit(), 0);
        assertEq(tub.per(), ray(1 ether));

        tub.join(20 ether);   // give us some more skr
        var price = wdiv(1 ether, 4 ether);   // 50% collat
        mark(price);
        top.cage();

        assertEq(4 * sai.totalSupply(), gem.balanceOf(tap));
        assertEq(top.fix(), ray(4 ether));                 // sai redeems 1:4 with gem, 1:1 with ref
    }

    // ensure cash returns the expected amount
    function testCashSafeOverCollat() {
        var cup = cageSetup();
        mark(1 ether);
        top.cage();

        assertEq(sai.balanceOf(this),  5 ether);
        assertEq(skr.balanceOf(this),  0 ether);
        assertEq(gem.balanceOf(this), 90 ether);
        assertEq(gem.balanceOf(tub),   5 ether);
        assertEq(gem.balanceOf(tap),   5 ether);

        tap.cash();
        assertEq(sai.balanceOf(this),   0 ether);
        assertEq(skr.balanceOf(this),   0 ether);
        assertEq(gem.balanceOf(this),  95 ether);
        assertEq(gem.balanceOf(tub),    5 ether);

        assertEq(tub.ink(cup), 10 ether);
        tub.bite(cup);
        assertEq(tub.ink(cup), 5 ether);
        tub.free(cup, tub.ink(cup));
        assertEq(skr.balanceOf(this),   5 ether);
        tap.vent();
        top.flow();
        tub.exit(uint256(skr.balanceOf(this)));
        assertEq(gem.balanceOf(this), 100 ether);
        assertEq(gem.balanceOf(tub),    0 ether);

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
        assertEq(gem.balanceOf(tub),  25 ether);
        assertEq(gem.balanceOf(tap),   5 ether);

        tub.bite(cup);
        tub.free(cup, tub.ink(cup));
        tap.vent();
        top.flow();
        assertEq(skr.balanceOf(this), 25 ether);
        tap.cash();
        tub.exit(uint256(skr.balanceOf(this)));
        assertEq(gem.balanceOf(this), 100 ether);
        assertEq(sai.balanceOf(this),   0 ether);
        assertEq(gem.balanceOf(tub),    0 ether);

        tap.vent();
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

        tap.cash();
        tub.exit(uint256(skr.balanceOf(this)));
        assertEq(skr.balanceOf(this), 0 ether);
        uint256 gemBySAI = 5 ether; // Adding 5 gem from 5 sai
        uint256 gemBySKR = wdiv(wmul(20 ether, 30 ether - gemBySAI), 30 ether);
        assertEq(gem.balanceOf(this), 70 ether + gemBySAI + gemBySKR);

        assertEq(sai.balanceOf(this), 0);
        assertEq(sai.totalSupply(), 0);
        assertEq(sin.totalSupply(), 0);

        tub.bite(cup);
        tub.free(cup, tub.ink(cup));
        tap.vent();
        top.flow();
        assertEq(skr.balanceOf(this), 5 ether); // skr retrieved by bail(cup)

        tub.exit(uint256(skr.balanceOf(this)));
        assertEq(gem.balanceOf(this), 100 ether);
        assertEq(sai.balanceOf(this),   0 ether);
        assertEq(gem.balanceOf(tub),    0 ether);
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

        tap.cash();
        assertEq(sai.balanceOf(this),   0 ether);
        assertEq(skr.balanceOf(this),  20 ether);

        uint256 gemBySAI = wdiv(wmul(5 ether, 4 ether), 3 ether);
        uint256 gemBySKR = 0;

        assertEq(gem.balanceOf(this), 70 ether + gemBySAI + gemBySKR);
        assertEq(gem.balanceOf(tub),  30 ether - gemBySAI - gemBySKR);

        // how much gem should be returned?
        // there were 10 gems initially, of which 5 were 100% collat
        // at the cage price, 5 * 4 / 3 are 100% collat,
        // leaving 10 - 5 * 4 / 3 as excess = 3.333
        // this should all be returned
        var ink = tub.ink(cup);
        var tab = tub.tab(cup);
        var skrToRecover = sub(ink, wdiv(tab, price));
        tub.bite(cup);
        tub.free(cup, tub.ink(cup));

        assertEq(skr.balanceOf(this), 20 ether + skrToRecover);
        assertEq(skr.balanceOf(tub),  0 ether);

        tap.vent();
        top.flow();
        tub.exit(uint256(skr.balanceOf(this)));
        assertEq(gem.balanceOf(this), 100 ether);
        assertEq(gem.balanceOf(tub),    0 ether);

        tap.vent();
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
        tap.cash();
        assertEq(sai.balanceOf(this),   0 ether);
        assertEq(skr.balanceOf(this),   0 ether);

        var saved = rmul(5 ether, rdiv(WAD, price));

        assertEq(gem.balanceOf(this),  90 ether + saved);
        assertEq(gem.balanceOf(tub),   10 ether - saved);

        // how much gem should be returned?
        // none :D
        assertEq(gem.balanceOf(this), 100 ether);
        assertEq(gem.balanceOf(tub),    0 ether);
        tub.bite(cup);
        tub.free(cup, tub.ink(cup));
        assertEq(gem.balanceOf(this), 100 ether);
        assertEq(gem.balanceOf(tub),    0 ether);

        tap.vent();
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

        tap.cash();
        assertEq(sai.balanceOf(this),   0 ether);

        tub.bite(cup);
        tub.free(cup, tub.ink(cup));
        tap.vent();
        top.flow();
        tub.exit(uint256(skr.balanceOf(this)));
        assertEq(gem.balanceOf(this), 100 ether);
        assertEq(gem.balanceOf(tub),    0 ether);

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

        tap.cash();
        assertEq(sai.balanceOf(this),   0 ether);
        tub.exit(uint256(skr.balanceOf(this)));
        assertEq(skr.balanceOf(this),   0 ether);


        var gemBySAI = wmul(5 ether, 2 ether);
        var gemBySKR = wdiv(wmul(20 ether, 30 ether - gemBySAI), 30 ether);

        assertEq(gem.balanceOf(this), 70 ether + gemBySAI + gemBySKR);
        assertEq(gem.balanceOf(tub),  30 ether - gemBySAI - gemBySKR);

        assertEq(sai.totalSupply(), 0);
        assertEq(sin.totalSupply(), 0);

        tub.bite(cup);
        tub.free(cup, tub.ink(cup));
        tap.vent();
        tub.exit(uint256(skr.balanceOf(this)));

        // Cup did not have skr to free, then the ramaining gem in tub can not be shared as there is not more skr to exit
        assertEq(gem.balanceOf(this), 70 ether + gemBySAI + gemBySKR);
        assertEq(gem.balanceOf(tub),  30 ether - gemBySAI - gemBySKR);

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
        tap.cash();
        assertEq(sai.balanceOf(this),   0 ether);
        assertEq(skr.balanceOf(this),   0 ether);

        // get back all 10 gems, which are now only worth 2.5 ref
        // so you've lost 50% on you sai
        assertEq(gem.balanceOf(this), 100 ether);
        assertEq(gem.balanceOf(tub),    0 ether);

        // how much gem should be returned?
        // none :D
        assertEq(gem.balanceOf(this), 100 ether);
        assertEq(gem.balanceOf(tub),    0 ether);
        tub.bite(cup);
        tub.free(cup, tub.ink(cup));
        assertEq(gem.balanceOf(this), 100 ether);
        assertEq(gem.balanceOf(tub),    0 ether);

        tap.vent();
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

        assertEq(sai.balanceOf(this),  5 ether);
        assertEq(gem.balanceOf(this), 70 ether);
        tap.cash();
        assertEq(sai.balanceOf(this),  0 ether);
        // returns 20 gems, taken from the free skr,
        // sai is made whole
        assertEq(gem.balanceOf(this), 90 ether);

        assertEq(skr.balanceOf(this),  20 ether);
        tub.bite(cup);
        tub.free(cup, tub.ink(cup));

        tap.vent();
        top.flow();
        tub.exit(uint256(skr.balanceOf(this)));
        assertEq(skr.balanceOf(this),   0 ether);
        // the skr has taken a 50% loss - 10 gems returned from 20 put in
        assertEq(gem.balanceOf(this), 100 ether);
        assertEq(gem.balanceOf(tub),    0 ether);

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

        assertEq(gem.balanceOf(tap), 0);
        assertEq(gem.balanceOf(tub), 100 ether);
        assertEq(gem.balanceOf(this), 0);
        assertEq(skr.balanceOf(this), 50 ether); // free skr
        assertEq(skr.balanceOf(tub), 50 ether); // locked skr

        uint256 price = 1 ether;
        mark(price);
        top.cage();

        assertEq(gem.balanceOf(tap), 5 ether); // Needed to payout 5 sai
        assertEq(gem.balanceOf(tub), 95 ether);

        tub.bite(cup);
        tub.free(cup, tub.ink(cup)); // 5 skr recovered, and 5 skr burnt

        assertEq(skr.balanceOf(this), 55 ether); // free skr
        assertEq(skr.balanceOf(tub), 40 ether); // locked skr

        tub.bite(cup2);
        tub.free(cup2, tub.ink(cup2)); // 20 skr recovered

        assertEq(skr.balanceOf(this), 75 ether); // free skr
        assertEq(skr.balanceOf(tub), 20 ether); // locked skr

        tub.bite(cup3);
        tub.free(cup3, tub.ink(cup3)); // 20 skr recovered

        assertEq(skr.balanceOf(this), 95 ether); // free skr
        assertEq(skr.balanceOf(tub), 0); // locked skr

        tap.cash();

        assertEq(sai.balanceOf(this), 0);
        assertEq(gem.balanceOf(this), 5 ether);

        tap.vent();
        top.flow();
        tub.exit(uint256(skr.balanceOf(this))); // exit 95 skr at price 95/95

        assertEq(gem.balanceOf(tub), 0);
        assertEq(gem.balanceOf(tap), 0);
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

        assertEq(gem.balanceOf(tap), 0);
        assertEq(gem.balanceOf(tub), 100 ether);
        assertEq(gem.balanceOf(this), 0);
        assertEq(skr.balanceOf(this), 50 ether); // free skr
        assertEq(skr.balanceOf(tub), 50 ether); // locked skr

        var price = wdiv(1 ether, 2 ether);
        mark(price);
        top.cage();

        assertEq(gem.balanceOf(tap), 10 ether); // Needed to payout 10 sai
        assertEq(gem.balanceOf(tub), 90 ether);

        tub.bite(cup);
        tub.free(cup, tub.ink(cup)); // 10 skr burnt

        assertEq(skr.balanceOf(this), 50 ether); // free skr
        assertEq(skr.balanceOf(tub), 40 ether); // locked skr

        tub.bite(cup2);
        tub.free(cup2, tub.ink(cup2)); // 20 skr recovered

        assertEq(skr.balanceOf(this), 70 ether); // free skr
        assertEq(skr.balanceOf(tub), 20 ether); // locked skr

        tub.bite(cup3);
        tub.free(cup3, tub.ink(cup3)); // 20 skr recovered

        assertEq(skr.balanceOf(this), 90 ether); // free skr
        assertEq(skr.balanceOf(tub), 0); // locked skr

        tap.cash();

        assertEq(sai.balanceOf(this), 0);
        assertEq(gem.balanceOf(this), 10 ether);

        tap.vent();
        top.flow();
        tub.exit(uint256(skr.balanceOf(this))); // exit 90 skr at price 90/90

        assertEq(gem.balanceOf(tub), 0);
        assertEq(gem.balanceOf(tap), 0);
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

        assertEq(gem.balanceOf(tap), 0);
        assertEq(gem.balanceOf(tub), 100 ether);
        assertEq(gem.balanceOf(this), 0);
        assertEq(skr.balanceOf(this), 50 ether); // free skr
        assertEq(skr.balanceOf(tub), 50 ether); // locked skr

        var price = wdiv(1 ether, 4 ether);
        mark(price);
        top.cage();

        assertEq(gem.balanceOf(tap), 20 ether); // Needed to payout 5 sai
        assertEq(gem.balanceOf(tub), 80 ether);

        tub.bite(cup);
        tub.free(cup, tub.ink(cup)); // No skr is retrieved as the cup doesn't even cover the debt. 10 locked skr in cup are burnt from tub

        assertEq(skr.balanceOf(this), 50 ether); // free skr
        assertEq(skr.balanceOf(tub), 40 ether); // locked skr

        tub.bite(cup2);
        tub.free(cup2, tub.ink(cup2)); // 20 skr recovered

        assertEq(skr.balanceOf(this), 70 ether); // free skr
        assertEq(skr.balanceOf(tub), 20 ether); // locked skr

        tub.bite(cup3);
        tub.free(cup3, tub.ink(cup3)); // 20 skr recovered

        assertEq(skr.balanceOf(this), 90 ether); // free skr
        assertEq(skr.balanceOf(tub), 0); // locked skr

        tap.cash();

        assertEq(sai.balanceOf(this), 0);
        assertEq(gem.balanceOf(this), 20 ether);

        tap.vent();
        top.flow();
        tub.exit(uint256(skr.balanceOf(this))); // exit 90 skr at price 80/90

        assertEq(gem.balanceOf(tub), 0);
        assertEq(gem.balanceOf(tap), 0);
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

        assertEq(gem.balanceOf(tap), 0);
        assertEq(gem.balanceOf(tub), 100 ether);
        assertEq(gem.balanceOf(this), 0);
        assertEq(skr.balanceOf(this), 50 ether); // free skr
        assertEq(skr.balanceOf(tub), 50 ether); // locked skr

        var price = wdiv(1 ether, 20 ether);
        mark(price);
        top.cage();

        assertEq(gem.balanceOf(tap), 100 ether); // Needed to payout 5 sai
        assertEq(gem.balanceOf(tub), 0 ether);

        tub.bite(cup);
        tub.free(cup, tub.ink(cup)); // No skr is retrieved as the cup doesn't even cover the debt. 10 locked skr in cup are burnt from tub

        assertEq(skr.balanceOf(this), 50 ether); // free skr
        assertEq(skr.balanceOf(tub), 40 ether); // locked skr

        tub.bite(cup2);
        tub.free(cup2, tub.ink(cup2)); // 20 skr recovered

        assertEq(skr.balanceOf(this), 70 ether); // free skr
        assertEq(skr.balanceOf(tub), 20 ether); // locked skr

        tub.bite(cup3);
        tub.free(cup3, tub.ink(cup3)); // 20 skr recovered

        assertEq(skr.balanceOf(this), 90 ether); // free skr
        assertEq(skr.balanceOf(tub), 0); // locked skr

        tap.cash();

        assertEq(sai.balanceOf(this), 0);
        assertEq(gem.balanceOf(this), 100 ether);

        tap.vent();
        top.flow();
        tub.exit(uint256(skr.balanceOf(this))); // exit 90 skr at price 0/90

        assertEq(gem.balanceOf(tub), 0);
        assertEq(gem.balanceOf(tap), 0);
        assertEq(gem.balanceOf(this), 100 ether);
        assertEq(skr.totalSupply(), 0);
    }

    function testPeriodicFixValue() {
        cageSetup();

        assertEq(gem.balanceOf(tap), 0);
        assertEq(gem.balanceOf(tub), 10 ether);
        assertEq(gem.balanceOf(this), 90 ether);
        assertEq(skr.balanceOf(this), 0 ether); // free skr
        assertEq(skr.balanceOf(tub), 10 ether); // locked skr

        FakePerson person = new FakePerson(tap);
        sai.transfer(person, 2.5 ether); // Transfer half of SAI balance to the other user

        var price = rdiv(9 ether, 8 ether);
        mark(price);
        top.cage();

        assertEq(gem.balanceOf(tap), rmul(5 ether, top.fix())); // Needed to payout 5 sai
        assertEq(gem.balanceOf(tub), sub(10 ether, rmul(5 ether, top.fix())));

        tap.cash();

        assertEq(sai.balanceOf(this),     0 ether);
        assertEq(sai.balanceOf(person), 2.5 ether);
        assertEq(gem.balanceOf(this), add(90 ether, rmul(2.5 ether, top.fix())));

        person.cash();
    }

    function testCageExitAfterPeriod() {
        var cup = cageSetup();
        admin.setMat(ray(1 ether));  // 100% collat limit
        tub.free(cup, 5 ether);  // 100% collat

        assertEq(uint(top.caged()), 0);
        top.cage();
        assertEq(uint(top.caged()), vox.era());

        // exit fails because ice != 0 && fog !=0 and not enough time passed
        assertTrue(!tub.call(bytes4(sha3('exit(uint256)')), 5 ether));

        top.setCooldown(1 days);
        warp(1 days);
        assertTrue(!tub.call(bytes4(sha3('exit(uint256)')), 5 ether));

        warp(1 seconds);
        top.flow();
        assertEq(skr.balanceOf(this), 5 ether);
        assertEq(gem.balanceOf(this), 90 ether);
        assertTrue(tub.call(bytes4(sha3('exit(uint256)')), 4 ether));
        assertEq(skr.balanceOf(this), 1 ether);
        // n.b. we don't get back 4 as there is still skr in the cup
        assertEq(gem.balanceOf(this), 92 ether);

        // now we can cash in our sai
        assertEq(sai.balanceOf(this), 5 ether);
        tap.cash();
        assertEq(sai.balanceOf(this), 0 ether);
        assertEq(gem.balanceOf(this), 97 ether);

        // the remaining gem can be claimed only if the cup skr is burned
        assertEq(tub.air(), 5 ether);
        assertEq(tap.fog(), 0 ether);
        assertEq(tub.ice(), 5 ether);
        assertEq(tap.woe(), 0 ether);
        tub.bite(cup);
        assertEq(tub.air(), 0 ether);
        assertEq(tap.fog(), 5 ether);
        assertEq(tub.ice(), 0 ether);
        assertEq(tap.woe(), 5 ether);

        tap.vent();
        assertEq(tap.fog(), 0 ether);
        assertEq(tap.woe(), 0 ether);

        // now this remaining 1 skr will claim all the remaining 3 ether.
        // this is why exiting early is bad if you want to maximise returns.
        // if we had exited with all the skr earlier, there would be 2.5 gem
        // trapped in the tub.
        tub.exit(1 ether);
        assertEq(skr.balanceOf(this),   0 ether);
        assertEq(gem.balanceOf(this), 100 ether);
    }
}

contract LiquidationTest is SaiTestBase {
    function liq(bytes32 cup) returns (uint256) {
        // compute the liquidation price of a cup
        var jam = rmul(tub.ink(cup), tub.per());  // this many eth
        var con = rmul(tub.tab(cup), vox.par());  // this much ref debt
        var min = rmul(con, tub.mat());        // minimum ref debt
        return wdiv(min, jam);
    }
    function testLiq() {
        admin.setHat(100 ether);
        mark(2 ether);

        tub.join(10 ether);
        var cup = tub.open();
        tub.lock(cup, 10 ether);
        tub.draw(cup, 10 ether);        // 200% collateralisation

        admin.setMat(ray(1 ether));         // require 100% collateralisation
        assertEq(liq(cup), 1 ether);

        admin.setMat(ray(3 ether / 2));     // require 150% collateralisation
        assertEq(liq(cup), wdiv(3 ether, 2 ether));

        mark(6 ether);
        assertEq(liq(cup), wdiv(3 ether, 2 ether));

        tub.draw(cup, 30 ether);
        assertEq(liq(cup), 6 ether);

        tub.join(10 ether);
        assertEq(liq(cup), 6 ether);

        tub.lock(cup, 10 ether);  // now 40 drawn on 20 gem == 120 ref
        assertEq(liq(cup), 3 ether);
    }
    function collat(bytes32 cup) returns (uint256) {
        // compute the collateralised fraction of a cup
        var pro = rmul(tub.ink(cup), tub.tag());
        var con = rmul(tub.tab(cup), vox.par());
        return wdiv(pro, con);
    }
    function testCollat() {
        admin.setHat(100 ether);
        mark(2 ether);

        tub.join(10 ether);
        var cup = tub.open();
        tub.lock(cup, 10 ether);
        tub.draw(cup, 10 ether);

        assertEq(collat(cup), 2 ether);  // 200%

        mark(4 ether);
        assertEq(collat(cup), 4 ether);  // 400%

        tub.draw(cup, 15 ether);
        assertEq(collat(cup), wdiv(8 ether, 5 ether));  // 160%

        mark(5 ether);
        tub.free(cup, 5 ether);
        assertEq(collat(cup), 1 ether);  // 100%

        mark(4 ether);
        assertEq(collat(cup), wdiv(4 ether, 5 ether));  // 80%

        tub.wipe(cup, 9 ether);
        assertEq(collat(cup), wdiv(5 ether, 4 ether));  // 125%
    }

    function testBustMint() {
        admin.setHat(100 ether);
        admin.setMat(ray(wdiv(3 ether, 2 ether)));  // 150% liq limit
        mark(2 ether);

        tub.join(10 ether);
        var cup = tub.open();
        tub.lock(cup, 10 ether);

        mark(3 ether);
        tub.draw(cup, 16 ether);  // 125% collat
        mark(2 ether);

        assertTrue(!tub.safe(cup));
        tub.bite(cup);
        // 20 ref of gem on 16 ref of sai
        // 125%
        // 100% = 16ref of gem == 8 gem
        assertEq(tap.fog(), 8 ether);

        // 8 skr for sale
        assertEq(tub.per(), ray(1 ether));

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
        assertEq(tap.fog(), 0);
        // but skr supply unchanged
        assertEq(skr.totalSupply(), 10 ether);

        // now skr will be minted
        tap.bust(2 ether);
        assertEq(skr.totalSupply(), 12 ether);
    }
    function testBustNoMint() {
        admin.setHat(1000 ether);
        admin.setMat(ray(2 ether));    // 200% liq limit
        admin.setAxe(ray(1.5 ether));  // 150% liq penalty
        mark(20 ether);

        tub.join(10 ether);
        var cup = tub.open();
        tub.lock(cup, 10 ether);
        tub.draw(cup, 100 ether);  // 200 % collat

        mark(15 ether);
        tub.bite(cup);

        // nothing remains in the cup
        assertEq(tub.tab(cup), 0);
        assertEq(tub.ink(cup), 0);

        // all collateral is now fog
        assertEq(tap.fog(), 10 ether);
        assertEq(tap.woe(), 100 ether);

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
        assertEq(tap.fog(), 0 ether);
        assertEq(tap.woe(), 0 ether);
        assertEq(tap.joy(), 50 ether);

        // joy is available through boom
        assertEq(tap.bid(1 ether), 15 ether);
        tap.boom(2 ether);
        assertEq(sai.balanceOf(this), 30 ether);
        assertEq(skr.balanceOf(this),  8 ether);
        assertEq(tap.fog(), 0 ether);
        assertEq(tap.woe(), 0 ether);
        assertEq(tap.joy(), 20 ether);
    }
}

contract TapTest is SaiTestBase {
    function testTapSetup() {
        assertEq(sai.balanceOf(tap), tap.joy());
        assertEq(sin.balanceOf(tap), tap.woe());
        assertEq(skr.balanceOf(tap), tap.fog());

        assertEq(tap.joy(), 0);
        assertEq(tap.woe(), 0);
        assertEq(tap.fog(), 0);

        sai.mint(tap, 3);
        sin.mint(tap, 4);
        skr.mint(tap, 5);

        assertEq(tap.joy(), 3);
        assertEq(tap.woe(), 4);
        assertEq(tap.fog(), 5);
    }
    // boom (flap) is surplus sale (sai for skr->burn)
    function testTapBoom() {
        sai.mint(tap, 50 ether);
        tub.join(60 ether);

        assertEq(sai.balanceOf(this),  0 ether);
        assertEq(skr.balanceOf(this), 60 ether);
        tap.boom(50 ether);
        assertEq(sai.balanceOf(this), 50 ether);
        assertEq(skr.balanceOf(this), 10 ether);
        assertEq(tap.joy(), 0);
    }
    function testFailTapBoomOverJoy() {
        sai.mint(tap, 50 ether);
        tub.join(60 ether);
        tap.boom(51 ether);
    }
    function testTapBoomHeals() {
        sai.mint(tap, 60 ether);
        sin.mint(tap, 50 ether);
        tub.join(10 ether);

        tap.boom(0 ether);
        assertEq(tap.joy(), 10 ether);
    }
    function testFailTapBoomNetWoe() {
        sai.mint(tap, 50 ether);
        sin.mint(tap, 60 ether);
        tub.join(10 ether);
        tap.boom(1 ether);
    }
    function testTapBoomBurnsSkr() {
        sai.mint(tap, 50 ether);
        tub.join(60 ether);

        assertEq(skr.totalSupply(), 60 ether);
        tap.boom(20 ether);
        assertEq(skr.totalSupply(), 40 ether);
    }
    function testTapBoomIncreasesPer() {
        sai.mint(tap, 50 ether);
        tub.join(60 ether);

        assertEq(tub.per(), ray(1 ether));
        tap.boom(30 ether);
        assertEq(tub.per(), ray(2 ether));
    }
    function testTapBoomMarkDep() {
        sai.mint(tap, 50 ether);
        tub.join(50 ether);

        mark(2 ether);
        tap.boom(10 ether);
        assertEq(sai.balanceOf(this), 20 ether);
        assertEq(sai.balanceOf(tap),  30 ether);
        assertEq(skr.balanceOf(this), 40 ether);
    }
    function testTapBoomPerDep() {
        sai.mint(tap, 50 ether);
        tub.join(50 ether);

        assertEq(tub.per(), ray(1 ether));
        skr.mint(50 ether);  // halves per
        assertEq(tub.per(), ray(.5 ether));

        tap.boom(10 ether);
        assertEq(sai.balanceOf(this),  5 ether);
        assertEq(sai.balanceOf(tap),  45 ether);
        assertEq(skr.balanceOf(this), 90 ether);
    }
    // flip is collateral sale (skr for sai)
    function testTapBustFlip() {
        sai.mint(50 ether);
        tub.join(50 ether);
        skr.push(tap, 50 ether);
        assertEq(tap.fog(), 50 ether);

        assertEq(skr.balanceOf(this),  0 ether);
        assertEq(sai.balanceOf(this), 50 ether);
        tap.bust(30 ether);
        assertEq(skr.balanceOf(this), 30 ether);
        assertEq(sai.balanceOf(this), 20 ether);
    }
    function testFailTapBustFlipOverFog() { // FAIL
        sai.mint(50 ether);
        tub.join(50 ether);
        skr.push(tap, 50 ether);

        tap.bust(51 ether);
    }
    function testTapBustHealsNetJoy() {
        sai.mint(tap, 20 ether);
        sin.mint(tap, 10 ether);

        tap.bust(0 ether);
        assertEq(tap.joy(), 10 ether);
        assertEq(tap.woe(),  0 ether);
    }
    function testTapBustHealsNetWoe() {
        sai.mint(tap, 10 ether);
        sin.mint(tap, 20 ether);

        tap.bust(0 ether);
        assertEq(tap.joy(),  0 ether);
        assertEq(tap.woe(), 10 ether);
    }
    function testTapBustFlipHealsNetJoy() {
        sai.mint(tap, 10 ether);
        sin.mint(tap, 20 ether);
        tub.join(50 ether);
        skr.push(tap, 50 ether);

        sai.mint(15 ether);
        tap.bust(15 ether);
        assertEq(tap.joy(), 5 ether);
        assertEq(tap.woe(), 0 ether);
    }
    function testTapBustFlipHealsNetWoe() {
        sai.mint(tap, 10 ether);
        sin.mint(tap, 20 ether);
        tub.join(50 ether);
        skr.push(tap, 50 ether);

        sai.mint(5 ether);
        tap.bust(5 ether);
        assertEq(tap.joy(), 0 ether);
        assertEq(tap.woe(), 5 ether);
    }
    // flop is debt sale (woe->skr for sai)
    function testTapBustFlop() {
        tub.join(50 ether);  // avoid per=1 init case
        sai.mint(100 ether);
        sin.mint(tap, 50 ether);
        assertEq(tap.woe(), 50 ether);

        assertEq(skr.balanceOf(this),  50 ether);
        assertEq(sai.balanceOf(this), 100 ether);
        tap.bust(50 ether);
        assertEq(skr.balanceOf(this), 100 ether);
        assertEq(sai.balanceOf(this),  75 ether);
    }
    function testFailTapBustFlopNetJoy() {
        tub.join(50 ether);  // avoid per=1 init case
        sai.mint(100 ether);
        sin.mint(tap, 50 ether);
        sai.mint(tap, 100 ether);

        tap.bust(1);  // anything but zero should fail
    }
    function testTapBustFlopMintsSkr() {
        tub.join(50 ether);  // avoid per=1 init case
        sai.mint(100 ether);
        sin.mint(tap, 50 ether);

        assertEq(skr.totalSupply(),  50 ether);
        tap.bust(20 ether);
        assertEq(skr.totalSupply(),  70 ether);
    }
    function testTapBustFlopDecreasesPer() {
        tub.join(50 ether);  // avoid per=1 init case
        sai.mint(100 ether);
        sin.mint(tap, 50 ether);

        assertEq(tub.per(), ray(1 ether));
        tap.bust(50 ether);
        assertEq(tub.per(), ray(.5 ether));
    }

    function testTapBustAsk() {
        tub.join(50 ether);
        assertEq(tap.ask(50 ether), 50 ether);

        skr.mint(50 ether);
        assertEq(tap.ask(50 ether), 25 ether);

        skr.mint(100 ether);
        assertEq(tap.ask(50 ether), 12.5 ether);

        skr.burn(175 ether);
        assertEq(tap.ask(50 ether), 100 ether);

        skr.mint(25 ether);
        assertEq(tap.ask(50 ether), 50 ether);

        skr.mint(10 ether);
        // per = 5 / 6
        assertEq(tap.ask(60 ether), 50 ether);

        skr.mint(30 ether);
        // per = 5 / 9
        assertEq(tap.ask(90 ether), 50 ether);

        skr.mint(10 ether);
        // per = 1 / 2
        assertEq(tap.ask(100 ether), 50 ether);
    }
    // flipflop is debt sale when collateral present
    function testTapBustFlipFlopRounding() {
        tub.join(50 ether);  // avoid per=1 init case
        sai.mint(100 ether);
        sin.mint(tap, 100 ether);
        skr.push(tap,  50 ether);
        assertEq(tap.joy(),   0 ether);
        assertEq(tap.woe(), 100 ether);
        assertEq(tap.fog(),  50 ether);

        assertEq(skr.balanceOf(this),   0 ether);
        assertEq(sai.balanceOf(this), 100 ether);
        assertEq(skr.totalSupply(),    50 ether);

        assertEq(tub.per(), ray(1 ether));
        assertEq(tap.s2s(), ray(1 ether));
        assertEq(tub.tag(), ray(1 ether));
        assertEq(tap.ask(60 ether), 60 ether);
        tap.bust(60 ether);
        assertEq(tub.per(), rdiv(5, 6));
        assertEq(tap.s2s(), rdiv(5, 6));
        assertEq(tub.tag(), rdiv(5, 6));
        // non ray prices would give small rounding error because wad math
        assertEq(tap.ask(60 ether), 50 ether);
        assertEq(skr.totalSupply(),    60 ether);
        assertEq(tap.fog(),             0 ether);
        assertEq(skr.balanceOf(this),  60 ether);
        assertEq(sai.balanceOf(this),  50 ether);
    }
    function testTapBustFlipFlop() {
        tub.join(50 ether);  // avoid per=1 init case
        sai.mint(100 ether);
        sin.mint(tap, 100 ether);
        skr.push(tap,  50 ether);
        assertEq(tap.joy(),   0 ether);
        assertEq(tap.woe(), 100 ether);
        assertEq(tap.fog(),  50 ether);

        assertEq(skr.balanceOf(this),   0 ether);
        assertEq(sai.balanceOf(this), 100 ether);
        assertEq(skr.totalSupply(),    50 ether);
        assertEq(tub.per(), ray(1 ether));
        tap.bust(80 ether);
        assertEq(tub.per(), rdiv(5, 8));
        assertEq(skr.totalSupply(),    80 ether);
        assertEq(tap.fog(),             0 ether);
        assertEq(skr.balanceOf(this),  80 ether);
        assertEq(sai.balanceOf(this),  50 ether);  // expected 50, actual 50 ether + 2???!!!
    }
}

contract TaxTest is SaiTestBase {
    function testEraInit() {
        assertEq(uint(vox.era()), now);
    }
    function testEraWarp() {
        warp(20);
        assertEq(uint(vox.era()), now + 20);
    }
    function taxSetup() returns (bytes32 cup) {
        mark(10 ether);
        gem.mint(1000 ether);

        admin.setHat(1000 ether);
        admin.setTax(1000000564701133626865910626);  // 5% / day
        cup = tub.open();
        tub.join(100 ether);
        tub.lock(cup, 100 ether);
        tub.draw(cup, 100 ether);
    }
    function testTaxEra() {
        var cup = taxSetup();
        assertEq(tub.tab(cup), 100 ether);
        warp(1 days);
        assertEq(tub.tab(cup), 105 ether);
        warp(1 days);
        assertEq(tub.tab(cup), 110.25 ether);
    }
    // Tax accumulates as sai surplus
    function testTaxJoy() {
        var cup = taxSetup();
        assertEq(tap.joy(),      0 ether);
        assertEq(tub.tab(cup), 100 ether);
        warp(1 days);
        assertEq(tub.tab(cup), 105 ether);
        assertEq(tap.joy(),      5 ether);
    }
    function testTaxDraw() {
        var cup = taxSetup();
        warp(1 days);
        assertEq(tub.tab(cup), 105 ether);
        tub.draw(cup, 100 ether);
        assertEq(tub.tab(cup), 205 ether);
        warp(1 days);
        assertEq(tub.tab(cup), 215.25 ether);
    }
    function testTaxWipe() {
        var cup = taxSetup();
        warp(1 days);
        assertEq(tub.tab(cup), 105 ether);
        tub.wipe(cup, 50 ether);
        assertEq(tub.tab(cup), 55 ether);
        warp(1 days);
        assertEq(tub.tab(cup), 57.75 ether);
    }
    // collected fees are available through boom
    function testTaxBoom() {
        taxSetup();
        warp(1 days);
        // should have 5 sai available == 0.5 skr
        tub.join(0.5 ether);  // get some unlocked skr

        assertEq(skr.totalSupply(),   100.5 ether);
        assertEq(sai.balanceOf(tap),    0 ether);
        assertEq(sin.balanceOf(tap),    0 ether);
        assertEq(sai.balanceOf(this), 100 ether);
        tub.drip();
        assertEq(sai.balanceOf(tap),    5 ether);
        tap.boom(0.5 ether);
        assertEq(skr.totalSupply(),   100 ether);
        assertEq(sai.balanceOf(tap),    0 ether);
        assertEq(sin.balanceOf(tap),    0 ether);
        assertEq(sai.balanceOf(this), 105 ether);
    }
    // Tax can flip a cup to unsafe
    function testTaxSafe() {
        var cup = taxSetup();
        mark(1 ether);
        assertTrue(tub.safe(cup));
        warp(1 days);
        assertTrue(!tub.safe(cup));
    }
    function testTaxBite() {
        var cup = taxSetup();
        mark(1 ether);
        warp(1 days);
        assertEq(tub.tab(cup), 105 ether);
        tub.bite(cup);
        assertEq(tub.tab(cup),   0 ether);
        assertEq(tap.woe(),    105 ether);
    }
    function testTaxBiteRounding() {
        var cup = taxSetup();
        mark(1 ether);
        admin.setMat(ray(1.5 ether));
        admin.setAxe(ray(1.4 ether));
        admin.setTax(ray(1.000000001547126 ether));
        // log_named_uint('tab', tub.tab(cup));
        // log_named_uint('sin', sin.balanceOf(tub));
        for (uint i=0; i<=50; i++) {
            warp(10);
            // log_named_uint('tab', tub.tab(cup));
            // log_named_uint('sin', sin.balanceOf(tub));
        }
        uint256 debtAfterWarp = rmul(100 ether, rpow(tub.tax(), 510));
        assertEq(tub.tab(cup), debtAfterWarp);
        tub.bite(cup);
        assertEq(tub.tab(cup), 0 ether);
        assertEq(tap.woe(), rmul(100 ether, rpow(tub.tax(), 510)));
    }
    function testTaxBail() {
        var cup = taxSetup();
        warp(1 days);
        tub.drip();
        mark(10 ether);
        top.cage();

        warp(1 days);  // should have no effect
        tub.drip();

        assertEq(skr.balanceOf(this),  0 ether);
        assertEq(skr.balanceOf(tub), 100 ether);
        tub.bite(cup);
        tub.free(cup, tub.ink(cup));
        assertEq(skr.balanceOf(this), 89.5 ether);
        assertEq(skr.balanceOf(tub),     0 ether);

        assertEq(sai.balanceOf(this),  100 ether);
        assertEq(gem.balanceOf(this), 1000 ether);
        tap.cash();
        assertEq(sai.balanceOf(this),    0 ether);
        assertEq(gem.balanceOf(this), 1010 ether);
    }
    function testTaxCage() {
        // after cage, un-distributed tax revenue remains as joy - sai
        // surplus in the tap. The remaining joy, plus all outstanding
        // sai, balances the sin debt in the tub, plus any debt (woe) in
        // the tap.

        // The effect of this is that joy remaining in tap is
        // effectively distributed to all skr holders.
        var cup = taxSetup();
        warp(1 days);
        mark(10 ether);

        assertEq(tap.joy(), 0 ether);
        top.cage();                // should drip up to date
        assertEq(tap.joy(), 5 ether);
        warp(1 days);  tub.drip();  // should have no effect
        assertEq(tap.joy(), 5 ether);

        var owe = tub.tab(cup);
        assertEq(owe, 105 ether);
        assertEq(tub.ice(), owe);
        assertEq(tap.woe(), 0);
        tub.bite(cup);
        assertEq(tub.ice(), 0);
        assertEq(tap.woe(), owe);

        assertEq(tap.joy(), 5 ether);
        tap.vent();
        assertEq(tap.joy(),   0 ether);
        assertEq(tap.woe(), 100 ether);
    }
}

contract WayTest is SaiTestBase {
    function waySetup() returns (bytes32 cup) {
        mark(10 ether);
        gem.mint(1000 ether);

        admin.setHat(1000 ether);

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
        assertEq(uint(vox.era()), now);
        assertEq(uint(vox.tau()), now);
    }
    function testWayPar() {
        admin.setWay(999999406327787478619865402);  // -5% / day

        assertEq(wad(vox.par()), 1.00 ether);
        warp(1 days);
        assertEq(wad(vox.par()), 0.95 ether);

        admin.setWay(1000008022568992670911001251);  // 200% / day
        warp(1 days);
        assertEq(wad(vox.par()), 1.90 ether);
    }
    function testWayDecreasingPrincipal() {
        var cup = waySetup();
        mark(0.98 ether);
        assertTrue(!tub.safe(cup));

        admin.setWay(999999406327787478619865402);  // -5% / day
        warp(1 days);
        assertTrue(tub.safe(cup));
    }
    // `cage` is slightly affected: the cage price is
    // now in *sai per gem*, where before ref per gem
    // was equivalent.
    // `bail` is unaffected, as all values are in sai.
    function testWayCage() {
        waySetup();

        admin.setWay(1000008022568992670911001251);  // 200% / day
        warp(1 days);  // par now 2

        // we have 100 sai
        // gem is worth 10 ref
        // sai is worth 2 ref
        // we should get back 100 / (10 / 2) = 20 gem

        top.cage();

        assertEq(gem.balanceOf(this), 1000 ether);
        assertEq(sai.balanceOf(this),  100 ether);
        assertEq(sai.balanceOf(tap),     0 ether);
        tap.cash();
        assertEq(gem.balanceOf(this), 1020 ether);
        assertEq(sai.balanceOf(this),   0 ether);
        assertEq(sai.balanceOf(tap),  100 ether);
    }

    // `boom` and `bust` as par is now needed to determine
    // the skr / sai price.
    function testWayBust() {
        var cup = waySetup();
        mark(0.5 ether);
        tub.bite(cup);

        assertEq(tap.joy(),   0 ether);
        assertEq(tap.woe(), 100 ether);
        assertEq(tap.fog(), 100 ether);
        assertEq(sai.balanceOf(this), 100 ether);

        tap.bust(50 ether);

        assertEq(tap.fog(),  50 ether);
        assertEq(tap.woe(),  75 ether);
        assertEq(sai.balanceOf(this), 75 ether);

        admin.setWay(999991977495368425989823173);  // -50% / day
        warp(1 days);
        assertEq(wad(vox.par()), 0.5 ether);
        // sai now worth half as much, so we cover twice as much debt
        // for the same skr
        tap.bust(50 ether);

        assertEq(tap.fog(),   0 ether);
        assertEq(tap.woe(),  25 ether);
        assertEq(sai.balanceOf(this), 25 ether);
    }
    function testWayBoom() {
        var cup = waySetup();
        tub.join(100 ether);       // give us some spare skr
        sai.push(tap, 100 ether);  // force some joy into the tap
        assertEq(tap.joy(), 100 ether);

        mark(2 ether);
        admin.setWay(1000008022568992670911001251);  // 200% / day
        warp(1 days);
        assertEq(wad(vox.par()), 2 ether);
        tap.boom(100 ether);
        assertEq(tap.joy(),   0 ether);
        assertEq(tub.per(), ray(2 ether));

        tub.join(100 ether);
        tub.draw(cup, 100 ether);
        sai.push(tap, 100 ether);  // force some joy into the tap

        // n.b. per is now 2
        assertEq(tap.joy(), 100 ether);
        mark(2 ether);
        admin.setWay(999991977495368425989823173);  // -50% / day
        warp(2 days);
        assertEq(wad(vox.par()), 0.5 ether);
        tap.boom(12.5 ether);
        assertEq(tap.joy(),   0 ether);
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
    function testGapSaiTapBid() {
        mark(1 ether);
        admin.setTapGap(1.01 ether);  // 1% spread
        assertEq(tap.bid(1 ether), 0.99 ether);
        mark(2 ether);
        assertEq(tap.bid(1 ether), 1.98 ether);
    }
    function testGapSaiTapAsk() {
        mark(1 ether);
        admin.setTapGap(1.01 ether);  // 1% spread
        assertEq(tap.ask(1 ether), 1.01 ether);
        mark(2 ether);
        assertEq(tap.ask(1 ether), 2.02 ether);
    }
    function testGapBoom() {
        sai.push(tap, 198 ether);
        assertEq(tap.joy(), 198 ether);

        admin.setTapGap(1.01 ether);  // 1% spread

        var sai_before = sai.balanceOf(this);
        var skr_before = skr.balanceOf(this);
        tap.boom(50 ether);
        var sai_after = sai.balanceOf(this);
        var skr_after = skr.balanceOf(this);
        assertEq(sai_after - sai_before, 99 ether);
        assertEq(skr_before - skr_after, 50 ether);
    }
    function testGapBust() {
        skr.push(tap, 100 ether);
        sin.push(tap, 200 ether);
        assertEq(tap.fog(), 100 ether);
        assertEq(tap.woe(), 200 ether);

        admin.setTapGap(1.01 ether);

        var sai_before = sai.balanceOf(this);
        var skr_before = skr.balanceOf(this);
        tap.bust(50 ether);
        var sai_after = sai.balanceOf(this);
        var skr_after = skr.balanceOf(this);
        assertEq(skr_after - skr_before,  50 ether);
        assertEq(sai_before - sai_after, 101 ether);
    }
    function testGapLimits() {
        uint256 legal   = 1.04 ether;
        uint256 illegal = 1.06 ether;

        var setGap = bytes4(sha3("setTapGap(uint256)"));

        assertTrue(admin.call(setGap, legal));
        assertEq(tap.gap(), legal);

        assertTrue(!admin.call(setGap, illegal));
        assertEq(tap.gap(), legal);
    }

    // join and exit have a spread parameter
    function testGapJarBidAsk() {
        assertEq(tub.per(), ray(1 ether));
        assertEq(tub.bid(1 ether), 1 ether);
        assertEq(tub.ask(1 ether), 1 ether);

        admin.setTubGap(1.01 ether);
        assertEq(tub.bid(1 ether), 0.99 ether);
        assertEq(tub.ask(1 ether), 1.01 ether);

        assertEq(skr.balanceOf(this), 500 ether);
        assertEq(skr.totalSupply(),   500 ether);
        skr.burn(250 ether);

        assertEq(tub.per(), ray(2 ether));
        assertEq(tub.bid(1 ether), 1.98 ether);
        assertEq(tub.ask(1 ether), 2.02 ether);
    }
    function testGapJoin() {
        gem.mint(100 ether);

        admin.setTubGap(1.05 ether);
        var skr_before = skr.balanceOf(this);
        var gem_before = gem.balanceOf(this);
        tub.join(100 ether);
        var skr_after = skr.balanceOf(this);
        var gem_after = gem.balanceOf(this);

        assertEq(skr_after - skr_before, 100 ether);
        assertEq(gem_before - gem_after, 105 ether);
    }
    function testGapExit() {
        gem.mint(100 ether);
        tub.join(100 ether);

        admin.setTubGap(1.05 ether);
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

        admin.setHat(1000 ether);

        cup = tub.open();
        tub.join(1000 ether);
        tub.lock(cup, 500 ether);
        tub.draw(cup, 100 ether);
    }
    function doLock(uint256 wad) logs_gas {
        tub.lock(cup, wad);
    }
    function doFree(uint256 wad) logs_gas {
        tub.free(cup, wad);
    }
    function doDraw(uint256 wad) logs_gas {
        tub.draw(cup, wad);
    }
    function doWipe(uint256 wad) logs_gas {
        tub.wipe(cup, wad);
    }
    function doDrip() logs_gas {
        tub.drip();
    }
    function doBoom(uint256 wad) logs_gas {
        tap.boom(wad);
    }

    uint64 tic = 15 seconds;

    function testGasLock() {
        warp(tic);
        doLock(100 ether);
        // assertTrue(false);
    }
    function testGasFree() {
        warp(tic);
        doFree(100 ether);
        // assertTrue(false);
    }
    function testGasDraw() {
        warp(tic);
        doDraw(100 ether);
        // assertTrue(false);
    }
    function testGasWipe() {
        warp(tic);
        doWipe(100 ether);
        // assertTrue(false);
    }
    function testGasBoom() {
        warp(tic);
        tub.join(10 ether);
        sai.mint(100 ether);
        sai.push(tap, 100 ether);
        skr.approve(tap, uint(-1));
        doBoom(1 ether);
        // assertTrue(false);
    }
    function testGasBoomHeal() {
        warp(tic);
        tub.join(10 ether);
        sai.mint(100 ether);
        sin.mint(100 ether);
        sai.push(tap, 100 ether);
        sin.push(tap,  50 ether);
        skr.approve(tap, uint(-1));
        doBoom(1 ether);
        // assertTrue(false);
    }
    function testGasDripNoop() {
        tub.drip();
        doDrip();
    }
    function testGasDrip1s() {
        warp(1 seconds);
        doDrip();
    }
    function testGasDrip1m() {
        warp(1 minutes);
        doDrip();
    }
    function testGasDrip1h() {
        warp(1 hours);
        doDrip();
    }
    function testGasDrip1d() {
        warp(1 days);
        doDrip();
    }
}
