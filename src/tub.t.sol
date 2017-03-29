pragma solidity ^0.4.8;

import "ds-test/test.sol";

import 'ds-token/token.sol';
import './tub.sol';

contract Test is DSTest {
    Tub tub;
    DSToken _gem;
    function setUp() {
        _gem = new DSToken("collateral", "COL", 18);
        _gem.mint(100 ether);
        tub = new Tub(_gem);
        _gem.approve(tub, 100000 ether);
        tub.skr().approve(tub, 100000 ether);
    }
    function testBasic() {
        assertEq( tub.skr().balanceOf(tub), 0 ether );
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
        assertEq( tub.skr().balanceOf(tub), 0 ether );
        tub.lock(cup, 10 ether); // lock skr token
        assertEq( tub.skr().balanceOf(this), 10 ether );
        assertEq( tub.skr().balanceOf(tub), 10 ether );

        assertEq( tub.sai().balanceOf(this), 0 ether);
        tub.draw(cup, 5 ether);
        assertEq( tub.sai().balanceOf(this), 5 ether);
    }
}
