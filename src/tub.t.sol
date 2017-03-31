pragma solidity ^0.4.8;

import "ds-test/test.sol";

import 'ds-token/token.sol';
import 'ds-vault/vault.sol';

import './tub.sol';

contract Test is DSTest {
    Tub tub;
    DSToken gem;
    DSToken sai;
    DSToken sin;
    DSToken skr;
    DSVault ice;

    function ray(uint128 wad) returns (uint128) {
        return wad * 1 ether;
    }

    function setUp() {
        gem = new DSToken("collateral", "COL", 18);
        gem.mint(100 ether);

        sai = new DSToken("SAI", "SAI", 18);
        sin = new DSToken("SIN", "SIN", 18);
        skr = new DSToken("SKR", "SKR", 18);
        ice = new DSVault();

        tub = new Tub(gem, sai, sin, skr, ice);

        sai.setOwner(tub);
        sin.setOwner(tub);
        skr.setOwner(tub);
        ice.setOwner(tub);

        gem.approve(tub, 100000 ether);
        tub.skr().approve(tub, 100000 ether);
        tub.skr().approve(ice, 100000 ether);
        tub.sai().approve(tub, 100000 ether);

        tub.mark(1 ether);
    }
    function testBasic() {
        assertEq( tub.skr().balanceOf(ice), 0 ether );
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
        assertEq( tub.skr().balanceOf(ice), 0 ether );
        tub.lock(cup, 10 ether); // lock skr token
        assertEq( tub.skr().balanceOf(this), 10 ether );
        assertEq( tub.skr().balanceOf(ice), 10 ether );

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
        tub.mark(1 ether / 2);
        assert(!tub.safe(cup));
    }
    function testBiteUnderParity() {
        assertEq(uint(tub.axe()), uint(ray(1 ether)));  // 100% collateralisation limit
        tub.join(10 ether);
        var cup = tub.open();
        tub.lock(cup, 10 ether);
        tub.draw(cup, 5 ether);  // 200% collateralisation
        tub.mark(1 ether / 4);   // 50% collateralisation

        assertEq(tub.rue(), uint(0));
        tub.bite(cup);
        assertEq(tub.rue(), uint(10 ether));
    }
    function testBiteOverParity() {
        tub.cuff(ray(2 ether));  // require 200% collateralisation
        tub.join(10 ether);
        var cup = tub.open();
        tub.lock(cup, 10 ether);

        tub.draw(cup, 4 ether);  // 250% collateralisation
        assert(tub.safe(cup));
        tub.mark(1 ether / 2);   // 125% collateralisation
        assert(!tub.safe(cup));

        assertEq(tub.rue(), uint(0));
        tub.bite(cup);
        assertEq(tub.rue(), uint(8 ether));

        // cdp should now be safe with 0 sai debt and 2 skr remaining
        var skr_before = skr.balanceOf(this);
        tub.free(cup, 2 ether);
        assertEq(skr.balanceOf(this) - skr_before, 2 ether);
    }
}
