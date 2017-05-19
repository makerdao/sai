pragma solidity ^0.4.8;

import "ds-roles/roles.sol";

contract SaiMom is DSRoles {
    // role identifiers
    uint8 public user = 1;

    bytes4[] public user_capabilities = [
        sig("join(uint128)"),
        sig("exit(uint128)"),
        sig("open()"),
        sig("shut(bytes32)"),
        sig("lock(bytes32,uint128)"),
        sig("free(bytes32,uint128)"),
        sig("draw(bytes32,uint128)"),
        sig("wipe(bytes32,uint128)"),
        sig("give(bytes32,address)"),
        sig("bite(bytes32)"),
        sig("boom(uint128)"),
        sig("bust(uint128)"),
        sig("cash()"),
        sig("bail(bytes32)")
    ];

    function SaiMom(address target) {
        for (uint i=0; i<user_capabilities.length; i++) {
            setRoleCapability(user, target, user_capabilities[i], true);
        }
    }

    function sig(string name) constant returns (bytes4) {
        return bytes4(sha3(name));
    }

    function setUser(address who, bool enabled) auth {
        setUserRole(who, user, enabled);
    }

    function isUser(address who) constant returns (bool) {
        return hasUserRole(who, user);
    }
}
