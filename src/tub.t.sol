pragma solidity ^0.4.8;

import "ds-test/test.sol";

import "ds-math/math.sol";

import 'ds-token/token.sol';
import 'ds-vault/vault.sol';
import 'ds-roles/roles.sol';
import 'ds-value/value.sol';

import './tub.sol';

contract Test is DSTest, DSMath {
    Tub tub;
    DSToken gem;
    DSToken sai;
    DSToken sin;
    DSToken skr;
    DSVault pot;
    DSValue tag;

    function ray(uint128 wad) returns (uint128) {
        return wad * 1 ether;
    }

    function assertEqWad(uint128 x, uint128 y) {
        assertEq(uint256(x), uint256(y));
    }

    // for later export to factory
    function roleSetup(address dad, address rat) returns (DSRoles) {
        uint8 DAD = 0;
        uint8 RAT = 1;
        var roles = new DSRoles();

    }

    function setUp() {
        gem = new DSToken("collateral", "COL", 18);
        gem.mint(100 ether);

        sai = new DSToken("SAI", "SAI", 18);
        sin = new DSToken("SIN", "SIN", 18);
        skr = new DSToken("SKR", "SKR", 18);
        pot = new DSVault();

        tag = new DSValue();
        tub = new Tub(gem, sai, sin, skr, pot, tag);

        var dad = new DSRoles(); // TODO

        var mom = DSAuthority(tub);

        sai.setOwner(mom);
        sin.setOwner(mom);
        skr.setOwner(mom);
        pot.setOwner(mom);

        gem.approve(tub, 100000 ether);
        tub.skr().approve(tub, 100000 ether);
        tub.skr().approve(pot, 100000 ether);
        tub.sai().approve(tub, 100000 ether);

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
    function testFailOverDraw() {
        tub.join(10 ether);
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
        tub.draw(cup, 5 ether);  // 200% collateralisation
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

        tub.draw(cup, 5 ether);  // 200% collat, full debt ceiling
        tag.poke(bytes32(1 ether / 2));   // 100% collat

        assertEq(tub.air(), uint(10 ether));
        assertEq(tub.fog(), uint(0 ether));
        tub.bite(cup);
        assertEq(tub.air(), uint(0 ether));
        assertEq(tub.fog(), uint(10 ether));

        tub.join(10 ether);
        // skr hasn't been diluted yet so still 1:1 skr:gem
        assertEq(skr.balanceOf(this), 10 ether);

        // open another cdp and see if we can draw against it, given
        // that the previous cdp maxed out the debt ceiling
        var mug = tub.open();
        tub.lock(mug, 10 ether);
        // this should suceed as the debt ceiling is defined by ice, not
        // ice + woe
        tub.draw(mug, 1 ether);
    }

    // ensure kill sets the settle prices right
    function killSetup() {
        tub.cork(5 ether);            // 5 sai debt ceiling
        tag.poke(bytes32(1 ether));   // price 1:1 gem:ref
        tub.cuff(ray(2 ether));       // require 200% collat
        tub.join(10 ether);
        var cup = tub.open();
        tub.lock(cup, 10 ether);
        tub.draw(cup, 5 ether);       // 200% collateralisation
    }
    function testKillSafeOverCollat() {
        killSetup();

        assertEqWad(tub.fix(), 0);
        assertEqWad(tub.fit(), 0);
        assertEqWad(tub.woe(), 0);         // no bad debt
        assertEqWad(tub.pie(), 10 ether);

        tub.kill(1 ether);

        assertEqWad(tub.woe(), 5 ether);       // all good debt now bad debt
        assertEqWad(tub.fix(), 1 ether);       // sai redeems 1:1 with gem
        assertEqWad(tub.fit(), 1 ether / 2);   // skr redeems 2:1 with gem
    }
    function testKillUnsafeOverCollat() {
        killSetup();

        assertEqWad(tub.fix(), 0);
        assertEqWad(tub.fit(), 0);

        var price = wdiv(3 ether, 4 ether);
        tub.kill(price);        // 150% collat

        assertEqWad(tub.fix(), wdiv(1 ether, price));   // sai redeems 4:3 with gem
        assertEqWad(tub.fit(), wdiv(1 ether, 3 ether)); // skr redeems 3:1 with gem
    }
    function testKillAtCollat() {
        killSetup();

        assertEqWad(tub.fix(), 0);
        assertEqWad(tub.fit(), 0);

        var price = wdiv(1 ether, 2 ether);  // 100% collat
        tub.kill(price);

        assertEqWad(tub.fix(), 2 ether);   // sai redeems 1:2 with gem, 1:1 with ref
        assertEqWad(tub.fit(), 0 ether);   // skr redeems 1:0 with gem
    }
    function testKillUnderCollat() {
        killSetup();

        assertEqWad(tub.fix(), 0);
        assertEqWad(tub.fit(), 0);

        var price = wdiv(1 ether, 4 ether);   // 50% collat
        tub.kill(price);

        assertEq(2 * sai.totalSupply(), tub.pie());
        assertEqWad(tub.fix(), 2 ether);      // sai redeems 1:2 with gem, 2:1 with ref
        assertEqWad(tub.fit(), 0 ether);      // skr redeems 1:0 with gem
    }

    // ensure save returns the expected amount
    function testSaveSafeOverCollat() {
    }
    function testSaveUnsafeOverCollat() {
    }
    function testSaveUnderCollat() {
    }
}
