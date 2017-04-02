pragma solidity ^0.4.8;

import "ds-test/test.sol";

import 'ds-token/token.sol';
import 'ds-vault/vault.sol';
import 'ds-roles/roles.sol';
import 'ds-value/value.sol';

import './tub.sol';

contract Test is DSTest {
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

        sai.setAuthority(mom);
        sin.setAuthority(mom);
        skr.setAuthority(mom);
        pot.setAuthority(mom);

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
}
