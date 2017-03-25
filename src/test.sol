pragma solidity ^0.4.8;

import "ds-test/test.sol";

import 'ds-token/token.sol';
import './yas.sol';

contract Test is DSTest {
    Tab tab;
    DSToken _col;
    function setUp() {
        _col = new DSToken("collateral", "COL", 18);
        _col.mint(100 ether);
        tab = new Tab(_col);
        _col.approve(tab, 100000 ether);
    }
    function testBasic() {
        // edge case
        tab.join(10 ether);
        assertEq( tab.SAY().balanceOf(this), 10 ether );
        // price formula 
        tab.join(10 ether); 
        assertEq( tab.SAY().balanceOf(this), 20 ether );
        
        
    }
}
