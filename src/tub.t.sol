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
    }
    function testBasic() {
        // edge case
        tub.join(10 ether);
        assertEq( tub.skr().balanceOf(this), 10 ether );
        // price formula 
        tub.join(10 ether); 
        assertEq( tub.skr().balanceOf(this), 20 ether );
    }
    function testScenario1() {
        tub.join(10 ether);
        assertEq( tub.skr().balanceOf(this), 10 ether );

        var cup = tub.open();
        tub.lock(cup, 10 ether); // lock skr token
        tub.draw(5);
    }
}
