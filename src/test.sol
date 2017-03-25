pragma solidity ^0.4.8;

import "ds-test/test.sol";

import 'ds-token/token.sol';
import './yas.sol';

contract Test is DSTest {
    Engine yas;
    DSToken _col;
    function setUp() {
        _col = new DSToken("collateral", "COL", 18);
        _col.mint(100 ether);
        yas = new Engine(_col);
        _col.approve(yas, 100000 ether);
    }
    function testJoinExit() {
        // edge case
        yas.join(10 ether);
        assertEq( yas.SAY().balanceOf(this), 10 ether );
        // price formula 
        yas.join(10 ether); 
        assertEq( yas.SAY().balanceOf(this), 20 ether );
    }
}
