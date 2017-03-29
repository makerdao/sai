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

//        var cdp = tub.open();
//        tub.lock(cdp, 10 ether); // lock skr token
    }
}
