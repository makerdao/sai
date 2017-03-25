pragma solidity ^0.4.8;

import "ds-test/test.sol";
import './yas.sol';

contract Test is DSTest {
    YAS yas;
    function setUp() {
        yas = new YAS();
    }

}
