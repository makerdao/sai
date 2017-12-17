pragma solidity ^0.4.18;

import "ds-token/token.sol";

contract GemPit {
    function burn(DSToken gem) public {
        gem.burn(gem.balanceOf(this));
    }
}
